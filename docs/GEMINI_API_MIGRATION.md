# Gemini 2.0 Flash API 集成指南

**目标：** 将项目从 Firebase Vertex AI 切换到 Gemini Developer API (2.0 Flash)  
**原因：** 你只能使用 Gemini Developer API，Firebase Vertex AI 不可用  
**更新日期：** 2026-01-20

---

## 一、为什么切换到 Gemini Developer API？

### Firebase Vertex AI vs Gemini Developer API

| 特性 | Firebase Vertex AI | Gemini Developer API |
|------|-------------------|---------------------|
| **需要 Firebase 项目** | ✅ 必须 | ❌ 不需要 |
| **API Key 管理** | 隐式（项目配额） | 显式（个人 API Key） |
| **模型版本** | Gemini 1.5 | **Gemini 2.0 Flash** ✨ |
| **免费额度** | 绑定 Firebase 项目 | 每月独立配额 |
| **适用场景** | Firebase 生态用户 | **独立开发者** ✅ |

**结论：** 如果你无法使用 Firebase Vertex AI，Gemini Developer API 是最佳选择。

---

## 二、获取 Gemini API Key

### 步骤 1：访问 Google AI Studio

🔗 **链接：** https://aistudio.google.com/app/apikey

### 步骤 2：创建 API Key

1. 登录你的 Google 账号
2. 点击 **"Get API key"** 或 **"Create API key"**
3. 选择 **"Create API key in new project"** 或使用现有项目
4. 复制生成的 API Key

**示例：**
```
AIzaSyC_xxxxxxxxxxxxxxxxxxxxxxxxxxx
```

⚠️ **安全提示：** 不要将 API Key 提交到 Git 仓库！

---

## 三、修改项目配置

### 步骤 1：更新 pubspec.yaml

**移除：**
```yaml
dependencies:
  firebase_vertexai: ^2.2.0  # ❌ 删除
```

**添加：**
```yaml
dependencies:
  google_generative_ai: ^0.4.6  # ✅ 添加最新版本
```

**完整的 dependencies 示例：**
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.9
  go_router: ^12.1.0
  flutter_markdown: ^0.6.18+1
  intl: ^0.19.0
  google_fonts: ^6.1.0
  shared_preferences: ^2.2.2
  firebase_core: ^4.3.0
  cloud_firestore: ^6.1.1
  firebase_auth: ^6.1.3
  google_generative_ai: ^0.4.6  # ← 新增
```

### 步骤 2：安装依赖

```bash
flutter pub get
```

---

## 四、代码修改

### 文件：`lib/core/services/content_generator_service.dart`

**旧代码（使用 Firebase Vertex AI）：**

```dart
import 'dart:convert';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/foundation.dart';
import '../../models/feed_item.dart';

class ContentGeneratorService {
  late final GenerativeModel _model;

  ContentGeneratorService() {
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-1.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }
  
  // ... 其他方法
}
```

---

**新代码（使用 Gemini Developer API）：**

```dart
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import '../../models/feed_item.dart';

class ContentGeneratorService {
  late final GenerativeModel _model;

  ContentGeneratorService({required String apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-exp',  // 🚀 使用最新的 Gemini 2.0 Flash
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.7,
        topP: 0.9,
      ),
    );
  }

  /// 生成知识卡片
  Future<List<FeedItem>> generateFromText(String text) async {
    const prompt = '''
    你是一位专业的教育内容创建专家。
    你的任务是分析提供的文本，并将其提炼成多个独立的"知识点"。
    
    对于每个知识点：
    1. 创建一个简洁的标题
    2. 确定难度级别（Easy、Medium、Hard）
    3. 将内容总结为适合 5-15 分钟阅读的 Markdown 格式
    4. 创建一个具体的闪卡问题和答案，用于测试对该知识点的理解
    
    输出一个 JSON 数组，格式如下：
    [
      {
        "title": "String",
        "category": "String",
        "difficulty": "Easy",
        "content": "Markdown 格式的内容...",
        "flashcard": {
          "question": "String",
          "answer": "String"
        }
      }
    ]
    ''';

    final content = [Content.text('$prompt\n\n输入文本：\n$text')];

    try {
      final response = await _model.generateContent(content);
      final responseText = response.text;
      
      if (responseText == null || responseText.isEmpty) {
        throw Exception('AI 未返回任何内容');
      }

      debugPrint('AI 响应: $responseText');

      final List<dynamic> jsonList = jsonDecode(responseText);
      
      return jsonList.map((json) {
        return FeedItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + 
              json['title'].hashCode.toString(),
          moduleId: 'B', // 默认为产品管理模块，或动态设置
          title: json['title'],
          category: json['category'] ?? 'General',
          difficulty: json['difficulty'] ?? 'Normal',
          masteryLevel: FeedItemMastery.unknown,
          pages: [
            OfficialPage(
              json['content'] ?? '',
              flashcardQuestion: json['flashcard']?['question'],
              flashcardAnswer: json['flashcard']?['answer'],
            ),
          ],
        );
      }).toList();
    } catch (e) {
      debugPrint('生成内容时出错: $e');
      
      // 更详细的错误处理
      if (e.toString().contains('API_KEY_INVALID')) {
        throw Exception('API Key 无效，请检查你的 Gemini API Key');
      } else if (e.toString().contains('quota')) {
        throw Exception('API 配额已用完，请稍后再试或升级配额');
      } else if (e.toString().contains('SAFETY')) {
        throw Exception('内容被安全过滤器拦截，请修改输入文本');
      }
      
      rethrow;
    }
  }
}
```

---

### 文件：`lib/features/lab/presentation/add_material_modal.dart`

**修改 Provider 定义：**

**旧代码：**
```dart
final contentGeneratorProvider = Provider((ref) => ContentGeneratorService());
```

**新代码：**
```dart
// 需要传入 API Key
final contentGeneratorProvider = Provider((ref) {
  // TODO: 从环境变量或用户设置中读取 API Key
  const apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_API_KEY_HERE',  // ⚠️ 临时方案，生产环境需改进
  );
  
  return ContentGeneratorService(apiKey: apiKey);
});
```

---

## 五、API Key 管理策略

### 方案 A：开发阶段 - 使用环境变量（推荐）

#### 1. 创建配置文件

**文件：** `lib/config/api_config.dart`

```dart
class ApiConfig {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  
  static bool get isConfigured => geminiApiKey.isNotEmpty;
}
```

#### 2. 在启动命令中传入 API Key

```bash
# 开发环境
flutter run -d web-server --web-port 3000 --dart-define=GEMINI_API_KEY=AIzaSyC_YOUR_KEY_HERE

# 构建生产版本
flutter build web --dart-define=GEMINI_API_KEY=AIzaSyC_YOUR_KEY_HERE
```

⚠️ **缺点：** API Key 仍然会被编译到前端代码中，不够安全。

---

### 方案 B：生产环境 - 用户提供 API Key（最安全）

#### 1. 在用户配置中存储

**Firestore 路径：** `/users/{uid}/profile`

```json
{
  "geminiApiKey": "user_provided_key"
}
```

#### 2. 读取并使用

```dart
final contentGeneratorProvider = Provider.family<ContentGeneratorService?, String>((ref, uid) {
  // 从 Firestore 读取用户的 API Key
  final profileDoc = FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .get();
  
  final apiKey = profileDoc.then((doc) => doc.data()?['geminiApiKey']);
  
  if (apiKey == null) {
    return null;  // 提示用户输入 API Key
  }
  
  return ContentGeneratorService(apiKey: apiKey);
});
```

#### 3. 在 UI 中添加 API Key 输入

**文件：** `lib/features/profile/presentation/profile_page.dart`

```dart
TextField(
  decoration: const InputDecoration(
    labelText: 'Gemini API Key',
    hintText: 'AIzaSyC...',
  ),
  obscureText: true,  // 隐藏 API Key
  onSubmitted: (value) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .update({'geminiApiKey': value});
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API Key 已保存！')),
    );
  },
)
```

---

### 方案 C：混合模式（推荐用于 MVP）

**策略：**
1. 提供有限的免费额度（使用你的 API Key）
2. 超过额度后，提示用户输入自己的 API Key
3. 追踪每个用户的使用次数

**实现：**

```dart
class ContentGeneratorService {
  final String apiKey;
  final String? userId;
  
  ContentGeneratorService({
    required this.apiKey,
    this.userId,
  });
  
  Future<List<FeedItem>> generateFromText(String text) async {
    // 检查用户配额
    if (userId != null) {
      final usageCount = await _checkUsageCount(userId!);
      if (usageCount >= 10) {  // 免费额度：10 次
        throw Exception(
          '免费额度已用完！\n'
          '请在个人中心添加你的 Gemini API Key 以继续使用。'
        );
      }
    }
    
    // 调用 API
    final response = await _model.generateContent(...);
    
    // 增加使用计数
    if (userId != null) {
      await _incrementUsageCount(userId!);
    }
    
    return ...;
  }
  
  Future<int> _checkUsageCount(String uid) async {
    final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
    return doc.data()?['aiUsageCount'] ?? 0;
  }
  
  Future<void> _incrementUsageCount(String uid) async {
    await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .update({
        'aiUsageCount': FieldValue.increment(1),
      });
  }
}
```

---

## 六、测试 Gemini 2.0 Flash

### 测试用例 1：基本文本生成

```dart
void main() async {
  final service = ContentGeneratorService(
    apiKey: 'YOUR_API_KEY',
  );
  
  final result = await service.generateFromText('''
  产品经理需要掌握需求分析、用户研究、原型设计和数据分析四大核心能力。
  需求分析是产品经理的基本功，要学会区分真需求和伪需求。
  ''');
  
  print('生成了 ${result.length} 个知识点');
  for (var item in result) {
    print('- ${item.title} (${item.difficulty})');
  }
}
```

**预期输出：**
```
生成了 2 个知识点
- 产品经理的四大核心能力 (Easy)
- 需求分析：区分真伪需求 (Medium)
```

---

### 测试用例 2：错误处理

```dart
try {
  final service = ContentGeneratorService(apiKey: 'INVALID_KEY');
  await service.generateFromText('测试文本');
} catch (e) {
  print('错误: $e');
  // 应输出: "API Key 无效，请检查你的 Gemini API Key"
}
```

---

## 七、Gemini 2.0 Flash 的新特性

### 1. 更快的响应速度
- Gemini 1.5 Flash: ~3-5 秒
- **Gemini 2.0 Flash: ~1-2 秒** ⚡

### 2. 支持更多模态
- 文本 ✅
- 图片 ✅
- 音频 ✅（新）
- 视频 ✅（新）

**示例：处理图片**
```dart
final imageBytes = await File('path/to/image.png').readAsBytes();
final content = [
  Content.multi([
    TextPart('分析这张产品截图，提取关键功能点'),
    DataPart('image/png', imageBytes),
  ])
];

final response = await _model.generateContent(content);
```

### 3. Native Tool Use（原生工具调用）
可以让 Gemini 调用你定义的函数。

**示例：**
```dart
final model = GenerativeModel(
  model: 'gemini-2.0-flash-exp',
  apiKey: apiKey,
  tools: [
    Tool(functionDeclarations: [
      FunctionDeclaration(
        'searchKnowledgeBase',
        'Search the knowledge base for related content',
        Schema.object(properties: {
          'query': Schema.string(description: 'Search query'),
        }),
      ),
    ]),
  ],
);
```

---

## 八、成本估算

### Gemini 2.0 Flash 定价（截至 2026 年 1 月）

| 操作 | 免费额度 | 超出后价格 |
|------|---------|----------|
| 输入 (每百万 tokens) | 15 RPM | $0.075 |
| 输出 (每百万 tokens) | 15 RPM | $0.30 |

**示例计算：**
- 用户粘贴 500 字文本 → ~1000 tokens 输入
- AI 生成 3 个知识点，每个 300 字 → ~2000 tokens 输出
- **总计：** ~3000 tokens / 请求

**每月免费额度估算：**
- 15 RPM (requests per minute) * 60 分钟 = 900 请求/小时
- 足够支持 MVP 阶段的使用

---

## 九、迁移检查清单

在切换到 Gemini Developer API 之前，确保完成：

- [ ] 获取 Gemini API Key
- [ ] 更新 `pubspec.yaml`，移除 `firebase_vertexai`，添加 `google_generative_ai`
- [ ] 运行 `flutter pub get`
- [ ] 修改 `content_generator_service.dart`
- [ ] 更新 Provider 定义，传入 API Key
- [ ] 选择 API Key 管理策略（环境变量/用户提供/混合）
- [ ] 测试基本功能
- [ ] 添加错误处理（配额超限、Key 无效等）
- [ ] 更新文档

---

## 十、常见问题

### Q1: Gemini 2.0 Flash 和 1.5 Flash 有什么区别？
**A:** 2.0 Flash 更快、更智能，支持多模态输入，原生工具调用。

### Q2: API Key 会暴露在前端吗？
**A:** 是的，如果使用方案 A（环境变量），Key 会被编译到 JS 中。建议生产环境使用方案 B（用户提供）或搭建后端代理。

### Q3: 如何保护 API Key 不被滥用？
**A:** 
1. 限制每个用户的调用次数
2. 使用 Firebase Cloud Functions 作为代理
3. 让用户使用自己的 API Key

### Q4: 免费额度够用吗？
**A:** 对于 MVP 阶段绝对够用。如果用户量大，建议引导用户使用自己的 Key。

---

**文档维护者：** AI Assistant  
**需要帮助？** 访问 [Gemini API 官方文档](https://ai.google.dev/docs)
