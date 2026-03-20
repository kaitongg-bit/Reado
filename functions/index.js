const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const axios = require("axios");
const crypto = require("crypto");
const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');
const { GoogleGenerativeAI } = require("@google/generative-ai");
const prompts = require("./prompts");

admin.initializeApp();

/** 密保问题列表（与 Flutter 端一致） */
const SECURITY_QUESTIONS = [
    "您母亲的姓名是？",
    "您出生的城市是？",
    "您的第一个宠物名字是？",
    "您的小学名称是？",
    "您的配偶生日（MMDD，如 0315）是？"
];

/** 用于分享点击统计的 reado 库（与 Flutter 端 databaseId 一致） */
function getReadoDb() {
  return getFirestore(admin.app(), 'reado');
}

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
 * v2: 播客模式强制输出「主持人A/B」对话稿 + contentFormat: 'dialogue'
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
        const db = getReadoDb();
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
            const outputLocale = (jobData.outputLocale === 'en' ? 'en' : 'zh');
            const jm = {
                analyzing: outputLocale === 'en' ? 'AI is analyzing content...' : 'AI 正在分析内容...',
                foundTopics: (n) => outputLocale === 'en'
                    ? `Found ${n} topics, generating...`
                    : `发现 ${n} 个知识点，开始生成...`,
                generating: (i, total, title) => outputLocale === 'en'
                    ? `Generating ${i}/${total}: ${title}`
                    : `正在生成 ${i}/${total}: ${title}`,
                savedProgress: (i, total) => outputLocale === 'en'
                    ? `Generated ${i}/${total} topics`
                    : `已生成 ${i}/${total} 个知识点`,
                allDone: (cards, total) => outputLocale === 'en'
                    ? `All done (${cards}/${total} topics parsed)`
                    : `全部完成！（解析出 ${cards}/${total} 个知识点）`,
            };
            console.log(`📦 Job moduleId: ${moduleId}, Mode: ${mode}, outputLocale: ${outputLocale}`);

            if (!content || content.length === 0) {
                const emptyMsg = outputLocale === 'en' ? 'Content is empty' : '内容为空';
                await jobRef.update({ status: 'failed', error: emptyMsg });
                throw new HttpsError('invalid-argument', emptyMsg);
            }

            // 2. 更新状态为处理中
            await jobRef.update({
                status: 'processing',
                progress: 0.1,
                message: jm.analyzing,
                startedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            const apiKey = geminiApiKey.value();
            const genAI = new GoogleGenerativeAI(apiKey);
            const model = genAI.getGenerativeModel({
                model: "gemini-2.5-flash",
                generationConfig: { responseMimeType: "application/json" }
            });

            // 3. 生成大纲（知识点数量随内容长度缩放，与 Flutter 端积分/字数规则一致）
            const contentLen = (content && content.length) || 0;
            const minPoints = contentLen <= 5000 ? 2 : Math.max(2, Math.floor(contentLen / 1500));
            const maxPoints = contentLen <= 5000 ? 8 : Math.min(30, Math.max(8, Math.ceil(contentLen / 800)));
            const pointRange = `${minPoints}-${maxPoints}`;

            const modeOutlineInstructions = prompts.getModeOutlineInstructions(outputLocale, mode);

            const outlinePrompt = prompts.getOutlinePrompt(outputLocale, {
                contentLen,
                minPoints,
                maxPoints,
                pointRange,
                modeOutlineInstructions,
                content,
            });

            console.log(`📝 Generating outline for job ${jobId}...`);
            const outlineResult = await model.generateContent(outlinePrompt);
            const outlineText = outlineResult.response.text();

            let cleanOutline = outlineText.replace(/```json|```/g, '').trim();
            const outlineJson = JSON.parse(cleanOutline);
            let topics = outlineJson.topics || outlineJson.items || [];
            if (topics.length < minPoints) {
                console.warn(`⚠️ Job ${jobId}: outline returned ${topics.length} topics (min ${minPoints} for ${contentLen} chars). Proceeding anyway.`);
            }

            await jobRef.update({
                progress: 0.2,
                message: jm.foundTopics(topics.length),
                totalCards: topics.length
            });

            // 4. 逐个生成卡片
            const cards = [];
            for (let i = 0; i < topics.length; i++) {
                const topic = topics[i];
                const title = topic.title;

                await jobRef.update({
                    message: jm.generating(i + 1, topics.length, title),
                    progress: 0.2 + (0.7 * (i / topics.length))
                });

                const modeInstructions = prompts.getModeInstructions(outputLocale, mode);
                const isPodcast = mode === 'podcast';
                const cardPrompt = prompts.getCardPrompt(outputLocale, {
                    mode,
                    modeInstructions,
                    title,
                    content,
                    topic,
                    isPodcast,
                });
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
                            flashcardAnswer: cardJson.flashcard?.answer,
                            ...(isPodcast ? { contentFormat: 'dialogue' } : {})
                        }];

                        cards.push(cardJson);
                        await jobRef.update({
                            cards: cards,
                            progress: 0.2 + (0.7 * ((i + 1) / topics.length)),
                            message: jm.savedProgress(i + 1, topics.length)
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
                message: jm.allDone(cards.length, topics.length),
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

/**
 * 记录推广分享点击并给推广者加 50 积分（服务端写入 reado 库，不依赖客户端规则）
 * 调用方：Flutter 在打开带 ref= 的分享链接时调用，可不要求登录。
 */
exports.logShareClick = onCall(
    { timeoutSeconds: 10 },
    async (request) => {
        const referrerId = request.data && request.data.referrerId;
        if (!referrerId || typeof referrerId !== 'string' || referrerId.length === 0) {
            throw new HttpsError('invalid-argument', '缺少 referrerId');
        }
        const db = getReadoDb();
        const userRef = db.collection('users').doc(referrerId);
        try {
            await userRef.set({
                shareClicks: admin.firestore.FieldValue.increment(1),
                credits: admin.firestore.FieldValue.increment(50),
                lastShareClickAt: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });
            console.log('📈 Share click logged for', referrerId);
            return { success: true };
        } catch (e) {
            console.error('❌ logShareClick failed:', e);
            throw new HttpsError('internal', e.message || '记录失败');
        }
    }
);

/** 知识库分享统计：文档 id = ownerId_moduleId，字段 viewCount / saveCount / likeCount / likedBy */
function getShareStatsRef(db, ownerId, moduleId) {
    return db.collection('share_stats').doc(`${ownerId}_${moduleId}`);
}

/**
 * 获取分享统计（服务端读 reado 库返回，不依赖客户端 Firestore 规则）
 */
exports.getShareStats = onCall(
    { timeoutSeconds: 10 },
    async (request) => {
        const ownerId = request.data && request.data.ownerId;
        const moduleId = request.data && request.data.moduleId;
        if (!ownerId || !moduleId || typeof ownerId !== 'string' || typeof moduleId !== 'string') {
            throw new HttpsError('invalid-argument', '缺少 ownerId 或 moduleId');
        }
        const db = getReadoDb();
        const ref = getShareStatsRef(db, ownerId, moduleId);
        const doc = await ref.get();
        if (!doc.exists) {
            return { viewCount: 0, saveCount: 0, likeCount: 0 };
        }
        const data = doc.data();
        return {
            viewCount: typeof data.viewCount === 'number' ? data.viewCount : 0,
            saveCount: typeof data.saveCount === 'number' ? data.saveCount : 0,
            likeCount: typeof data.likeCount === 'number' ? data.likeCount : 0,
            likedBy: Array.isArray(data.likedBy) ? data.likedBy : []
        };
    }
);

/**
 * 记录分享页被浏览（任何人打开分享链接时调用，可不登录）
 */
exports.recordShareView = onCall(
    { timeoutSeconds: 10 },
    async (request) => {
        const ownerId = request.data && request.data.ownerId;
        const moduleId = request.data && request.data.moduleId;
        if (!ownerId || !moduleId || typeof ownerId !== 'string' || typeof moduleId !== 'string') {
            throw new HttpsError('invalid-argument', '缺少 ownerId 或 moduleId');
        }
        const db = getReadoDb();
        const ref = getShareStatsRef(db, ownerId, moduleId);
        await ref.set({
            viewCount: admin.firestore.FieldValue.increment(1),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
        return { success: true };
    }
);

/**
 * 记录有人点击「保存到我的知识库」并保存成功（由客户端在保存成功后调用）
 */
exports.recordShareSave = onCall(
    { timeoutSeconds: 10 },
    async (request) => {
        const ownerId = request.data && request.data.ownerId;
        const moduleId = request.data && request.data.moduleId;
        if (!ownerId || !moduleId || typeof ownerId !== 'string' || typeof moduleId !== 'string') {
            throw new HttpsError('invalid-argument', '缺少 ownerId 或 moduleId');
        }
        const db = getReadoDb();
        const ref = getShareStatsRef(db, ownerId, moduleId);
        await ref.set({
            saveCount: admin.firestore.FieldValue.increment(1),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
        return { success: true };
    }
);

/**
 * 点赞分享的知识库（路人也可点赞；登录用户每人仅计一次，未登录直接加一）
 */
exports.recordShareLike = onCall(
    { timeoutSeconds: 10 },
    async (request) => {
        const ownerId = request.data && request.data.ownerId;
        const moduleId = request.data && request.data.moduleId;
        if (!ownerId || !moduleId || typeof ownerId !== 'string' || typeof moduleId !== 'string') {
            throw new HttpsError('invalid-argument', '缺少 ownerId 或 moduleId');
        }
        const uid = request.auth && request.auth.uid;
        const db = getReadoDb();
        const ref = getShareStatsRef(db, ownerId, moduleId);
        if (uid) {
            const doc = await ref.get();
            const data = doc.exists ? doc.data() : {};
            const likedBy = Array.isArray(data.likedBy) ? data.likedBy : [];
            if (likedBy.includes(uid)) {
                return { success: true, alreadyLiked: true };
            }
            await ref.set({
                viewCount: admin.firestore.FieldValue.increment(0),
                saveCount: admin.firestore.FieldValue.increment(0),
                likeCount: admin.firestore.FieldValue.increment(1),
                likedBy: admin.firestore.FieldValue.arrayUnion(uid),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });
            return { success: true, alreadyLiked: false };
        } else {
            await ref.set({
                likeCount: admin.firestore.FieldValue.increment(1),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });
            return { success: true, alreadyLiked: false };
        }
    }
);

/** 每日签到：lastCheckInDate 存于 reado users 文档，格式 YYYY-MM-DD */
function todayStr() {
    const d = new Date();
    return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
}

/**
 * 获取今日是否已签到（用于头像旁是否显示提示）
 */
exports.getDailyCheckInStatus = onCall(
    { timeoutSeconds: 10 },
    async (request) => {
        if (!request.auth || !request.auth.uid) {
            return { claimedToday: false };
        }
        const db = getReadoDb();
        const userRef = db.collection('users').doc(request.auth.uid);
        const doc = await userRef.get();
        const last = doc.exists ? (doc.data().lastCheckInDate || '') : '';
        return { claimedToday: last === todayStr() };
    }
);

/**
 * 领取每日签到积分（每天一次，20 积分）
 */
exports.claimDailyCheckIn = onCall(
    { timeoutSeconds: 10 },
    async (request) => {
        if (!request.auth || !request.auth.uid) {
            throw new HttpsError('unauthenticated', '请先登录');
        }
        const uid = request.auth.uid;
        const db = getReadoDb();
        const userRef = db.collection('users').doc(uid);
        const today = todayStr();
        const doc = await userRef.get();
        const data = doc.exists ? doc.data() : {};
        const lastCheckIn = data.lastCheckInDate || '';
        if (lastCheckIn === today) {
            return { success: true, alreadyClaimed: true, credits: 0 };
        }
        await userRef.set({
            lastCheckInDate: today,
            credits: admin.firestore.FieldValue.increment(20),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
        return { success: true, alreadyClaimed: false, credits: 20 };
    }
);

// ---------- 忘记密码：密保问题 ----------

/**
 * 获取密保问题（用于忘记密码流程，不返回答案）
 * 入参: { email }
 * 返回: { questionId, questionText } 或 抛错
 */
exports.getSecurityQuestion = onCall(
    { timeoutSeconds: 10 },
    async (request) => {
        const email = request.data?.email;
        if (!email || typeof email !== "string" || !email.trim()) {
            throw new HttpsError("invalid-argument", "请提供邮箱");
        }
        const normalizedEmail = email.trim().toLowerCase();
        let uid;
        try {
            const userRecord = await admin.auth().getUserByEmail(normalizedEmail);
            uid = userRecord.uid;
        } catch (e) {
            throw new HttpsError("not-found", "该邮箱未注册");
        }
        const db = getReadoDb();
        const userRef = db.collection("users").doc(uid);
        const doc = await userRef.get();
        if (!doc.exists) {
            throw new HttpsError("failed-precondition", "未设置密保，请使用邮件重置或联系客服");
        }
        const data = doc.data() || {};
        const questionId = data.securityQuestionId;
        if (questionId == null || questionId < 0 || questionId >= SECURITY_QUESTIONS.length) {
            throw new HttpsError("failed-precondition", "未设置密保，请使用邮件重置或联系客服");
        }
        return {
            questionId,
            questionText: SECURITY_QUESTIONS[questionId],
        };
    }
);

/**
 * 设置密保问题（仅登录后可用）
 * 入参: { questionId: number, answer: string }
 */
exports.setSecurityQuestion = onCall(
    { timeoutSeconds: 10 },
    async (request) => {
        if (!request.auth || !request.auth.uid) {
            throw new HttpsError("unauthenticated", "请先登录");
        }
        const uid = request.auth.uid;
        const questionId = request.data?.questionId;
        const answer = request.data?.answer;
        if (typeof questionId !== "number" || questionId < 0 || questionId >= SECURITY_QUESTIONS.length) {
            throw new HttpsError("invalid-argument", "请选择有效密保问题");
        }
        if (!answer || typeof answer !== "string" || answer.trim().length < 2) {
            throw new HttpsError("invalid-argument", "答案至少 2 个字符");
        }
        const salt = crypto.randomBytes(16).toString("hex");
        const hash = crypto.createHash("sha256").update(salt + answer.trim(), "utf8").digest("hex");
        const db = getReadoDb();
        await db.collection("users").doc(uid).set({
            securityQuestionId: questionId,
            securityAnswerSalt: salt,
            securityAnswerHash: hash,
            securityQuestionUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        return { success: true };
    }
);

/**
 * 通过密保答案重置密码
 * 入参: { email, answer, newPassword }
 */
exports.resetPasswordWithSecurityAnswer = onCall(
    { timeoutSeconds: 15 },
    async (request) => {
        const email = request.data?.email;
        const answer = request.data?.answer;
        const newPassword = request.data?.newPassword;
        if (!email || typeof email !== "string" || !email.trim()) {
            throw new HttpsError("invalid-argument", "请提供邮箱");
        }
        if (!answer || typeof answer !== "string") {
            throw new HttpsError("invalid-argument", "请填写密保答案");
        }
        if (!newPassword || typeof newPassword !== "string" || newPassword.length < 6) {
            throw new HttpsError("invalid-argument", "新密码至少 6 位");
        }
        const normalizedEmail = email.trim().toLowerCase();
        let uid;
        try {
            const userRecord = await admin.auth().getUserByEmail(normalizedEmail);
            uid = userRecord.uid;
        } catch (e) {
            throw new HttpsError("not-found", "该邮箱未注册");
        }
        const db = getReadoDb();
        const userRef = db.collection("users").doc(uid);
        const doc = await userRef.get();
        if (!doc.exists) {
            throw new HttpsError("failed-precondition", "未设置密保，无法通过密保找回");
        }
        const data = doc.data() || {};
        const salt = data.securityAnswerSalt;
        const storedHash = data.securityAnswerHash;
        if (!salt || !storedHash) {
            throw new HttpsError("failed-precondition", "未设置密保，请使用邮件重置");
        }
        const hash = crypto.createHash("sha256").update(salt + answer.trim(), "utf8").digest("hex");
        if (hash !== storedHash) {
            throw new HttpsError("invalid-argument", "密保答案错误");
        }
        await admin.auth().updateUser(uid, { password: newPassword });
        return { success: true };
    }
);
