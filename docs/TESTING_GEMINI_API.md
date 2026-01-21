# Gemini API 切换完成 - 测试指南

**更新时间：** 2026-01-20  
**状态：** ✅ 已完成切换到 Gemini 2.0 Flash Developer API

---

## ✅ 完成的工作

### 1. 代码更新
- ✅ 切换到 `google_generative_ai` SDK (v0.4.6)
- ✅ 移除了 `firebase_vertexai` 依赖
- ✅ 更新了 `ContentGeneratorService`
- ✅ 优化了 AI Prompt，确保高质量输出
- ✅ 添加了完善的错误处理
- ✅ 创建了 `ApiConfig` 配置文件

### 2. Prompt 优化重点

新的 Prompt 确保：
✅ **知识点拆分合理**：2-8 个独立知识点，按逻辑顺序排列  
✅ **正文通俗易懂**：300-800 字，5-15 分钟阅读时长  
✅ **使用类比和例子**：避免生硬的术语堆砌  
✅ **结构化内容**："是什么 → 为什么 → 怎么做"  
✅ **Flashcard 质量高**：
  - 问题具体且有针对性
  - 答案简洁但完整（100-200字）
  - 包含实际例子

**Prompt 示例要求：**
```
✅ 好问题："为什么产品经理需要区分真需求和伪需求？请举例说明。"
✅ 好问题："用 STAR 法则描述一个项目时，应该包含哪四个要素？"

❌ 差问题："产品经理是什么？"（太宽泛）
❌ 差问题："PRD 的英文全称是什么？"（太简单）
```

---

## 🚀 如何运行应用

### 方式 1：使用环境变量（推荐开发阶段）

1. **获取 Gemini API Key**
   - 访问：https://aistudio.google.com/app/apikey
   - 创建 API Key，例如：`AIzaSyC_xxxxxxxxxxxxxxxxxxxxxxxxxxx`

2. **运行应用**
   ```bash
   # Web
   flutter run -d web-server --web-port 3000 \
     --dart-define=GEMINI_API_KEY=AIzaSyC_YOUR_KEY_HERE

   # 桌面（macOS）
   flutter run -d macos \
     --dart-define=GEMINI_API_KEY=AIzaSyC_YOUR_KEY_HERE

   # 移动端
   flutter run -d chrome \
     --dart-define=GEMINI_API_KEY=AIzaSyC_YOUR_KEY_HERE
   ```

### 方式 2：设置环境变量文件

1. 创建 `.env` 文件（不要提交到 Git）
   ```bash
   echo "GEMINI_API_KEY=AIzaSyC_YOUR_KEY_HERE" > .env
   ```

2. 添加到 `.gitignore`
   ```bash
   echo ".env" >> .gitignore
   ```

3. 使用脚本运行
   ```bash
   # 创建运行脚本
   echo '#!/bin/bash\nsource .env\nflutter run -d web-server --web-port 3000 --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY' > run.sh
   chmod +x run.sh
   
   # 运行
   ./run.sh
   ```

---

## 🧪 测试 AI 功能

### 测试用例 1：基础产品管理知识

**输入文本：**
```
产品经理需要写 PRD 文档。PRD 全称是 Product Requirements Document，
是产品需求文档。PRD 包含需求背景、功能描述、交互流程、优先级、成功指标等内容。

写好 PRD 可以确保团队对需求理解一致，减少返工，提高开发效率。
```

**预期输出：**
- 生成 1-2 个知识点
- 每个知识点有清晰的标题、分类、难度
- 正文包含"是什么、为什么、怎么做"的结构
- Flashcard 问题具体，答案完整

**检查要点：**
- [ ] 正文长度在 300-800 字
- [ ] 使用了类比或例子
- [ ] Flashcard 问题不是 YES/NO 题
- [ ] Flashcard 答案包含 2-3 个要点

---

### 测试用例 2：复杂长文本

**输入文本（从文章或笔记复制）：**
```
敏捷开发是一种迭代式的软件开发方法。与传统的瀑布模型不同，
敏捷开发强调快速迭代、持续交付、客户协作。

Scrum 是最流行的敏捷框架之一，包含三个角色：
Product Owner、Scrum Master、开发团队。

每个 Sprint 通常是 2-4 周，包含以下环节：
Sprint Planning、Daily Standup、Sprint Review、Sprint Retrospective。

敏捷开发的优势在于能快速响应变化，但也需要团队有高度的自组织能力。
```

**预期输出：**
- 生成 2-4 个知识点
- 拆分合理，例如：
  1. 敏捷开发基础概念
  2. Scrum 框架详解
  3. Sprint 工作流程
- 每个知识点独立可读

**检查要点：**
- [ ] 知识点数量合理（2-4 个）
- [ ] 难度评级准确
- [ ] 没有重复内容
- [ ] 每个 Flashcard 针对特定概念

---

### 测试用例 3：错误处理

**场景 1：API Key 未配置**
- 不使用 `--dart-define` 运行
- 预期：显示友好的错误提示，引导用户配置 API Key

**场景 2：输入文本过短**
```
产品经理
```
- 预期：AI 可能无法生成足够的知识点，应有错误提示

**场景 3：输入敏感内容**
- 输入包含敏感词的文本
- 预期：被安全过滤器拦截，显示提示

---

## 📊 Prompt 效果验证

### 验证标准

按照以下标准评估生成的知识点质量：

| 维度 | 标准 | 如何检查 |
|------|------|---------|
| **阅读时长** | 5-15 分钟（300-800字） | 数正文字数 |
| **通俗程度** | 非专业人士也能理解 | 找一个不懂的人阅读 |
| **结构化** | 有标题、小标题、列表 | 检查 Markdown 格式 |
| **例子/类比** | 至少包括 1 个实际例子 | 全文搜索"例如"、"比如" |
| **Flashcard Q** | 具体、可口述回答 | 尝试口头回答，看是否需要30秒-1分钟 |
| **Flashcard A** | 100-200字，包含要点 | 数字数，检查是否有 2-3 个要点 |

### 如果质量不佳

如果生成的内容不符合预期，可能的原因：

1. **输入文本质量差**
   - 解决：要求用户提供更完整、结构化的内容
   
2. **Prompt 需要调整**
   - 查看：`lib/core/services/content_generator_service.dart` 第 35 行
   - 可以根据实际效果微调

3. **API 模型限制**
   - Gemini 2.0 Flash 已经是最新最智能的模型
   - 如果还不够，可以考虑升级到 Gemini Pro（但成本更高）

---

## 🐛 常见问题排查

### Q1: 运行时提示 "Gemini API Key 未配置"

**原因：** 未传入 `--dart-define=GEMINI_API_KEY`

**解决：**
```bash
flutter run -d web-server --web-port 3000 \
  --dart-define=GEMINI_API_KEY=你的Key
```

---

### Q2: API 返回 403 错误

**可能原因：**
1. API Key 无效
2. API Key 配额用完
3. API Key 被禁用

**检查方法：**
1. 访问 https://aistudio.google.com/app/apikey
2. 查看 Key 状态和配额

**解决方案：**
- 如果 Key 无效：重新生成
- 如果配额用完：等待重置或升级

---

### Q3: 生成的内容是空的

**原因：** 输入文本太短或无意义

**解决：** 确保输入至少 100 字以上的有意义内容

---

### Q4: JSON 解析失败

**原因：** AI 返回的格式不符合预期

**已处理：** 代码中已添加了清理逻辑（去除 ``` 标记）

**如果仍然失败：** 查看控制台日志，检查 AI 的原始响应

---

## 📈 下一步优化建议

### 短期（本周）

1. **测试不同类型的输入**
   - 产品管理知识
   - 技术文章
   - 面试经验

2. **收集用户反馈**
   - 内容质量如何？
   - 拆分是否合理？
   - Flashcard 是否有用？

### 中期（下周）

3. **根据反馈微调 Prompt**
   - 调整知识点拆分逻辑
   - 优化 Flashcard 设计
   - 添加更多示例

4. **实现数据持久化**
   - 将生成的知识点保存到 Firestore
   - 参考：`docs/DATA_STORAGE_ARCHITECTURE.md`

### 长期（下个月）

5. **添加用户提供 API Key 功能**
   - 在个人中心添加 API Key 输入
   - 从 Firestore 读取用户的 Key
   - 参考：`docs/GEMINI_API_MIGRATION.md` 第五章

6. **API 调用优化**
   - 限制每个用户的调用次数
   - 缓存常见问题的结果
   - 添加重试机制

---

## 📞 需要帮助？

- 📖 **文档中心**：`docs/README.md`
- 🤖 **API 指南**：`docs/GEMINI_API_MIGRATION.md`
- 💾 **数据架构**：`docs/DATA_STORAGE_ARCHITECTURE.md`
- 🔍 **快速参考**：`docs/QUICK_REFERENCE.md`

---

**祝测试顺利！🚀**
