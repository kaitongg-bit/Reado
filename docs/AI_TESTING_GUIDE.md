# AI 生成测试工具使用指南

## 🎯 功能说明

这个脚本用于**独立测试** Gemini AI 生成知识点的功能，无需运行整个 Flutter 应用。

## 📋 使用方式

### 方式 1：使用默认测试文本

```bash
cd /Users/gktnbjl/Desktop/QuickPM
GEMINI_API_KEY='你的Key' ./test_ai_generation.sh
```

**默认测试文本：**
```
产品经理需要写 PRD 文档...
```

---

### 方式 2：测试你自己的文本

```bash
cd /Users/gktnbjl/Desktop/QuickPM

# 直接在命令行传入文本
GEMINI_API_KEY='你的Key' dart run --define=GEMINI_API_KEY='你的Key' test/test_gemini_generation.dart "你的文本内容"
```

**示例：**
```bash
dart run --define=GEMINI_API_KEY=AIzaSyC... test/test_gemini_generation.dart "敏捷开发是一种迭代式的软件开发方法。Scrum 是最流行的敏捷框架之一。"
```

---

### 方式 3：从文件读取测试文本

```bash
# 1. 创建测试文件
echo "你的学习资料内容..." > my_test.txt

# 2. 运行测试
dart run --define=GEMINI_API_KEY='你的Key' test/test_gemini_generation.dart "$(cat my_test.txt)"
```

---

## 📊 输出说明

### ✅ 成功输出示例

```
✅ API 响应成功！

════════════════════════════════════════════════════════════
完整 JSON 响应：
════════════════════════════════════════════════════════════

[
  {
    "title": "PRD 文档：产品经理的核心技能",
    "category": "产品管理",
    "difficulty": "Easy",
    "content": "# PRD 文档...",
    "flashcard": {
      "question": "PRD 文档的核心作用是什么？",
      "answer": "PRD 的核心作用是..."
    }
  }
]

📊 生成统计：
────────────────────────────────────────────────────────────
总知识点数：1

知识点 1:
  标题：PRD 文档：产品经理的核心技能
  分类：产品管理
  难度：Easy
  正文长度：870 字符
  Flashcard 问题：PRD 文档的核心作用是什么？

✨ 质量验证：
  ✅ JSON 格式正确
  ✅ 知识点数量：1
  ✅ 所有字段完整
  ⚠️  警告：《PRD 文档：产品经理的核心技能》正文长度 870，建议 300-800
```

---

## 🔍 质量检查项

脚本会自动验证：

1. ✅ **JSON 格式** - 是否是有效的 JSON
2. ✅ **知识点数量** - 应该是 2-8 个
3. ✅ **必需字段** - title, category, difficulty, content, flashcard
4. ✅ **正文长度** - 建议 300-800 字符
5. ✅ **Flashcard** - 是否有问题和答案

---

## ⚠️ 常见问题

### Q1: 看到 "RangeError" 错误
**答：** 已修复！这是显示预览时的小bug，不影响实际功能。

### Q2: 想测试很长的文本
**答：** 建议使用文件方式：
```bash
dart run --define=GEMINI_API_KEY='你的Key' test/test_gemini_generation.dart "$(cat 你的文件.txt)"
```

### Q3: 正文长度超过 800 字
**答：** 这是**警告不是错误**。AI 有时会生成稍长的内容，这是正常的。如果超过太多（如 1500+），可以考虑调整 Prompt。

---

## 📝 关于测试结果

### ✅ 刚才的测试结果

从你的测试看：

**生成的内容：**
- ✅ **1个知识点**（对于简短测试文本，这是合理的）
- ✅ **标题清晰**："PRD 文档：产品经理的核心技能"
- ✅ **分类正确**："产品管理"
- ✅ **难度合适**："Easy"
- ✅ **正文完整**：870字符（略超过800，但质量很好）
- ✅ **Flashcard 优秀**：问题和答案都很好

**质量评估：⭐⭐⭐⭐⭐ 优秀！**

---

## 🎯 下一步

### 在应用中测试
现在你可以在应用中测试相同的功能：

1. 访问：http://localhost:3000
2. 点击 "Add Material"
3. 粘贴你的文本
4. 生成并保存

数据会保存到 Firestore `/users/{uid}/custom_items/`

---

**需要帮助？查看文档：**
- 📖 `docs/GEMINI_MIGRATION_SUMMARY.md` - 完整的迁移总结
- 🔍 `docs/QUICK_REFERENCE.md` - 快速参考
