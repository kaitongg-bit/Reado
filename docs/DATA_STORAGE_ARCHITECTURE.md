# QuickPM 数据存储架构设计文档 (生产环境)

**版本：** 1.0 Production Ready  
**更新日期：** 2026-01-20  
**目标：** 定义清晰的数据存储策略，支持匿名登录和正式登录两种场景

---

## 目录

1. [架构总览](#架构总览)
2. [认证策略](#认证策略)
3. [Firestore 数据库设计](#firestore-数据库设计)
4. [数据类型与存储位置](#数据类型与存储位置)
5. [安全规则](#安全规则)
6. [数据迁移策略](#数据迁移策略)
7. [API 配置](#api-配置)

---

## 架构总览

### 设计原则

```
┌─────────────────────────────────────────────────────────────┐
│                    QuickPM 数据架构                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  📊 官方内容 (公共)          👤 用户数据 (私有)              │
│  ├─ 存储位置: /feed_items    ├─ 存储位置: /users/{uid}/    │
│  ├─ 所有人只读               ├─ 仅所有者读写                │
│  ├─ 管理员可写               ├─ 包含个人学习数据            │
│  └─ 预先上传的课程内容       └─ AI生成、笔记、进度          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 核心理念

1. **公私分离**：官方内容与用户数据完全隔离
2. **UID 绑定**：所有用户数据必须关联到 `userId`
3. **可迁移性**：匿名用户升级为正式用户时，数据可平滑迁移
4. **安全优先**：通过 Firestore 规则确保数据隔离

---

## 认证策略

### 阶段一：匿名登录 (MVP)

```dart
// 应用启动时自动执行
FirebaseAuth.instance.signInAnonymously();

// 获得临时 UID，例如：
// uid = "anon_abc123..."
```

**特点：**
- ✅ 用户无需注册，立即使用
- ✅ 拥有独立的用户 ID (UID)
- ⚠️ 卸载 App → 数据丢失
- ❌ 无法跨设备同步

**适用场景：** 快速验证产品，降低注册门槛

---

### 阶段二：账号升级 (正式登录)

用户可将匿名账号升级为正式账号：

```dart
// 方式 1: 绑定邮箱
final credential = EmailAuthProvider.credential(
  email: email, 
  password: password
);
await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);

// 方式 2: 绑定 Google 账号
final googleCredential = await GoogleSignIn().signIn();
await FirebaseAuth.instance.currentUser!.linkWithCredential(googleCredential);
```

**升级后的效果：**
- ✅ 数据全部保留（UID 不变）
- ✅ 支持多设备同步
- ✅ 账号安全性提升
- ✅ 可找回密码

---

### 阶段三：完整用户管理 (Scale-up)

```dart
// 直接注册/登录
await FirebaseAuth.instance.createUserWithEmailAndPassword(...);
await FirebaseAuth.instance.signInWithEmailAndPassword(...);
```

**多端策略：**
- Web：优先 Google 登录 / 邮箱登录
- 移动端：支持 Apple Sign-In（iOS）/ Google（Android）

---

## Firestore 数据库设计

### 完整集合结构

```
quickpm-8f9c9/
│
├── feed_items/                        # 官方知识点库 (公共资源)
│   ├── {itemId}/                      # 单个知识点文档
│   │   ├── id: string                 # 唯一标识
│   │   ├── module: string             # 模块: A/B/C/D
│   │   ├── title: string              # 标题
│   │   ├── category: string           # 分类
│   │   ├── difficulty: string         # 难度: Easy/Medium/Hard
│   │   ├── estimatedMinutes: number   # 预计学习时长
│   │   ├── pages: array               # 内容页面
│   │   │   └── [
│   │   │        {
│   │   │          type: "official",
│   │   │          markdown: "...",
│   │   │          flashcard: {q, a}
│   │   │        }
│   │   │      ]
│   │   ├── tags: array                # 标签
│   │   ├── createdAt: timestamp
│   │   └── updatedAt: timestamp
│   │
│   └── ... (其他官方内容)
│
├── users/                             # 用户根目录
│   ├── {uid}/                         # 单个用户的数据空间
│   │   ├── profile/                   # 用户配置 (单文档)
│   │   │   ├── displayName: string
│   │   │   ├── email: string
│   │   │   ├── dailyGoalMinutes: number
│   │   │   ├── targetOfferDate: timestamp
│   │   │   ├── createdAt: timestamp
│   │   │   └── isPro: boolean
│   │   │
│   │   ├── learning_progress/        # 学习进度 (子集合)
│   │   │   └── {feedItemId}/         # 每个知识点的学习状态
│   │   │       ├── feedItemId: string
│   │   │       ├── masteryLevel: string      # unknown/hard/medium/easy
│   │   │       ├── isFavorited: boolean
│   │   │       ├── nextReviewTime: timestamp # SRS 算法
│   │   │       ├── intervalDays: number
│   │   │       ├── easeFactor: number
│   │   │       ├── lastReviewedAt: timestamp
│   │   │       └── reviewCount: number
│   │   │
│   │   ├── user_notes/                # 用户笔记 (子集合)
│   │   │   └── {noteId}/              # AI 对话生成的笔记
│   │   │       ├── feedItemId: string         # 关联的知识点
│   │   │       ├── question: string           # 用户提问
│   │   │       ├── answer: string             # AI 回答
│   │   │       ├── createdAt: timestamp
│   │   │       └── isPinned: boolean          # 是否钉住到知识点
│   │   │
│   │   ├── custom_items/              # 用户自定义知识点 (子集合)
│   │   │   └── {customItemId}/        # AI 生成的自定义内容
│   │   │       ├── id: string
│   │   │       ├── module: string             # 用户指定的模块
│   │   │       ├── title: string
│   │   │       ├── category: string
│   │   │       ├── difficulty: string
│   │   │       ├── pages: array
│   │   │       ├── source: string             # "ai_generated"
│   │   │       ├── sourceText: string         # 原始输入文本
│   │   │       └── createdAt: timestamp
│   │   │
│   │   └── war_room_docs/             # 面经文档库 (子集合)
│   │       └── {docId}/               # 用户生成的面试回答
│   │           ├── templateId: string         # 基于哪个模板克隆
│   │           ├── category: string           # 项目/指标/产品设计...
│   │           ├── title: string
│   │           ├── content: string            # Markdown 内容
│   │           ├── resumeContext: string      # 关联的简历信息
│   │           ├── createdAt: timestamp
│   │           └── lastModified: timestamp
│   │
│   └── ... (其他用户)
│
└── war_room_templates/                # 面经模板库 (公共资源)
    └── {templateId}/
        ├── category: string
        ├── title: string
        ├── goldStandardAnswer: string
        ├── framework: string          # STAR / 5W2H ...
        └── createdAt: timestamp
```

---

## 数据类型与存储位置

### 1. 官方知识点 (Official Content)

**集合路径：** `/feed_items/{itemId}`

**数据示例：**
```json
{
  "id": "pm_basics_001",
  "module": "B",
  "title": "什么是产品经理",
  "category": "基础概念",
  "difficulty": "Easy",
  "estimatedMinutes": 10,
  "pages": [
    {
      "type": "official",
      "markdown": "产品经理是...",
      "flashcard": {
        "question": "产品经理的核心职责是什么？",
        "answer": "定义产品方向，协调资源..."
      }
    }
  ],
  "tags": ["产品", "基础"],
  "createdAt": "2026-01-01T00:00:00Z"
}
```

**访问控制：**
- 读取：所有已登录用户（包括匿名）
- 写入：仅管理员

**更新策略：**
- 内容由管理员通过 Firebase Console 或脚本上传
- 不允许用户修改

---

### 2. 学习进度 (Learning Progress)

**集合路径：** `/users/{uid}/learning_progress/{feedItemId}`

**数据示例：**
```json
{
  "feedItemId": "pm_basics_001",
  "masteryLevel": "medium",        // unknown → hard → medium → easy
  "isFavorited": true,
  "nextReviewTime": "2026-01-25T10:00:00Z",
  "intervalDays": 3,
  "easeFactor": 2.5,
  "lastReviewedAt": "2026-01-22T10:00:00Z",
  "reviewCount": 5
}
```

**触发时机：**
- 用户在 Feed 页面阅读知识点时创建
- 在 Vault 复习时更新 SRS 数据
- 收藏/取消收藏时更新

**读写权限：**
- 仅当前用户可读写

---

### 3. 用户笔记 (User Notes)

**集合路径：** `/users/{uid}/user_notes/{noteId}`

**数据示例：**
```json
{
  "noteId": "note_abc123",
  "feedItemId": "pm_basics_001",
  "question": "产品经理和项目经理的区别是什么？",
  "answer": "产品经理关注 What 和 Why，项目经理关注 When 和 How...",
  "createdAt": "2026-01-20T15:30:00Z",
  "isPinned": true
}
```

**生成流程：**
1. 用户在 Feed 页面点击 "Ask AI"
2. 输入问题，调用 Gemini API
3. 点击 "Pin to Card"
4. 保存到 Firestore：`/users/{uid}/user_notes/`
5. 前端动态加载并追加到知识点的 `pages` 数组

**关联逻辑：**
- 前端读取 `feed_items/{id}` 的官方内容
- 同时读取 `/users/{uid}/user_notes?feedItemId={id}`
- 合并显示

---

### 4. 自定义知识点 (Custom Items)

**集合路径：** `/users/{uid}/custom_items/{customItemId}`

**数据示例：**
```json
{
  "id": "custom_20260120_001",
  "module": "B",
  "title": "什么是 OKR",
  "category": "用户自定义",
  "difficulty": "Medium",
  "pages": [
    {
      "type": "ai_generated",
      "markdown": "OKR 是 Objectives and Key Results 的缩写...",
      "flashcard": {
        "question": "OKR 和 KPI 的区别？",
        "answer": "OKR 关注目标和结果..."
      }
    }
  ],
  "source": "ai_generated",
  "sourceText": "用户粘贴的原始文本...",
  "createdAt": "2026-01-20T22:00:00Z"
}
```

**生成流程：**
1. 用户点击 "Add Material"
2. 粘贴文本内容
3. 调用 Gemini API 生成结构化知识点
4. 保存到 `/users/{uid}/custom_items/`

**显示逻辑：**
- 在 Feed 页面中，**混合显示**官方内容和用户自定义内容
- 通过 Provider 合并：
  ```dart
  final allItems = [
    ...officialItems,  // 来自 /feed_items
    ...customItems     // 来自 /users/{uid}/custom_items
  ];
  ```

---

### 5. 用户配置 (Profile)

**文档路径：** `/users/{uid}/profile` (单文档，非集合)

**数据示例：**
```json
{
  "displayName": "张三",
  "email": "zhangsan@example.com",
  "dailyGoalMinutes": 30,
  "targetOfferDate": "2026-03-15T00:00:00Z",
  "createdAt": "2026-01-15T08:00:00Z",
  "isPro": false,
  "apiKeys": {
    "geminiApiKey": "user_provided_key_optional"  // 用户可选提供
  }
}
```

**使用场景：**
- Onboarding 页面设置每日目标
- Profile 页面修改设置
- 计算倒计时

---

### 6. 面经文档 (War Room Documents)

**集合路径：** `/users/{uid}/war_room_docs/{docId}`

**数据示例：**
```json
{
  "docId": "wr_001",
  "templateId": "template_project_experience",
  "category": "项目经历",
  "title": "我的电商推荐系统项目",
  "content": "# 项目背景\n我在 XX 公司负责...",
  "resumeContext": "简历中的项目描述...",
  "createdAt": "2026-01-18T14:00:00Z",
  "lastModified": "2026-01-19T10:00:00Z"
}
```

**工作流：**
1. 用户在 War Room 浏览模板
2. 点击 "用我的经历重写"
3. 与 AI 对话，输入简历信息
4. AI 生成个性化回答
5. 保存到 `/users/{uid}/war_room_docs/`

---

## 安全规则

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // 辅助函数：检查是否已登录
    function isSignedIn() {
      return request.auth != null;
    }
    
    // 辅助函数：检查是否是文档所有者
    function isOwner(uid) {
      return request.auth.uid == uid;
    }
    
    // ============================================
    // 官方知识点库：所有人可读，仅管理员可写
    // ============================================
    match /feed_items/{itemId} {
      allow read: if isSignedIn();
      allow write: if false;  // 仅通过 Firebase Admin SDK 写入
    }
    
    // ============================================
    // 面经模板库：所有人可读
    // ============================================
    match /war_room_templates/{templateId} {
      allow read: if isSignedIn();
      allow write: if false;
    }
    
    // ============================================
    // 用户数据：仅所有者可读写
    // ============================================
    match /users/{uid} {
      // 用户配置
      match /profile {
        allow read, write: if isOwner(uid);
      }
      
      // 学习进度
      match /learning_progress/{progressId} {
        allow read, write: if isOwner(uid);
      }
      
      // 用户笔记
      match /user_notes/{noteId} {
        allow read, write: if isOwner(uid);
      }
      
      // 自定义知识点
      match /custom_items/{customItemId} {
        allow read, write: if isOwner(uid);
      }
      
      // 面经文档
      match /war_room_docs/{docId} {
        allow read, write: if isOwner(uid);
      }
    }
  }
}
```

**部署安全规则：**
```bash
# 将上述规则保存到 firestore.rules
firebase deploy --only firestore:rules
```

---

## 数据迁移策略

### 场景：匿名用户升级为正式用户

**问题：** 用户绑定邮箱后，UID 会改变吗？

**答案：** ❌ **UID 不会改变！**

Firebase 的 `linkWithCredential` 方法会：
- 保持原有的匿名 UID
- 将邮箱/Google 账号绑定到该 UID
- Firestore 中的所有数据路径 (`/users/{uid}/...`) 自动保留

**因此不需要数据迁移！**

---

### 边缘情况：用户注销后重新登录

如果用户：
1. 匿名登录 → 生成 UID_A
2. 未绑定账号就退出登录
3. 再次打开 App → 生成新的 UID_B

**结果：** UID_A 的数据无法恢复

**解决方案：**
- 在 Onboarding 中引导用户尽早绑定账号
- 显示提示："未绑定账号，卸载或登出将丢失数据"

---

## API 配置

### 切换到 Gemini Developer API (2.0 Flash)

**为什么切换？**
- Firebase Vertex AI 有配额限制
- Gemini Developer API 更灵活，可使用个人 API Key
- 支持最新的 Gemini 2.0 Flash 模型

---

### 配置步骤

#### 1. 获取 API Key
访问：https://aistudio.google.com/app/apikey
创建 API Key，例如：`AIzaSyC_YOUR_KEY_HERE`

#### 2. 安装 SDK
在 `pubspec.yaml` 中：
```yaml
dependencies:
  google_generative_ai: ^0.4.0  # Gemini Developer API SDK
```

**移除：**
```yaml
# firebase_vertexai: ^2.2.0  ← 不再使用
```

#### 3. 修改代码

**旧代码：** `lib/core/services/content_generator_service.dart`
```dart
import 'package:firebase_vertexai/firebase_vertexai.dart';

_model = FirebaseVertexAI.instance.generativeModel(...);
```

**新代码：**
```dart
import 'package:google_generative_ai/google_generative_ai.dart';

class ContentGeneratorService {
  late final GenerativeModel _model;
  
  ContentGeneratorService({required String apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-exp',  // 最新模型
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }
  
  // 其他方法保持不变
}
```

#### 4. API Key 管理策略

**选项 A：开发阶段 - 硬编码（不推荐生产）**
```dart
final service = ContentGeneratorService(
  apiKey: 'AIzaSyC_YOUR_DEV_KEY'
);
```

**选项 B：生产环境 - 用户提供 API Key**
```dart
// 从用户配置中读取
final profile = await FirebaseFirestore.instance
  .collection('users')
  .doc(uid)
  .collection('profile')
  .get();

final apiKey = profile.data()?['geminiApiKey'] ?? DEFAULT_KEY;
```

**选项 C：混合模式（推荐）**
- 提供免费额度：使用你的 API Key，限制每日调用次数
- 超过额度：提示用户输入自己的 API Key
- 存储在：`/users/{uid}/profile` 的 `apiKeys.geminiApiKey`

---

### API 调用示例

```dart
Future<List<FeedItem>> generateFromText(String text) async {
  const prompt = '''
  你是教育内容专家。分析以下文本并提取知识点...
  ''';

  final content = [Content.text('$prompt\n\n$text')];
  
  try {
    final response = await _model.generateContent(content);
    final jsonList = jsonDecode(response.text!);
    
    return jsonList.map((json) => FeedItem.fromJson(json)).toList();
  } catch (e) {
    if (e.toString().contains('quota')) {
      throw Exception('API 配额已用完，请在设置中添加你的 API Key');
    }
    rethrow;
  }
}
```

---

## 总结：数据流全景图

```
┌────────────────────────────────────────────────────────────────────┐
│                          用户操作流程                               │
└────────────────────────────────────────────────────────────────────┘
                                  │
                   ┌──────────────┴──────────────┐
                   │                              │
            📖 阅读官方内容              ✍️ 创建自定义内容
                   │                              │
                   ▼                              ▼
        ┌──────────────────┐          ┌──────────────────┐
        │ /feed_items/     │          │ 粘贴文本 →       │
        │ (公共库)         │          │ Gemini API →     │
        └──────────────────┘          │ /users/{uid}/    │
                   │                  │ custom_items/    │
                   │                  └──────────────────┘
                   ▼                              │
        ┌──────────────────┐                     │
        │ 记录学习进度     │◄────────────────────┘
        │ /users/{uid}/    │
        │ learning_progress│
        └──────────────────┘
                   │
                   ▼
        ┌──────────────────┐
        │ 遇到疑问 → Ask AI│
        │ 保存笔记到       │
        │ /users/{uid}/    │
        │ user_notes/      │
        └──────────────────┘
                   │
                   ▼
        ┌──────────────────┐
        │ SRS 复习系统     │
        │ 更新 masteryLevel│
        │ 和 nextReviewTime│
        └──────────────────┘
```

---

## 快速检查清单

在上线前，确保：

- [ ] Firestore 安全规则已部署
- [ ] 所有用户数据写入都包含 `uid` 验证
- [ ] Gemini API Key 已配置（或提供用户输入界面）
- [ ] 测试匿名登录 → 绑定账号的流程
- [ ] Feed Provider 正确合并官方和自定义内容
- [ ] 错误处理：API 超限、网络失败等场景
- [ ] 数据冗余：关键操作有加载状态和失败重试

---

**文档维护者：** AI Assistant  
**需要帮助？** 参考 Firebase 官方文档：https://firebase.google.com/docs/firestore
