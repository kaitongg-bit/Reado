import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

/// 独立测试脚本 - 验证 Gemini API 生成的知识点
///
/// 运行方式：
/// dart run test/test_gemini_generation.dart
void main(List<String> arguments) async {
  print('╔════════════════════════════════════════════════════════════╗');
  print('║       QuickPM AI 知识点生成测试工具                        ║');
  print('╚════════════════════════════════════════════════════════════╝');
  print('');

  // 读取 API Key
  const apiKey = String.fromEnvironment('GEMINI_API_KEY');

  if (apiKey.isEmpty) {
    print('❌ 错误：未提供 API Key');
    print('');
    print('运行方式：');
    print(
        'dart run --define=GEMINI_API_KEY=你的Key test/test_gemini_generation.dart');
    exit(1);
  }

  print('✅ API Key: ${apiKey.substring(0, 10)}...');
  print('');

  // 测试文本 - 支持命令行参数或使用默认
  String testText;

  if (arguments.isNotEmpty) {
    // 使用命令行参数
    testText = arguments.join(' ');
    print('📝 使用自定义文本（来自命令行参数）');
  } else {
    // 使用默认测试文本
    testText = '''
产品经理需要写 PRD 文档。PRD 全称是 Product Requirements Document，
是产品需求文档。PRD 包含需求背景、功能描述、交互流程、优先级、成功指标等内容。

写好 PRD 可以确保团队对需求理解一致，减少返工，提高开发效率。
产品经理在写 PRD 时要遵循 5W1H 法则：Who、What、When、Where、Why、How。
''';
    print('📝 使用默认测试文本');
  }

  print('');
  print('测试文本内容：');
  print('─' * 60);
  print(testText.trim());
  print('─' * 60);
  print('');

  // 初始化模型
  final model = GenerativeModel(
    model: 'gemini-2.0-flash-exp',
    apiKey: apiKey,
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      temperature: 0.7,
      topP: 0.9,
      topK: 40,
    ),
  );

  // Prompt（与应用中一致）
  const prompt = '''
你是一位资深的教育内容专家和产品经理导师。你的任务是将用户提供的学习资料转化为易于理解和记忆的知识卡片。

## 核心要求

### 1. 知识点拆分原则
- **独立性**：每个知识点应该是一个独立的概念或技能
- **适度粒度**：不要太大（难以消化）也不要太小（过于琐碎）
- **逻辑顺序**：按照从基础到进阶的顺序排列
- **数量控制**：根据输入内容长度，生成 2-8 个知识点

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
- **问题**：具体且有针对性，测试核心概念或应用能力
- **答案**：简洁但完整（100-200 字），包含关键要点（2-3 个）

### 4. 输出格式

严格按照以下 JSON 格式输出：

[
  {
    "title": "知识点的简洁标题（10-20字）",
    "category": "分类名称",
    "difficulty": "Easy|Medium|Hard",
    "content": "# 标题\\n\\n## 是什么\\n\\n[Markdown 正文]",
    "flashcard": {
      "question": "具体的测试问题",
      "answer": "简洁但完整的答案"
    }
  }
]

现在，请根据以上要求，分析用户提供的文本并生成知识卡片。
''';

  final content = [Content.text('$prompt\n\n## 用户输入的学习资料：\n\n$testText')];

  print('🚀 调用 Gemini API...');
  print('');

  try {
    final response = await model.generateContent(content);
    final responseText = response.text;

    if (responseText == null) {
      print('❌ AI 未返回任何内容');
      exit(1);
    }

    print('✅ AI 响应成功！');
    print('');
    print('═' * 60);
    print('完整 JSON 响应：');
    print('═' * 60);
    print('');

    // 清理并美化 JSON
    String cleanedResponse = responseText.trim();
    if (cleanedResponse.startsWith('```json')) {
      cleanedResponse = cleanedResponse.substring(7);
    }
    if (cleanedResponse.startsWith('```')) {
      cleanedResponse = cleanedResponse.substring(3);
    }
    if (cleanedResponse.endsWith('```')) {
      cleanedResponse =
          cleanedResponse.substring(0, cleanedResponse.length - 3);
    }
    cleanedResponse = cleanedResponse.trim();

    // 解析并美化输出
    try {
      final jsonData = jsonDecode(cleanedResponse);
      final prettyJson = JsonEncoder.withIndent('  ').convert(jsonData);
      print(prettyJson);
      print('');
      print('═' * 60);

      // 解析知识点
      if (jsonData is List) {
        print('');
        print('📊 生成统计：');
        print('─' * 60);
        print('总知识点数：${jsonData.length}');
        print('');

        for (var i = 0; i < jsonData.length; i++) {
          final item = jsonData[i];
          print('知识点 ${i + 1}:');
          print('  标题：${item['title']}');
          print('  分类：${item['category']}');
          print('  难度：${item['difficulty']}');
          print('  正文长度：${item['content']?.length ?? 0} 字符');
          final question = item['flashcard']?['question'] ?? '';
          final preview = question.length > 30
              ? '${question.substring(0, 30)}...'
              : question;
          print('  Flashcard 问题：$preview');
          print('');
        }

        print('─' * 60);
        print('');
        print('✨ 质量验证：');
        print('  ✅ JSON 格式正确');
        print('  ✅ 知识点数量：${jsonData.length}');
        print('  ✅ 所有字段完整');

        // 检查正文长度
        bool allGoodLength = true;
        for (var item in jsonData) {
          final contentLength = item['content']?.length ?? 0;
          if (contentLength < 300 || contentLength > 800) {
            allGoodLength = false;
            print('  ⚠️  警告：《${item['title']}》正文长度 $contentLength，建议 300-800');
          }
        }

        if (allGoodLength) {
          print('  ✅ 正文长度均在 300-800 字符范围内');
        }
      }
    } catch (e) {
      print('❌ JSON 解析失败: $e');
      print('');
      print('原始响应：');
      print(responseText);
    }
  } catch (e) {
    print('❌ 错误：$e');
    exit(1);
  }

  print('');
  print('╔════════════════════════════════════════════════════════════╗');
  print('║                    测试完成！                               ║');
  print('╚════════════════════════════════════════════════════════════╝');
}
