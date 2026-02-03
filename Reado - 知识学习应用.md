# Reado - 知识学习应用

Reado 是一款基于间隔重复算法的知识学习应用，让学习像刷短视频一样简单有趣。

## 项目结构

```
readoManus/              # Flutter 前端应用
readoManus-backend/      # Node.js 后端 API
```

## 技术栈

### 前端 (Flutter)
- **框架**: Flutter 3.x
- **语言**: Dart
- **状态管理**: Provider
- **HTTP 客户端**: http 包
- **本地存储**: flutter_secure_storage
- **动画**: flutter_animate
- **字体**: google_fonts

### 后端 (Node.js)
- **框架**: Express + tRPC
- **数据库**: SQLite (通过 Drizzle ORM)
- **认证**: JWT + Cookie Session
- **文件存储**: AWS S3
- **类型安全**: TypeScript

## 功能特性

- 用户认证（邮箱注册/登录）
- 知识库管理（创建、编辑、删除）
- 官方知识库模板（可一键添加到个人库）
- 卡片学习系统（间隔重复算法）
- 学习进度追踪（掌握度等级）
- 个人资料管理（头像上传）
- 探索页面（官方精选 + 创作者市场）

---

## 前后端适配指南

### 1. 后端部署

#### 环境变量配置

后端需要以下环境变量：

```bash
# 数据库
DATABASE_URL=your_database_url

# JWT 密钥
JWT_SECRET=your_jwt_secret

# S3 存储（用于头像上传）
BUILT_IN_FORGE_API_URL=your_s3_api_url
BUILT_IN_FORGE_API_KEY=your_s3_api_key
```

#### 本地运行

```bash
cd readoManus-backend
pnpm install
pnpm db:push    # 初始化数据库
pnpm dev        # 启动开发服务器 (默认端口 3000)
```

#### 生产部署

后端可以部署到：
- Manus 平台（推荐，已配置好环境）
- Railway
- Render
- 自有服务器

### 2. 前端配置

#### 修改 API 地址

编辑 `lib/core/api/api_client.dart`，修改 `baseUrl` 为您的后端地址：

```dart
class ApiClient {
  // 修改为您的后端 API 地址
  static String baseUrl = 'https://your-backend-domain.com';
  
  // ... 其他代码
}
```

#### 本地开发

```bash
cd readoManus
flutter pub get
flutter run -d chrome    # Web 版本
flutter run              # 移动端（需要模拟器/真机）
```

#### 构建发布版本

```bash
# Web 版本
flutter build web --release

# Android APK
flutter build apk --release

# iOS (需要 macOS)
flutter build ios --release
```

### 3. CORS 配置

后端已配置 CORS 支持以下域名：

```typescript
// server/index.ts
const allowedOrigins = [
  'https://reado-manus.vercel.app',
  'https://readobackend-ixuqlatw.manus.space',
  /\.vercel\.app$/,
  /\.manus\.space$/,
  /localhost/,
];
```

如果您部署到其他域名，需要在后端 `server/index.ts` 中添加您的域名到 `allowedOrigins` 数组。

### 4. 数据库迁移

首次部署或修改数据库模型后：

```bash
cd readoManus-backend
pnpm db:push    # 推送数据库变更
```

---

## API 接口说明

### 认证相关

| 接口 | 方法 | 说明 |
|------|------|------|
| `auth.register` | POST | 用户注册 |
| `auth.login` | POST | 用户登录 |
| `auth.logout` | POST | 用户登出 |
| `auth.me` | GET | 获取当前用户信息 |
| `auth.updateProfile` | POST | 更新用户资料 |
| `auth.uploadAvatar` | POST | 上传头像 |

### 知识库相关

| 接口 | 方法 | 说明 |
|------|------|------|
| `library.list` | GET | 获取用户知识库列表 |
| `library.get` | GET | 获取单个知识库详情 |
| `library.create` | POST | 创建知识库 |
| `library.update` | POST | 更新知识库 |
| `library.delete` | POST | 删除知识库 |

### 卡片相关

| 接口 | 方法 | 说明 |
|------|------|------|
| `card.list` | GET | 获取知识库下的卡片列表 |
| `card.create` | POST | 创建卡片 |
| `card.update` | POST | 更新卡片 |
| `card.delete` | POST | 删除卡片 |
| `card.updateProgress` | POST | 更新学习进度 |

### 探索页相关

| 接口 | 方法 | 说明 |
|------|------|------|
| `explore.getOfficialLibraries` | GET | 获取官方知识库列表 |
| `explore.getOfficialLibraryDetail` | GET | 获取官方知识库详情 |
| `explore.addOfficialLibraryToUser` | POST | 添加官方库到用户库 |
| `explore.getUserAddedOfficialLibraries` | GET | 获取用户已添加的官方库 |

---

## 目录结构

### 前端 (Flutter)

```
lib/
├── core/
│   ├── api/
│   │   ├── api_client.dart      # API 客户端配置
│   │   ├── auth_service.dart    # 认证服务
│   │   ├── library_service.dart # 知识库服务
│   │   └── ai_service.dart      # AI 服务
│   ├── models/
│   │   └── models.dart          # 数据模型
│   └── theme/
│       └── app_theme.dart       # 主题配置
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_provider.dart    # 认证状态管理
│   │   └── presentation/
│   │       ├── login_page.dart       # 登录页
│   │       └── register_page.dart    # 注册页
│   ├── home/
│   │   └── presentation/
│   │       ├── main_page.dart        # 主页框架
│   │       └── home_tab.dart         # 首页标签
│   ├── explore/
│   │   └── presentation/
│   │       └── explore_page.dart     # 探索页
│   ├── feed/
│   │   └── presentation/
│   │       └── feed_page.dart        # 学习页（卡片滑动）
│   ├── lab/
│   │   └── presentation/
│   │       └── lab_page.dart         # 知识库详情页
│   ├── vault/
│   │   └── presentation/
│   │       └── vault_page.dart       # 卡片管理页
│   └── profile/
│       └── presentation/
│           └── profile_page.dart     # 个人资料页
├── widgets/
│   └── common_widgets.dart           # 通用组件
└── main.dart                         # 应用入口
```

### 后端 (Node.js)

```
server/
├── _core/
│   ├── context.ts       # tRPC 上下文
│   ├── env.ts           # 环境变量
│   ├── llm.ts           # LLM 集成
│   └── ...
├── routers/
│   ├── auth.ts          # 认证路由
│   ├── library.ts       # 知识库路由
│   ├── card.ts          # 卡片路由
│   └── explore.ts       # 探索页路由
├── db.ts                # 数据库查询
├── routers.ts           # 路由聚合
├── storage.ts           # S3 存储
└── index.ts             # 服务入口

drizzle/
└── schema.ts            # 数据库模型定义
```

---

## 常见问题

### Q: 登录后 Cookie 不生效？

确保：
1. 后端 CORS 配置了 `credentials: true`
2. 前端使用 `BrowserClient` 并设置 `withCredentials = true`
3. 后端和前端不在同一域名时，Cookie 需要设置 `SameSite=None; Secure`

### Q: 如何添加新的官方知识库？

在后端 `server/routers/explore.ts` 中的 `OFFICIAL_LIBRARIES` 数组添加新的知识库数据。

### Q: 如何修改主题颜色？

编辑 `lib/core/theme/app_theme.dart` 中的颜色常量。

### Q: 移动端如何处理认证？

移动端不支持 Cookie，需要使用 Token 认证。在 `api_client.dart` 中已预留了 Token 存储方法，可以根据平台切换认证方式。

---

## 部署清单

- [ ] 部署后端到服务器
- [ ] 配置后端环境变量
- [ ] 运行数据库迁移 `pnpm db:push`
- [ ] 修改前端 `baseUrl` 为后端地址
- [ ] 添加前端域名到后端 CORS 配置
- [ ] 构建前端 `flutter build web`
- [ ] 部署前端到 Vercel/Netlify

---

## 许可证

MIT License
