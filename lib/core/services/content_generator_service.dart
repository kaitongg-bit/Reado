import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import '../../models/feed_item.dart';
import 'proxy_http_client.dart';
import '../prompts/app_prompts.dart';

class ContentGeneratorService {
  late final GenerativeModel _jsonModel;
  late final GenerativeModel _textModel;

  ContentGeneratorService({required String apiKey, String? baseUrl}) {
    final client = baseUrl != null ? ProxyHttpClient(baseUrl) : null;

    // Model 1: For structured data generation (JSON)
    _jsonModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      httpClient: client,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.7,
        topP: 0.9,
        topK: 40,
      ),
    );

    // Model 2: For natural conversation/text (Standard)
    _textModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      httpClient: client,
      generationConfig: GenerationConfig(
        // No specific mimeType -> defaults to text/plain
        temperature: 0.7,
        topP: 0.9,
        topK: 40,
      ),
    );
  }

  /// 从用户提供的文本生成知识卡片
  Future<List<FeedItem>> generateFromText(String text, {String outputLocale = 'zh'}) async {
    final langInstr = languageInstruction(outputLocale);
    final prompt = '''
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
- **格式化**：使用 Markdown 格式，包含：
  - 清晰的标题和小标题（## ### ####）
  - 要点列表（- 或 1. 2. 3.）
  - **加粗**重点概念
  - `代码块` 或专业术语
  - > 引用 来强调关键观点

### 3. Flashcard 设计原则
每个知识点的 flashcard 必须：
- **问题**：
  - 具体且有针对性
  - 测试核心概念或应用能力
  - 不要太简单（是/否题），也不要太难（需要完整论述）
  - 适合口头快速回答（30秒-1分钟）
  - 示例好问题：
    ✅ "为什么产品经理需要区分真需求和伪需求？请举例说明。"
    ✅ "用 STAR 法则描述一个项目时，应该包含哪四个要素？"
    ❌ "产品经理是什么？"（太宽泛）
    ❌ "PRD 的英文全称是什么？"（太简单）
- **答案**：
  - 简洁但完整（100-200 字）
  - 包含关键要点（2-3 个）
  - 如果可能，加上一个简短例子
  - 结构清晰，易于记忆

### 4. 难度评级标准
- **Easy**：基础概念、定义、常识性内容
- **Medium**：需要理解和简单应用的知识
- **Hard**：需要深度理解、综合分析或实践经验

### 5. 分类建议
- 如果是产品管理相关：使用 "产品设计"、"需求分析"、"数据分析"、"用户研究" 等
- 如果是技术相关：使用 "编程基础"、"算法"、"系统设计" 等
- 如果不确定：使用 "通识" 或从内容中提取主题

### 6. 语言
- $langInstr

## 输出格式

严格按照以下 JSON 格式输出（必须是有效的 JSON，不要有多余的文字）：

[
  {
    "title": "知识点的简洁标题（10-20字）",
    "category": "分类名称",
    "difficulty": "Easy|Medium|Hard",
    "content": "# 标题\\n\\n## 是什么\\n\\n[300-800字的 Markdown 正文，通俗易懂，包含例子]\\n\\n## 为什么重要\\n\\n[说明意义]\\n\\n## 怎么应用\\n\\n[实际使用方法]",
    "flashcard": {
      "question": "具体的测试问题（针对核心概念）",
      "answer": "简洁但完整的答案（100-200字，包含要点和例子）"
    }
  }
]

现在，请根据以上要求，分析用户提供的文本并生成知识卡片。
''';

    final content = [Content.text('$prompt\n\n## 用户输入的学习资料：\n\n$text')];

    try {
      debugPrint('🚀 调用 Gemini 2.0 Flash API (JSON Mode)...');
      debugPrint('📝 输入文本长度: ${text.length} 字符');

      final response = await _jsonModel.generateContent(content);
      // ... (Rest of logic is same, using response.text) ...
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        throw Exception('AI 未返回任何内容，请重试');
      }

      debugPrint('✅ AI 响应成功');
      // ...

      // 解析 JSON
      List<dynamic> jsonList;
      try {
        // 尝试清理可能的 markdown 代码块标记
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

        jsonList = jsonDecode(cleanedResponse);
      } catch (e) {
        debugPrint('❌ JSON 解析失败: $e');
        debugPrint('原始响应: $responseText');
        throw Exception('AI 返回的格式不正确，请重试');
      }

      if (jsonList.isEmpty) {
        throw Exception('AI 没有生成任何知识点，请尝试提供更多内容');
      }

      debugPrint('✨ 成功生成 ${jsonList.length} 个知识点');

      // 转换为 FeedItem
      final items = jsonList
          .asMap()
          .entries
          .map((entry) {
            final index = entry.key;
            final json = entry.value;

            // 验证必需字段
            if (json['title'] == null || json['content'] == null) {
              debugPrint('⚠️ 知识点 #$index 缺少必需字段，跳过');
              return null;
            }

            final item = FeedItem(
              id: '${DateTime.now().millisecondsSinceEpoch}_${index}_${json['title'].hashCode.abs()}',
              moduleId: 'B', // 默认为产品管理模块
              title: json['title'],
              category: json['category'] ?? '通识',
              difficulty: json['difficulty'] ?? 'Medium',
              masteryLevel: FeedItemMastery.unknown,
              pages: [
                OfficialPage(
                  json['content'] ?? '',
                  flashcardQuestion: json['flashcard']?['question'],
                  flashcardAnswer: json['flashcard']?['answer'],
                ),
              ],
            );

            debugPrint('  - ${item.title} (${item.difficulty})');
            return item;
          })
          .whereType<FeedItem>()
          .toList();

      if (items.isEmpty) {
        throw Exception('未能成功生成有效的知识点，请检查输入内容');
      }

      return items;
    } on GenerativeAIException catch (e) {
      debugPrint('❌ Gemini API 错误: ${e.message}');

      // 详细的错误处理
      if (e.message.contains('API_KEY_INVALID') ||
          e.message.contains('invalid api key')) {
        throw Exception('API Key 无效\n请检查你的 Gemini API Key');
      } else if (e.message.contains('quota') ||
          e.message.contains('RESOURCE_EXHAUSTED')) {
        throw Exception('API 调用次数已达上限\n请稍后再试，或升级配额');
      } else if (e.message.contains('SAFETY')) {
        throw Exception('内容被安全过滤器拦截\n请修改输入文本');
      } else {
        throw Exception('AI 服务暂时不可用\n错误: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ 未知错误: $e');
      rethrow;
    }
  }

  /// 与卡片内容进行对话（一次性返回，兼容旧逻辑）
  Future<String> chatWithContent(
      String contextContent, List<Map<String, String>> history) async {
    final buffer = StringBuffer();
    await for (final chunk
        in chatWithContentStream(contextContent, history)) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }

  /// 与卡片内容进行对话（流式返回，用于打字机效果）
  Stream<String> chatWithContentStream(
      String contextContent, List<Map<String, String>> history) async* {
    final historyText = history.map((msg) {
      final role = msg['role'] == 'user' ? '用户' : 'AI Mentor';
      return '$role: ${msg['content']}';
    }).join('\n');

    final lastUserMessage = history.lastWhere(
        (element) => element['role'] == 'user',
        orElse: () => {'content': ''})['content'];

    if (lastUserMessage!.isEmpty) return;

    final prompt = '''
你是一位资深的教育导师。用户正在学习以下内容。你需要基于这些内容回答用户的问题。
背景内容：
"""
$contextContent
"""

以下是对话记录：
$historyText

请回答用户最新的问题（"$lastUserMessage"）。
要求：
1. **直接回答**：不要使用 JSON 格式，直接输出纯文本（Markdown）。
2. **结合上下文**：解答必须基于背景内容，保持准确。
3. **通俗易懂**：用简洁、鼓励性的语言。
4. **追问**：在回答结束时，必须提出一个相关的、能引发思考的追问，引导用户更深一层。

请直接输出回答内容。
''';

    final content = [Content.text(prompt)];

    try {
      final stream = _textModel.generateContentStream(content);
      await for (final response in stream) {
        final text = response.text;
        if (text != null && text.isNotEmpty) yield text;
      }
    } catch (e) {
      debugPrint('❌ Chat API Error: $e');
      throw Exception('无法连接 AI Mentor');
    }
  }

  /// 整理并 Pin 笔记
  Future<String> summarizeForPin(
      String contextContent, String selectedChatContent) async {
    final prompt = '''
你是一个智能笔记助手。用户的目标是将一段有价值的对话整理成精炼的知识点笔记。
背景内容（参考用）：
"""
$contextContent
"""

重点对话内容（需整理）：
"""
$selectedChatContent
"""

任务：
请仅基于"重点对话内容"中的信息，整理出一个结构化的知识点。背景内容仅用于帮助你理解上下文，不要大量重复背景内容。
要求：
1. **提炼核心**：归纳对话中 AI 解释的核心观点或方法论（干货）。
2. **脱水处理**：去除寒暄、废话和过于显而易见的信息。
3. **格式清晰**：
   - Q: 一个能概括这段对话核心议题的问题（简短有力）。
   - A: 经过整理的回答。使用 Markdown 列表或加粗来突出重点。
4. **直接输出**：不要使用 JSON，直接输出问答对。不要输出 "\n" 字符本身，而是使用真正的换行。

输出示例：
Q: [核心问题]
A: [整理后的核心回答]
''';

    final content = [Content.text(prompt)];

    try {
      final response = await _textModel.generateContent(content);
      return response.text ?? '整理失败，请重试。';
    } catch (e) {
      debugPrint('❌ Summarize API Error: $e');
      throw Exception('整理笔记失败');
    }
  }
}
