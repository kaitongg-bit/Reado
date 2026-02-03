const functions = require("firebase-functions");
const axios = require("axios");

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
