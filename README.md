# Reado（QuickPM）- 知识学习应用

AI 知识流的知识学习应用：支持知识库管理、AI 智能拆解、卡片学习与收藏复习。Web 端使用 Flutter + Firebase（Hosting、Firestore、Cloud Functions）。

---

## 快速开始

### 环境要求

- **Flutter** 3.x（含 Dart 3.2+）
- **Node.js** 22（仅部署云函数时需要）
- **Firebase CLI**：`npm install -g firebase-tools` 并 `firebase login`

### 1. 克隆与依赖

```bash
git clone <仓库地址>
cd QuickPM
flutter pub get
```

### 2. 本地运行（Web）

在项目根目录执行：

```bash
flutter run -d chrome
```

或使用本机 Web 服务器：

```bash
flutter run -d web-server
```

浏览器打开终端里给出的地址（如 `http://localhost:xxxxx`）即可。  
如需使用 AI 拆解/代理，需在项目根目录配置 `.env`（见下方「环境配置」）。

### 3. 部署到线上

#### 部署前端（网站）

在项目根目录执行：

```bash
./deploy_to_web.sh
```

若无执行权限，先执行 `chmod +x deploy_to_web.sh` 再运行上述命令。

脚本会：从 `.env` 读取代理地址、自动递增 `pubspec.yaml` 版本号、执行 `flutter build web`、并执行 `firebase deploy --only hosting`。部署完成后访问 Firebase Hosting 提供的 URL（如 `https://reado-c8d21.web.app`）。

#### 部署云函数（仅修改了 functions 时）

修改了 `functions/` 下代码或首次配置云函数时：

1. **配置 Secret（仅首次或更换 Key 时）**  
   在项目根目录执行：
   ```bash
   firebase functions:secrets:set GEMINI_API_KEY
   ```
   按提示输入 Gemini API Key。

2. **若之前部署过 1st gen 云函数**，需先删除再部署 2nd gen：
   ```bash
   firebase functions:delete geminiProxy processExtractionJob --force
   ```

3. **部署云函数**：
   ```bash
   firebase deploy --only functions
   ```

更多说明（含冲突报错处理）见 [functions/SECRETS_MIGRATION.md](functions/SECRETS_MIGRATION.md)。

---

## 环境配置

### 前端 / 部署脚本

在项目根目录创建或编辑 `.env`，用于**本地开发**和 **deploy_to_web.sh** 的打包注入：

```bash
# 可选：本地直连 Gemini 时使用
GEMINI_API_KEY=your_gemini_api_key

# 推荐：Web 生产环境走代理（Cloud Function 地址）
GEMINI_PROXY_URL=https://us-central1-<project-id>.cloudfunctions.net/geminiProxy
```

- 使用代理时，`deploy_to_web.sh` 会读取 `GEMINI_PROXY_URL` 并注入到 Web 构建中。
- 云函数的 API Key 不放在 `.env`，而是通过 Firebase Secret Manager 配置（见上文及 `functions/SECRETS_MIGRATION.md`）。

### 云函数

敏感配置（如 Gemini API Key）使用 Firebase Secret Manager，不再使用 `functions.config()` 或 `functions/.env` 中的 `GEMINI_API_KEY`。详见 [functions/SECRETS_MIGRATION.md](functions/SECRETS_MIGRATION.md)。

---

## 项目结构

```
QuickPM/
├── lib/                    # Flutter 应用源码
│   ├── main.dart
│   ├── core/               # 路由、主题、服务、通用组件
│   └── features/           # 功能模块（home, feed, lab, vault, profile, …）
├── functions/              # Firebase Cloud Functions（2nd gen）
│   ├── index.js            # geminiProxy、processExtractionJob
│   └── SECRETS_MIGRATION.md
├── build/web/              # flutter build web 输出（部署到 Hosting）
├── firebase.json           # Firebase 配置（Hosting + Functions）
├── deploy_to_web.sh        # 一键部署前端脚本
└── .env                    # 本地/构建用环境变量（勿提交敏感 key）
```

---

## 技术栈

- **前端**: Flutter 3.x、Dart 3.2+、Riverpod、go_router、Firebase Auth / Firestore
- **后端/服务**: Firebase（Hosting、Firestore、Cloud Functions 2nd gen）、Gemini API（经 Cloud Function 代理）

---

## 功能概览

- 用户认证（邮箱/Google 等）
- 知识库管理（官方 + 个人）、AI 智能拆解生成知识点
- 学习流（卡片滑动、掌握度、间隔复习）
- 收藏与复习、个人资料与积分

---

## 部署清单（给协作者）

- [ ] 安装 Flutter、Node、Firebase CLI
- [ ] 克隆仓库并 `flutter pub get`
- [ ] 根目录配置 `.env`（`GEMINI_PROXY_URL` 或 `GEMINI_API_KEY`）
- [ ] 云函数：`firebase functions:secrets:set GEMINI_API_KEY`（若尚未配置）
- [ ] 若曾部署过 1st gen 云函数，先 `firebase functions:delete geminiProxy processExtractionJob --force`
- [ ] 部署云函数：`firebase deploy --only functions`
- [ ] 部署前端：`./deploy_to_web.sh`

---

## 常见问题

- **部署报错 “Upgrading from 1st Gen to 2nd Gen is not yet supported”**  
  先删除旧云函数再部署，见上文「部署云函数」步骤 2 或 [functions/SECRETS_MIGRATION.md](functions/SECRETS_MIGRATION.md)。

- **部署报错 “Secret environment variable overlaps non secret environment variable: GEMINI_API_KEY”**  
  删除 `functions/.env` 中的 `GEMINI_API_KEY=...` 行，仅用 Secret Manager 存储。详见 [functions/SECRETS_MIGRATION.md](functions/SECRETS_MIGRATION.md)。

- **用户浏览器一直看到旧版**  
  每次发布前运行 `./deploy_to_web.sh` 会自动递增版本号，便于缓存更新；或让用户强制刷新 / 无痕打开。

---

## 许可证

MIT License
