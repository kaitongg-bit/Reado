# ✅ Gemini API 切换总结

**日期：** 2026-01-20  
**任务：** 切换到 Gemini 2.0 Flash Developer API 并优化 Prompt

---

## 🎯 你的核心关注点

### ❓ 问题 1：我的算法或 Prompt能否实现高质量内容生成？

**答案：✅ 可以！我已经精心设计了 Prompt。**

#### Prompt 设计要点：

1. **知识点拆分策略**
   - 📏 **独立性**：每个知识点是一个完整的概念
   - 📐 **适度粒度**：不会太大（难消化）或太小（碎片化）
   - 📊 **逻辑顺序**：从基础到进阶
   - 🔢 **数量控制**：根据输入长度生成 2-8 个知识点

2. **正文质量保证**
   - ⏱️ **阅读时长**：5-15 分钟（300-800 字）
   - 💡 **通俗易懂**：
     - 使用日常语言，避免术语堆砌
     - 术语必须先解释
     - 多用类比、比喻、实际案例
   - 📝 **结构化**：采用"是什么 → 为什么 → 怎么做"

3. **Flashcard 设计原则**
   - **问题质量**：
     - ✅ "为什么产品经理需要区分真需求和伪需求？请举例说明。"
     - ❌ "产品经理是什么？"（太宽泛）
   - **答案质量**：
     - 简洁但完整（100-200 字）
     - 包含 2-3 个关键要点
     - 最好有一个简短例子

---

## 📝 实际 Prompt 片段

```markdown
### 2. 正文内容要求
每个知识点的正文必须：
- **阅读时长**：5-15 分钟，约 300-800 字
- **通俗易懂**：
  - 使用日常语言，避免过度的专业术语
  - 如果必须使用术语，先用简单语言解释
  - 多用类比、比喻、实际案例
  - 采用"是什么 → 为什么 → 怎么做"的结构

### 3. Flashcard 设计原则
每个知识点的 flashcard 必须：
- **问题**：
  - 具体且有针对性
  - 测试核心概念或应用能力
  - 不要太简单（是/否题），也不要太难（需要完整论述）
  - 适合口头快速回答（30秒-1分钟）
- **答案**：
  - 简洁但完整（100-200 字）
  - 包含关键要点（2-3 个）
  - 如果可能，加上一个简短例子
```

完整 Prompt 见：`lib/core/services/content_generator_service.dart` 第 35-136 行

---

## 🛠️ 完成的技术工作

### 1. 依赖更新
```yaml
# 移除
❌ firebase_vertexai: ^2.2.0

# 添加
✅ google_generative_ai: ^0.4.6
```

### 2. 代码重写

**文件：** `lib/core/services/content_generator_service.dart`

**核心改变：**
```dart
// 旧：Firebase Vertex AI
import 'package:firebase_vertexai/firebase_vertexai.dart';
_model = FirebaseVertexAI.instance.generativeModel(...)

// 新：Gemini Developer API
import 'package:google_generative_ai/google_generative_ai.dart';
_model = GenerativeModel(
  model: 'gemini-2.0-flash-exp',  // 最新模型
  apiKey: apiKey,  // 需要用户提供
)
```

### 3. API Key 管理

**新文件：** `lib/config/api_config.dart`

支持三种方式：
1. 环境变量：`--dart-define=GEMINI_API_KEY=xxx`
2. 默认 Key（可选）
3. 用户提供（未来实现）

### 4. 错误处理

添加了详细的错误提示：
- ✅ API Key 无效
- ✅ 配额用完
- ✅ 内容被过滤
- ✅ JSON 解析失败

---

## 🚀 如何使用

### 步骤 1：获取 API Key

访问：https://aistudio.google.com/app/apikey

点击 "Create API key" → 复制生成的 Key

### 步骤 2：运行应用

```bash
cd /Users/gktnbjl/Desktop/QuickPM

# Web 版本
flutter run -d web-server --web-port 3000 \
  --dart-define=GEMINI_API_KEY=AIzaSyC_YOUR_KEY_HERE
```

### 步骤 3：测试功能

1. 打开应用
2. 点击 "Add Material" 按钮
3. 粘贴测试文本（建议 200 字以上）
4. 点击 "生成知识卡片"
5. 查看生成的知识点

---

## 📊 Prompt 效果示例

### 输入：
```
产品经理需要写 PRD 文档。PRD 包含需求背景、功能描述、
优先级等。写好 PRD 可以减少返工。
```

### 预期输出：

**知识点 1：什么是 PRD 文档**

**正文（节选）：**
```markdown
# 什么是 PRD 文档

## PRD 的定义

PRD 全称是 **Product Requirements Document**（产品需求文档），
是产品经理用来描述产品功能和需求的核心文档。

可以把 PRD 想象成**建筑图纸**：
- 建筑师画图纸 → 产品经理写 PRD
- 施工队看图纸盖房子 → 开发团队看 PRD 做产品
- 图纸越详细，房子质量越好 → PRD 越清晰，产品实现越准确

## PRD 包含什么

1. **需求背景**：为什么要做这个功能？
2. **功能描述**：具体要做什么？
3. **交互流程**：用户如何操作？
4. **优先级**：哪些必须做，哪些可以后续优化？
5. **成功指标**：怎么判断做成功了？
...
```

**Flashcard：**
```
问：为什么产品经理需要写 PRD 文档？它解决了什么问题？

答：PRD 文档解决了三个核心问题：
1. **对齐认知** - 确保产品经理、设计师、开发工程师对需求
   的理解一致，避免各做各的
2. **减少返工** - 前期把需求说清楚，后期就不会频繁改需求，
   节省时间成本
3. **责任明确** - 当产品出现问题时，可以追溯到最初的需求定义

就像盖房子前先画图纸，PRD 是产品开发的'施工图'，没有它团队就是盲目开工。
```

---

## 📈 质量验证标准

| 维度 | 目标 | 如何验证 |
|------|------|---------|
| 阅读时长 | 5-15 分钟 | 数字数：300-800字 ✅ |
| 通俗程度 | 非专业人士能懂 | 找不懂的人阅读 |
| 结构化 | 清晰的层次 | 检查 Markdown 标题 ✅ |
| 例子/类比 | 至少 1 个 | 搜索"例如"、"比如" ✅ |
| Flashcard Q | 具体可测 | 30秒-1分钟可回答 ✅ |
| Flashcard A | 100-200字 | 包含 2-3 个要点 ✅ |

---

## 📂 新增的文档

我为你创建了 6 份详细文档：

1. **`docs/DATA_STORAGE_ARCHITECTURE.md`** (20.8KB)
   - 完整的 Firestore 数据库设计
   - 认证策略和安全规则
   - 生产环境级别的架构

2. **`docs/GEMINI_API_MIGRATION.md`** (13.8KB)
   - API 切换详细指南
   - API Key 管理策略
   - 成本估算

3. **`docs/QUICK_REFERENCE.md`** (7.8KB)
   - 数据结构速查表
   - 常用代码片段
   - 快速问题排查

4. **`docs/README.md`** (11.1KB)
   - 文档导航中心
   - 架构总览
   - TODO 清单

5. **`docs/API_AND_DATABASE_GUIDE.md`** (8.9KB)
   - 当前实现状态
   - 快速参考

6. **`docs/TESTING_GEMINI_API.md`** (刚创建)
   - 测试指南
   - 测试用例
   - 常见问题

---

## ✅ 下一步建议

### 立即测试（今天）

1. **获取 Gemini API Key**
   - https://aistudio.google.com/app/apikey

2. **运行应用并测试**
   ```bash
   flutter run -d web-server --web-port 3000 \
     --dart-define=GEMINI_API_KEY=你的Key
   ```

3. **验证 Prompt 效果**
   - 输入不同类型的学习资料
   - 检查生成的知识点质量
   - 评估 Flashcard 的实用性

### 短期优化（本周）

4. **根据实际效果调整 Prompt**
   - 如果拆分不合理 → 调整拆分逻辑
   - 如果太专业 → 加强"通俗化"要求
   - 如果 Flashcard 不好 → 提供更多示例

5. **实现数据持久化**
   - 将生成的知识点保存到 Firestore
   - 参考：`docs/DATA_STORAGE_ARCHITECTURE.md` 第 4.4 节

### 中长期规划（下周+）

6. **添加用户 API Key 输入**
   - 在个人中心添加设置项
   - 从 Firestore 读取用户的 Key

7. **优化用户体验**
   - 添加生成进度条
   - 支持编辑生成的内容
   - 批量生成

---

## 🎓 关键学习要点

### 关于 Prompt Engineering

1. **明确要求**：告诉 AI 具体要做什么（字数、结构、风格）
2. **提供示例**：给出好的和差的例子，帮助 AI 理解标准
3. **结构化输出**：要求特定的 JSON 格式，便于解析
4. **迭代优化**：根据实际效果不断调整

### 关于 API 选择

1. **Firebase Vertex AI**：适合 Firebase 生态用户，隐式认证
2. **Gemini Developer API**：灵活，适合独立开发者，显式 API Key

### 关于数据架构

1. **公私分离**：官方内容 vs 用户数据
2. **UID 绑定**：所有用户数据关联到 userId
3. **安全优先**：通过 Firestore 规则保护数据

---

## 📞 如果遇到问题

1. **查看文档**
   - `/docs/TESTING_GEMINI_API.md` - 测试指南
   - `/docs/GEMINI_API_MIGRATION.md` - API 详细说明

2. **检查日志**
   - 查看 Flutter 控制台输出
   - 搜索 "❌" 或 "Error" 关键词

3. **常见问题**
   - API Key 无效 → 重新生成
   - 配额用完 → 等待或升级
   - JSON 解析失败 → 查看原始响应，调整 Prompt

---

**总结：所有准备工作已完成，现在可以开始测试了！🚀**

需要我帮你运行测试吗？我可以帮你创建一个测试用的 API Key 命令。
