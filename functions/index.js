const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const axios = require("axios");
const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');
const { GoogleGenerativeAI } = require("@google/generative-ai");

admin.initializeApp();

// Secret Manager：敏感配置迁移（替代旧版 functions.config / 环境配置）
const geminiApiKey = defineSecret("GEMINI_API_KEY");

/**
 * Gemini API Proxy Cloud Function
 *
 * 强制最宽 CORS 策略，解决 Web 端 Preflight 失败。
 * 使用 Secret Manager 存储 GEMINI_API_KEY。
 */
exports.geminiProxy = onRequest(
    { secrets: [geminiApiKey] },
    async (req, res) => {
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
            const apiKey = geminiApiKey.value();
            if (!apiKey) {
                console.error("Critical: GEMINI_API_KEY missing");
                res.status(500).send({ error: "API Key missing" });
                return;
            }

            // 解析并清理路径
            let path = req.path || req.url.split('?')[0];
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
            res.status(500).send({ error: "Proxy Exception", details: error.message });
        }
    }
);

/**
 * 完全后台 AI 提取任务
 * 使用 Secret Manager 存储 GEMINI_API_KEY。
 */
exports.processExtractionJob = onCall(
    {
        secrets: [geminiApiKey],
        timeoutSeconds: 540,
        memory: '1GB'
    },
    async (request) => {
        const data = request.data;
        const context = { auth: request.auth };

        // 验证用户登录
        if (!context.auth) {
            throw new HttpsError('unauthenticated', '用户未登录');
        }

        const jobId = data.jobId;
        if (!jobId) {
            throw new HttpsError('invalid-argument', '缺少 jobId');
        }

        const userId = context.auth.uid;
        const db = getFirestore(admin.app(), 'reado');
        const jobRef = db.collection('extraction_jobs').doc(jobId);

        console.log(`🚀 Starting background job ${jobId} for user ${userId}`);

        try {
            // 1. 读取任务
            const jobDoc = await jobRef.get();
            if (!jobDoc.exists) {
                throw new HttpsError('not-found', '任务不存在');
            }

            const jobData = jobDoc.data();
            if (jobData.userId !== userId) {
                throw new HttpsError('permission-denied', '无权访问此任务');
            }

            const content = jobData.content;
            const moduleId = jobData.moduleId || 'custom';
            const mode = jobData.deconstructionMode || (jobData.isGrandmaMode ? 'grandma' : 'standard');
            console.log(`📦 Job moduleId: ${moduleId}, Mode: ${mode}`);

            if (!content || content.length === 0) {
                await jobRef.update({ status: 'failed', error: '内容为空' });
                throw new HttpsError('invalid-argument', '内容为空');
            }

            // 2. 更新状态为处理中
            await jobRef.update({
                status: 'processing',
                progress: 0.1,
                message: 'AI 正在分析内容...',
                startedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            const apiKey = geminiApiKey.value();
            const genAI = new GoogleGenerativeAI(apiKey);
            const model = genAI.getGenerativeModel({
                model: "gemini-2.5-flash",
                generationConfig: { responseMimeType: "application/json" }
            });

            // 3. 生成大纲
            const modeOutlineInstructions = mode === 'grandma'
                ? "采用“极简大白话”风格：识别出最基础、最通俗的核心知识点，标题要平实直白。"
                : (mode === 'phd' ? "采用“智障博士生”风格：极简大白话，但逻辑极严密，不要任何花哨类比，直接提取硬核逻辑支柱。" : "");

            const outlinePrompt = `
你是一位资深的教育内容专家。请快速分析用户提供的学习资料，识别出其中的核心知识点。

${modeOutlineInstructions}

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

            await jobRef.update({
                progress: 0.2,
                message: `发现 ${topics.length} 个知识点，开始生成...`,
                totalCards: topics.length
            });

            // 4. 逐个生成卡片
            const cards = [];
            for (let i = 0; i < topics.length; i++) {
                const topic = topics[i];
                const title = topic.title;

                await jobRef.update({
                    message: `正在生成 ${i + 1}/${topics.length}: ${title}`,
                    progress: 0.2 + (0.7 * (i / topics.length))
                });

                let modeInstructions = '';
                if (mode === 'grandma') {
                    modeInstructions = `
## 🚨 重要：采用“极简大白话”风格 🚨
- **语言风格**：严禁使用专业术语。如果必须使用，必须通过“生活化类比”进行降维解释。
- **类比要求**：必须包含一个极其生活化、接地气的类比（如：买菜、做饭、点外卖等）。
- **讲解要求**：亲切直白。禁止任何寒暄，直接开始讲解知识点本身。
`;
                } else if (mode === 'phd') {
                    modeInstructions = `
## 🚨 重要：采用“智障博士生”级别拆解 🚨
- **目标**：像是在给逻辑非常严密、但认知极简的人解释。
- **语言风格**：必须使用**极简的大白话**，傻子都能听懂的语言。严禁堆砌专业术语，严禁使用长句。**严禁在文字之间添加任何多余的空格或空格占位**。
- **逻辑要求**：禁止任何感性类比（如：买菜、带孩子）。必须通过严密的逻辑推导、事实陈述、因果链条来拆解核心。
- **语气**：直白。禁止任何寒暄，直接开始讲解知识点本身。
`;
                }

                const cardPrompt = `
你是一位资深的教育内容专家。请针对以下知识点，生成一张详细的知识卡片。

${modeInstructions}

## 知识点标题
${title}

## 参考资料（从中提取相关内容）
${content.substring(0, 30000)}

## 要求
1. **正文内容**：必须生成 300-800 字的详细解释。${mode === 'grandma' ? "采用极简大白话和生活类比。" : (mode === 'phd' ? "采用极简大白话，严密逻辑拆解，禁止类比。" : "采用\"是什么 → 为什么 → 怎么做\"的结构。")}
2. **Flashcard**：一个具体的测试问题 + 简洁但完整的答案（100-200字）
3. 使用 Markdown 格式。
4. **语言要求**：输出的所有内容必须使用简体中文。

## 输出格式
严格按照以下 JSON 格式输出：

{
  "title": "${title}",
  "category": "${topic.category || 'AI Generated'}",
  "difficulty": "${topic.difficulty || 'Medium'}",
  "content": "# 标题\\n\\n[在此处填写详细的知识点正文内容，不少于300字]",
  "flashcard": {
    "question": "具体的测试问题",
    "answer": "简洁但完整的答案"
  }
}
`;

                let cardJson = null;
                let retries = 2;

                while (retries >= 0 && !cardJson) {
                    try {
                        const cardResult = await model.generateContent(cardPrompt);
                        const cardText = cardResult.response.text();

                        const jsonMatch = cardText.match(/\{[\s\S]*\}/);
                        if (!jsonMatch) throw new Error('No JSON object found');

                        cardJson = JSON.parse(jsonMatch[0].trim());
                        cardJson.id = `custom_${Date.now()}_${i}`;
                        cardJson.module = moduleId;
                        cardJson.isCustom = true;
                        cardJson.readingTimeMinutes = 5;
                        cardJson.createdAt = new Date(Date.now() + i * 1000).toISOString();
                        cardJson.pages = [{
                            type: 'text',
                            markdownContent: cardJson.content || cardJson.markdownContent || 'No content generated',
                            flashcardQuestion: cardJson.flashcard?.question,
                            flashcardAnswer: cardJson.flashcard?.answer
                        }];

                        cards.push(cardJson);
                        await jobRef.update({
                            cards: cards,
                            progress: 0.2 + (0.7 * ((i + 1) / topics.length)),
                            message: `已生成 ${i + 1}/${topics.length} 个知识点`
                        });

                    } catch (err) {
                        console.error(`⚠️ Attempt failing to generate card ${i}:`, err);
                        retries--;
                        if (retries >= 0) await new Promise(r => setTimeout(r, 1000));
                    }
                }
            }

            // 5. 标记完成并保存
            const userRef = db.collection('users').doc(userId);
            await userRef.set({ lastActive: new Date() }, { merge: true });

            const userItemsRef = userRef.collection('custom_items');
            const batch = db.batch();
            for (const card of cards) {
                batch.set(userItemsRef.doc(card.id), {
                    ...card,
                    module: moduleId,
                    createdAt: new Date(),
                    autoSaved: true,
                    sourceJobId: jobId
                });
            }
            await batch.commit();

            await jobRef.update({
                status: 'completed',
                progress: 1.0,
                message: `全部完成！（解析出 ${cards.length}/${topics.length} 个知识点）`,
                autoSaved: true,
                savedCount: cards.length,
                completedAt: new Date()
            });

            return { success: true, jobId, cardCount: cards.length };

        } catch (error) {
            console.error(`❌ Job ${jobId} failed:`, error);
            await jobRef.update({
                status: 'failed',
                error: error.message,
                completedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            throw new HttpsError('internal', error.message);
        }
    }
);
