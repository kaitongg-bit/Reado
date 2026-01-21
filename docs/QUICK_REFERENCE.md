# QuickPM 数据存储快速参考卡

**版本：** v1.0  
**目标：** 生产环境数据存储方案一览

---

## 📊 Firestore 集合结构速查表

### 官方内容（公共，只读）

```
/feed_items/{itemId}
├── id: string                      # 唯一标识
├── module: "A"|"B"|"C"|"D"        # 模块分类
├── title: string                   # 标题
├── category: string                # 分类
├── difficulty: "Easy"|"Medium"|"Hard"
├── estimatedMinutes: number        # 预计学习时长
├── pages: array                    # 内容页面
└── createdAt: timestamp
```

**安全规则：**
```javascript
allow read: if isSignedIn();
allow write: if false;  // 仅管理员
```

---

### 用户数据（私有，读写受限）

#### 1. 用户配置
```
/users/{uid}/profile
├── displayName: string
├── email: string
├── dailyGoalMinutes: number
├── targetOfferDate: timestamp
├── isPro: boolean
└── geminiApiKey: string (可选)
```

#### 2. 学习进度
```
/users/{uid}/learning_progress/{feedItemId}
├── feedItemId: string
├── masteryLevel: "unknown"|"hard"|"medium"|"easy"
├── isFavorited: boolean
├── nextReviewTime: timestamp
├── intervalDays: number
├── easeFactor: number
└── lastReviewedAt: timestamp
```

#### 3. 用户笔记
```
/users/{uid}/user_notes/{noteId}
├── feedItemId: string         # 关联的知识点
├── question: string            # 用户提问
├── answer: string              # AI 回答
├── createdAt: timestamp
└── isPinned: boolean
```

#### 4. 自定义知识点
```
/users/{uid}/custom_items/{customItemId}
├── id: string
├── module: string
├── title: string
├── category: string
├── difficulty: string
├── pages: array
├── source: "ai_generated"
├── sourceText: string          # 原始输入
└── createdAt: timestamp
```

#### 5. 面经文档
```
/users/{uid}/war_room_docs/{docId}
├── templateId: string
├── category: string
├── title: string
├── content: string (Markdown)
├── resumeContext: string
├── createdAt: timestamp
└── lastModified: timestamp
```

**安全规则：**
```javascript
allow read, write: if request.auth.uid == uid;
```

---

## 🔐 认证流程

### 阶段 1：匿名登录（自动）
```dart
// main.dart - 应用启动时
await FirebaseAuth.instance.signInAnonymously();
// → 生成临时 UID
```

### 阶段 2：账号升级（可选）
```dart
// 绑定邮箱/Google 账号
final credential = EmailAuthProvider.credential(...);
await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
// → UID 保持不变，数据全部保留
```

---

## 🤖 Gemini API 配置

### 依赖
```yaml
# pubspec.yaml
dependencies:
  google_generative_ai: ^0.4.6
```

### 初始化
```dart
final model = GenerativeModel(
  model: 'gemini-2.0-flash-exp',
  apiKey: 'AIzaSyC_YOUR_KEY',
  generationConfig: GenerationConfig(
    responseMimeType: 'application/json',
  ),
);
```

### API Key 管理策略

| 方案 | 安全性 | 适用场景 |
|------|--------|---------|
| 环境变量 | ⚠️ 中 | 开发阶段 |
| 用户提供 | ✅ 高 | 生产环境 |
| 混合模式 | ✅ 高 | MVP（推荐） |

**混合模式实现：**
- 免费额度：10 次/用户（使用你的 Key）
- 超出后：提示用户添加自己的 Key
- 存储位置：`/users/{uid}/profile/geminiApiKey`

---

## 📝 数据操作代码示例

### 1. 保存自定义知识点
```dart
Future<void> saveCustomItem(FeedItem item) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  
  await FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .collection('custom_items')
    .doc(item.id)
    .set(item.toJson());
}
```

### 2. 读取学习进度
```dart
Future<Map<String, dynamic>?> getProgress(String feedItemId) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  
  final doc = await FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .collection('learning_progress')
    .doc(feedItemId)
    .get();
  
  return doc.data();
}
```

### 3. 保存用户笔记
```dart
Future<void> saveNote({
  required String feedItemId,
  required String question,
  required String answer,
}) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final noteId = DateTime.now().millisecondsSinceEpoch.toString();
  
  await FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .collection('user_notes')
    .doc(noteId)
    .set({
      'feedItemId': feedItemId,
      'question': question,
      'answer': answer,
      'createdAt': FieldValue.serverTimestamp(),
      'isPinned': true,
    });
}
```

### 4. 更新 SRS 状态
```dart
Future<void> updateSRS({
  required String feedItemId,
  required String masteryLevel,
  required DateTime nextReviewTime,
}) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  
  await FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .collection('learning_progress')
    .doc(feedItemId)
    .set({
      'feedItemId': feedItemId,
      'masteryLevel': masteryLevel,
      'nextReviewTime': Timestamp.fromDate(nextReviewTime),
      'lastReviewedAt': FieldValue.serverTimestamp(),
      'reviewCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
}
```

---

## 🔄 典型数据流

### 用户上传学习资料
```
1. 用户粘贴文本
2. 调用 Gemini API → 生成 JSON
3. 解析为 FeedItem 对象
4. 保存到 /users/{uid}/custom_items/
5. Provider 刷新 → UI 更新
```

### 复习流程
```
1. 查询 /users/{uid}/learning_progress/
   WHERE nextReviewTime <= now()
2. 显示待复习列表
3. 用户选择掌握程度
4. 更新 masteryLevel 和 nextReviewTime
5. 跳转到下一个
```

---

## ⚠️ 常见陷阱

### 1. UID 为 null
```dart
❌ 错误写法
final uid = FirebaseAuth.instance.currentUser?.uid;
// uid 可能为 null！

✅ 正确写法
final user = FirebaseAuth.instance.currentUser;
if (user == null) throw Exception('User not logged in');
final uid = user.uid;
```

### 2. 时间戳格式
```dart
❌ 错误
'createdAt': DateTime.now()  // 会报错

✅ 正确
'createdAt': FieldValue.serverTimestamp()
// 或
'createdAt': Timestamp.fromDate(DateTime.now())
```

### 3. 集合路径拼写错误
```dart
❌ 错误
.collection('users/{uid}/custom_items')  // 不要包含变量

✅ 正确
.collection('users').doc(uid).collection('custom_items')
```

---

## 📋 上线前检查清单

数据存储相关：
- [ ] Firestore 安全规则已部署
- [ ] 所有写操作都检查了 UID
- [ ] 错误处理完善（网络失败、权限拒绝）
- [ ] 数据模型有 toJson/fromJson 方法
- [ ] 测试了匿名登录 → 账号升级流程

API 相关：
- [ ] Gemini API Key 已配置
- [ ] API 调用有配额限制
- [ ] 错误提示友好（配额用完、Key 无效）
- [ ] 敏感信息不在 Git 中

---

## 🆘 快速问题排查

| 症状 | 可能原因 | 解决方案 |
|------|---------|---------|
| 数据保存后刷新丢失 | 只存在内存中 | 检查是否调用了 Firestore API |
| Permission denied | 安全规则拒绝 | 检查用户是否已登录，规则是否正确 |
| UID is null | 用户未登录 | 确保 main.dart 中的匿名登录已执行 |
| API 403 错误 | API Key 无效/配额用完 | 检查 API Key，查看 AI Studio 配额 |
| Data not loading | 查询条件错误 | 打印查询语句，检查集合路径 |

---

**快速链接：**
- 📖 完整文档：[DATA_STORAGE_ARCHITECTURE.md](./DATA_STORAGE_ARCHITECTURE.md)
- 🤖 API 指南：[GEMINI_API_MIGRATION.md](./GEMINI_API_MIGRATION.md)
- 📚 文档中心：[README.md](./README.md)

**最后更新：** 2026-01-20
