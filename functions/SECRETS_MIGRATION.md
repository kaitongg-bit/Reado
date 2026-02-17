# 云函数配置迁移说明（Secret Manager）

本项目已按 Firebase 要求，将敏感配置从旧版运行时配置迁移到 **Secret Manager**，并升级为 **2nd gen** 云函数。

## 你需要做的（首次部署或未设置过密钥时）

1. **在项目根目录执行**（会提示你输入 Gemini API Key）：
   ```bash
   firebase functions:secrets:set GEMINI_API_KEY
   ```
   按提示输入你的 Gemini API Key 并确认。

2. **若之前已部署过 1st gen 云函数**（部署时报错 “Upgrading from 1st Gen to 2nd Gen is not yet supported”）  
   需先删除旧函数，再部署新的 2nd gen（同名）：
   ```bash
   firebase functions:delete geminiProxy processExtractionJob --force
   firebase deploy --only functions
   ```
   `--force` 避免交互确认；删除后到部署完成前会有短暂不可用。

3. **若没有上述报错，直接部署**：
   ```bash
   firebase deploy --only functions
   ```

若你之前用 `firebase functions:config:set` 存过配置，可先导出再写入 Secret：
   ```bash
   firebase functions:config:get | firebase functions:secrets:set GEMINI_API_KEY --data-file=-
   ```
   （若原 key 不是 `GEMINI_API_KEY`，需按实际 key 名在代码或上述命令中对应调整。）

## 代码变更摘要

- **geminiProxy**、**processExtractionJob** 已改为 2nd gen：`onRequest` / `onCall`（`firebase-functions/v2/https`）。
- API Key 改为通过 `defineSecret("GEMINI_API_KEY")` 声明，在函数内用 `geminiApiKey.value()` 读取。
- 不再使用 `functions.config()` 或 `process.env.GEMINI_API_KEY`（由 Secret Manager 注入）。

**若部署报错 “Secret environment variable overlaps non secret environment variable: GEMINI_API_KEY”**：说明 `functions/.env` 里还有同名变量。删掉其中的 `GEMINI_API_KEY=...` 这一行即可（Key 已用 Secret 存储，不必写在 .env）。

更多说明见 [Firebase 配置与环境](https://firebase.google.com/docs/functions/config-env)。
