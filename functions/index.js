const functions = require("firebase-functions");
const axios = require("axios");
const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');
const { GoogleGenerativeAI } = require("@google/generative-ai");

admin.initializeApp();

/**
 * Gemini API Proxy Cloud Function
 * 
 * 强制最宽 CORS 策略，解决 Web 端 Preflight 失败。
 */
exports.geminiProxy = functions.https.onRequest(async (req, res) => {
    // 1. 无论请求是什么，先给跨域许可！
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Headers', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Max-Age', '3600');

    // 2. 立即响应 OPTIONS 请求
    if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
    }

    try {
        const apiKey = process.env.GEMINI_API_KEY;
        if (!apiKey) {
            console.error("Critical: GEMINI_API_KEY missing");
            res.status(500).send({ error: "API Key missing" });
            return;
        }

        // 解析并清理路径
        let path = req.path || req.url.split('?')[0];
        // 防止路径污染
        path = path.replace('//', '/');

        const targetUrl = `https://generativelanguage.googleapis.com${path}`;

        console.log(`📡 Forwarding to: ${targetUrl}`);

        // 3. 构造转发请求
        const response = await axios({
            method: req.method,
            url: targetUrl,
            params: { ...req.query, key: apiKey },
            data: req.body,
            headers: {
                'Content-Type': 'application/json',
                // 只透传客户端版本号主要信息
                'x-goog-api-client': req.headers['x-goog-api-client'] || 'revert-to-1.5',
            },
            timeout: 60000,
            validateStatus: () => true
        });

        // 4. 返回结果
        res.set('Content-Type', response.headers['content-type'] || 'application/json');
        res.status(response.status).send(response.data);

    } catch (error) {
        console.error("Proxy Error:", error.message);
        // 即使炸了也要给 JSON
        res.status(500).send({ error: "Proxy Exception", details: error.message });
    }
});

/**
 * 完全后台 AI 提取任务
 * 
 * 工作流程：
 * 1. 前端创建 job 文档到 Firestore (extraction_jobs/{jobId})
 * 2. 前端调用此函数，传入 jobId
 * 3. 函数从 Firestore 读取任务内容
 * 4. AI 处理过程中，实时更新 Firestore 进度
 * 5. 完成后，结果保存到 Firestore
 * 6. 即使客户端断连，函数继续执行到完成
 * 7. 前端监听 Firestore 文档获取实时更新
 */
exports.processExtractionJob = functions
    .runWith({
        timeoutSeconds: 540,  // 9分钟超时
        memory: '1GB'
    })
    .https.onCall(async (data, context) => {
        // 验证用户登录
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', '用户未登录');
        }

        const jobId = data.jobId;
        if (!jobId) {
            throw new functions.https.HttpsError('invalid-argument', '缺少 jobId');
        }

        const userId = context.auth.uid;

        // 🔥 使用 'reado' 命名数据库（与前端一致）
        // getFirestore(app, databaseId) - 第二个参数指定数据库 ID
        const db = getFirestore(admin.app(), 'reado');

        const jobRef = db.collection('extraction_jobs').doc(jobId);

        console.log(`🚀 Starting background job ${jobId} for user ${userId}`);

        try {
            // 1. 读取任务
            const jobDoc = await jobRef.get();
            if (!jobDoc.exists) {
                throw new functions.https.HttpsError('not-found', '任务不存在');
            }

            const jobData = jobDoc.data();

            // 验证任务属于当前用户
            if (jobData.userId !== userId) {
                throw new functions.https.HttpsError('permission-denied', '无权访问此任务');
            }

            const content = jobData.content;
            const moduleId = jobData.moduleId || 'custom';
            console.log(`📦 Job moduleId: ${moduleId}`);

            if (!content || content.length === 0) {
                await jobRef.update({ status: 'failed', error: '内容为空' });
                throw new functions.https.HttpsError('invalid-argument', '内容为空');
            }

            // 2. 更新状态为处理中
            await jobRef.update({
                status: 'processing',
                progress: 0.1,
                message: 'AI 正在分析内容...',
                startedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            const apiKey = process.env.GEMINI_API_KEY;
            if (!apiKey) {
                await jobRef.update({ status: 'failed', error: 'API Key missing' });
                throw new functions.https.HttpsError('internal', 'API Key missing');
            }

            const genAI = new GoogleGenerativeAI(apiKey);
            const model = genAI.getGenerativeModel({
                model: "gemini-2.5-flash",
                generationConfig: { responseMimeType: "application/json" }
            });

            // 3. 生成大纲
            const outlinePrompt = `
你是一位资深的教育内容专家。请快速分析用户提供的学习资料，识别出其中的核心知识点。

## 任务
1. 阅读用户的学习资料
2. 识别出 2-8 个独立的核心知识点
3. 每个知识点用一个简洁的标题概括（10-20字）

## 输出格式
严格按照以下 JSON 格式输出（只输出 JSON，不要有其他文字）。
**重要提示：所有输出内容必须使用简体中文，即使原文是英文。**

{
  "topics": [
    {"title": "知识点1的标题", "category": "分类", "difficulty": "Easy|Medium|Hard"},
    {"title": "知识点2的标题", "category": "分类", "difficulty": "Medium"}
  ]
}

## 用户的学习资料：
${content.substring(0, 30000)} 
`;

            console.log(`📝 Generating outline for job ${jobId}...`);
            const outlineResult = await model.generateContent(outlinePrompt);
            const outlineText = outlineResult.response.text();

            let cleanOutline = outlineText.replace(/```json|```/g, '').trim();
            const outlineJson = JSON.parse(cleanOutline);
            const topics = outlineJson.topics || outlineJson.items || [];

            console.log(`✅ Found ${topics.length} topics`);

            await jobRef.update({
                progress: 0.2,
                message: `发现 ${topics.length} 个知识点，开始生成...`,
                totalCards: topics.length
            });

            // 4. 逐个生成卡片并实时保存
            const cards = [];
            for (let i = 0; i < topics.length; i++) {
                const topic = topics[i];
                const title = topic.title;

                await jobRef.update({
                    message: `正在生成 ${i + 1}/${topics.length}: ${title}`,
                    progress: 0.2 + (0.7 * (i / topics.length))
                });

                console.log(`📝 Generating card ${i + 1}/${topics.length}: ${title}`);

                const cardPrompt = `
你是一位资深的教育内容专家。请针对以下知识点，生成一张详细的知识卡片。

## 知识点标题
${title}

## 参考资料（从中提取相关内容）
${content.substring(0, 30000)}

## 要求
1. **正文内容**：300-800 字，通俗易懂，采用"是什么 → 为什么 → 怎么做"的结构
2. **Flashcard**：一个具体的测试问题 + 简洁但完整的答案（100-200字）
3. 使用 Markdown 格式
4. **语言要求**：输出的所有内容必须使用简体中文。

## 输出格式
严格按照以下 JSON 格式输出：

{
  "title": "${title}",
  "category": "${topic.category || 'AI Generated'}",
  "difficulty": "${topic.difficulty || 'Medium'}",
  "content": "# 标题\\n\\n## 是什么\\n\\n[Markdown 正文]",
  "flashcard": {
    "question": "具体的测试问题",
    "answer": "简洁但完整的答案"
  }
}
`;

                let cardJson = null;
                let retries = 2; // 最多重试2次

                while (retries >= 0 && !cardJson) {
                    try {
                        const cardResult = await model.generateContent(cardPrompt);
                        const cardText = cardResult.response.text();

                        // 更鲁棒的 JSON 提取：尝试匹配第一个 { 和最后一个 }
                        const jsonMatch = cardText.match(/\{[\s\S]*\}/);
                        if (!jsonMatch) {
                            throw new Error('No JSON object found in response');
                        }

                        const cleanCard = jsonMatch[0].trim();
                        cardJson = JSON.parse(cleanCard);

                        // Add metadata
                        cardJson.id = `custom_${Date.now()}_${i}`;
                        cardJson.module = moduleId;
                        cardJson.isCustom = true;
                        cardJson.readingTimeMinutes = 5;
                        // 递增时间戳：i=0 是最旧的，i=N 是最新的
                        // 配合前端 ASC 排序，知识点会按 1, 2, 3... 的顺序从上到下依次追加到末尾
                        cardJson.createdAt = new Date(Date.now() + i * 1000).toISOString();

                        // 格式化 pages 结构
                        cardJson.pages = [{
                            type: 'text',
                            markdownContent: cardJson.content || cardJson.markdownContent || 'No content generated',
                            flashcardQuestion: cardJson.flashcard?.question,
                            flashcardAnswer: cardJson.flashcard?.answer
                        }];

                        cards.push(cardJson);

                        // 实时保存已生成的卡片到 Firestore
                        await jobRef.update({
                            cards: cards,
                            progress: 0.2 + (0.7 * ((i + 1) / topics.length)),
                            message: `已生成 ${i + 1}/${topics.length} 个知识点`
                        });

                    } catch (err) {
                        console.error(`⚠️ Attempt failing to generate card ${i} (Retries left: ${retries}):`, err);
                        retries--;
                        if (retries < 0) {
                            console.error(`❌ Permanently failed to generate card ${i}:`, topics[i]);
                        } else {
                            // 稍微等待一下再重试
                            await new Promise(resolve => setTimeout(resolve, 1000));
                        }
                    }
                }
            }

            // 5. 标记完成
            await jobRef.update({
                status: 'completed',
                progress: 1.0,
                message: '全部完成！',
                cards: cards,
                completedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // 6. 🔥 自动保存到用户的 custom_items
            console.log(`💾 Auto-saving ${cards.length} cards to user ${userId}, moduleId: ${moduleId}`);

            // 确保用户文档存在（有些新账号可能没有用户文档）
            const userRef = db.collection('users').doc(userId);
            await userRef.set({ lastActive: new Date() }, { merge: true });

            const userItemsRef = userRef.collection('custom_items');
            const batch = db.batch();

            for (const card of cards) {
                const cardDoc = userItemsRef.doc(card.id);
                const cardToSave = {
                    ...card,
                    module: moduleId, // 对应前端 FeedItem.fromJson 中的 'module'
                    createdAt: new Date(), // 使用 JS Date 避免引用问题
                    autoSaved: true,
                    sourceJobId: jobId
                };
                console.log(`📝 Preparing card ${card.id} for module ${moduleId}`);
                batch.set(cardDoc, cardToSave);
            }

            await batch.commit();
            console.log(`✅ Successfully auto-saved ${cards.length} cards to users/${userId}/custom_items`);

            // 更新任务状态
            await jobRef.update({
                autoSaved: true,
                savedCount: cards.length,
                status: 'completed',
                progress: 1.0,
                message: cards.length === topics.length ? '全部完成！' : `完成（解析出 ${cards.length}/${topics.length} 个知识点）`,
                completedAt: new Date()
            });

            return { success: true, jobId: jobId, autoSaved: true, cardCount: cards.length };

        } catch (error) {
            console.error(`❌ Job ${jobId} failed:`, error);
            await jobRef.update({
                status: 'failed',
                error: error.message,
                completedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            throw new functions.https.HttpsError('internal', error.message);
        }
    });
