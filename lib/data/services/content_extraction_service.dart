import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';
import '../../models/feed_item.dart';
import '../../config/api_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../core/services/proxy_http_client.dart';
import '../../core/providers/ai_settings_provider.dart';

/// 内容来源类型
enum SourceType {
  url,
  text,
  youtube,
  pdf,
}

/// 内容提取结果
class ExtractionResult {
  final String title;
  final String content;
  final String? sourceUrl;
  final SourceType sourceType;

  ExtractionResult({
    required this.title,
    required this.content,
    this.sourceUrl,
    required this.sourceType,
  });
}

/// 流式生成事件类型
enum StreamingEventType {
  status, // 状态更新（文字提示）
  outline, // 大纲已生成（知道总数了）
  card, // 一张卡片生成完成
  complete, // 全部完成
  error, // 出错
}

/// 流式生成事件
class StreamingGenerationEvent {
  final StreamingEventType type;
  final String? statusMessage;
  final int? totalCards;
  final int? currentIndex;
  final FeedItem? card;
  final String? error;

  StreamingGenerationEvent._({
    required this.type,
    this.statusMessage,
    this.totalCards,
    this.currentIndex,
    this.card,
    this.error,
  });

  factory StreamingGenerationEvent.status(String message) {
    return StreamingGenerationEvent._(
      type: StreamingEventType.status,
      statusMessage: message,
    );
  }

  factory StreamingGenerationEvent.outline(int total) {
    return StreamingGenerationEvent._(
      type: StreamingEventType.outline,
      totalCards: total,
    );
  }

  factory StreamingGenerationEvent.card(FeedItem item, int index, int total) {
    return StreamingGenerationEvent._(
      type: StreamingEventType.card,
      card: item,
      currentIndex: index,
      totalCards: total,
    );
  }

  factory StreamingGenerationEvent.complete() {
    return StreamingGenerationEvent._(type: StreamingEventType.complete);
  }

  factory StreamingGenerationEvent.error(String message) {
    return StreamingGenerationEvent._(
      type: StreamingEventType.error,
      error: message,
    );
  }
}

/// 内容提取服务
class ContentExtractionService {
  /// 根据字符数计算所需的积分逻辑
  /// 梯度：
  /// 0 - 5k: 10（基础分析费）
  /// 5k - 15k: 20（中度分析费）
  /// 15k+: 每多 15k 字增加 20 积分（因为需要多出一个块分段处理）
  static int calculateRequiredCredits(int charCount) {
    if (charCount <= 5000) return 10;
    if (charCount <= 15000) return 20;

    // 超过 15k 开启分段计算
    final int baseLimit = 15000;
    final int chunkCount = (charCount / baseLimit).ceil();
    return chunkCount * 20;
  }

  /// 从 URL 提取内容
  ///
  /// 优先级：
  /// 1. YouTube 链接 → 提取字幕 + 描述
  /// 2. 小红书链接 → 提示或尝试 API
  /// 3. 普通链接 → Jina Reader AI
  static Future<ExtractionResult> extractFromUrl(String url) async {
    // 1. YouTube 特殊处理
    if (_isYoutubeUrl(url)) {
      // Web 端 MVP 策略:
      // 由于浏览器的 CORS 安全限制，无法在 Web 端使用 youtube_explode 进行本地提取。
      // 因此，Web 端自动回退使用 Jina Reader (服务端代理)，它通常也能很好地处理 YouTube。
      if (kIsWeb) {
        if (kDebugMode) {
          print(
              '🌐 Web Environment detected: Skipping local YouTube extraction due to CORS.');
          print('👉 Falling back to Jina Reader (Server-side proxy).');
        }
        // 不执行 return，继续向下执行，自然会进入默认的 _extractWithJinaReader 逻辑
      } else {
        if (kDebugMode) print('🎥 Detected YouTube URL: $url');
        return _extractFromYoutube(url);
      }
    }

    try {
      if (kDebugMode) print('📥 Extracting content from URL: $url');

      // 检测常见的需要特殊处理的平台
      // ... (existing logic for other platforms)

      final needsSpecialHandling = _checkIfNeedsSpecialHandling(url);
      if (needsSpecialHandling != null) {
        if (kDebugMode) {
          print('⚠️ Detected platform: $needsSpecialHandling');
          print('💡 建议：如需更好支持，可部署独立的内容提取后端服务');
        }
      }

      // Jina Reader API - 将任意网页转换为 Markdown
      // 文档: https://jina.ai/reader
      final jinaUrl = 'https://r.jina.ai/$url';

      final response = await http.get(
        Uri.parse(jinaUrl),
        headers: {
          'Accept': 'text/plain',
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 45)); // 增加超时时间

      if (response.statusCode == 200) {
        final content = response.body;

        // 检查是否实际提取到了有效内容
        if (content.trim().isEmpty || content.length < 50) {
          throw Exception('提取的内容过少，可能是该网站限制了访问。\n\n'
              '💡 建议：\n'
              '1. 在浏览器中打开链接\n'
              '2. 复制全文内容\n'
              '3. 切换到"文本导入"标签粘贴');
        }

        // 尝试从内容中提取标题
        String title = '来自网页的内容';
        final lines = content.split('\n');
        for (var line in lines) {
          if (line.startsWith('# ')) {
            title = line.substring(2).trim();
            break;
          }
        }

        // 如果是微信公众号，尝试从URL中获取更多信息
        if (url.contains('mp.weixin.qq.com')) {
          title = title.isEmpty ? '微信公众号文章' : title;
        } else if (url.contains('xiaohongshu.com') ||
            url.contains('xhslink.com')) {
          title = title.isEmpty ? '小红书笔记' : title;
        }

        if (kDebugMode) print('✅ Extracted ${content.length} characters');

        return ExtractionResult(
          title: title,
          content: content,
          sourceUrl: url,
          sourceType: SourceType.url,
        );
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        throw Exception('网站拒绝访问 (${response.statusCode})\n\n'
            '该网站可能需要登录或有访问限制。\n\n'
            '💡 建议使用"文本导入"功能：\n'
            '1. 在浏览器中打开并登录\n'
            '2. 复制全文\n'
            '3. 粘贴到"文本导入"标签');
      } else if (response.statusCode == 404) {
        throw Exception('链接无效或文章已删除 (404)');
      } else {
        throw Exception('提取失败 (HTTP ${response.statusCode})\n\n'
            '${needsSpecialHandling != null ? "检测到 $needsSpecialHandling 平台，" : ""}'
            '建议使用"文本导入"功能手动粘贴内容。');
      }
    } on TimeoutException {
      throw Exception('网络请求超时\n\n'
          '可能原因：\n'
          '• 网络连接较慢\n'
          '• 网站响应时间过长\n'
          '• 网站有访问限制\n\n'
          '💡 建议：重试或使用"文本导入"功能');
    } catch (e) {
      if (kDebugMode) print('❌ URL extraction failed: $e');

      // 如果是我们自己抛出的友好错误，直接传递
      if (e is Exception && e.toString().contains('建议')) {
        rethrow;
      }

      // 其他错误，提供通用建议
      throw Exception('内容提取失败\n\n'
          '错误详情: ${e.toString()}\n\n'
          '💡 备选方案：\n'
          '1. 检查链接是否正确\n'
          '2. 使用"文本导入"标签手动粘贴内容\n'
          '3. 尝试其他公开的文章链接');
    }
  }

  /// 检测是否需要特殊处理的平台
  static String? _checkIfNeedsSpecialHandling(String url) {
    if (url.contains('mp.weixin.qq.com')) {
      return '微信公众号';
    } else if (url.contains('xiaohongshu.com') || url.contains('xhslink.com')) {
      return '小红书';
    } else if (url.contains('zhihu.com')) {
      return '知乎';
    } else if (url.contains('juejin.cn')) {
      return '掘金';
    } else if (url.contains('bilibili.com')) {
      return 'B站';
    }
    return null;
  }

  /// 从纯文本创建提取结果
  static ExtractionResult extractFromText(String text, {String? title}) {
    return ExtractionResult(
      title: title ?? '粘贴的文本',
      content: text,
      sourceType: SourceType.text,
    );
  }

  /// 使用 Gemini AI 将提取的内容转换为知识卡片
  ///
  /// 复用现有的 AI 生成逻辑（来自 test_gemini_generation.dart）
  static Future<List<FeedItem>> generateKnowledgeCards(
    ExtractionResult extraction, {
    required String moduleId,
    AiDeconstructionMode mode = AiDeconstructionMode.standard,
  }) async {
    final apiKey = ApiConfig.getApiKey();
    final proxyUrl = ApiConfig.geminiProxyUrl;
    final client = proxyUrl.isNotEmpty ? ProxyHttpClient(proxyUrl) : null;

    final model = GenerativeModel(
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

    String modeInstructions = '';
    if (mode == AiDeconstructionMode.grandma) {
      modeInstructions = '''
## 🚨 重要：采用“极简大白话”风格 🚨
- **语言风格**：严禁使用任何专业术语。如果不得不提术语，必须用“大白话”进行降维打击式的解释。
- **类比要求**：必须包含至少一个极其生活化、接地气的类比来解释复杂逻辑。
- **讲解要求**：亲切、耐心、直白。禁止任何寒暄（如“奶奶您好”），直接开始深入浅出地讲解知识点本身。
''';
    } else if (mode == AiDeconstructionMode.phd) {
      modeInstructions = '''
## 🚨 重要：采用“智障博士生”级别拆解 🚨
- **目标**：像是在给逻辑极度敏感、但认知极简的人解释。
- **语言风格**：必须使用**极简的大白话**，傻子都能听懂的语音。严禁堆砌专业术语，严禁使用长句。**严禁在文字之间添加任何多余的空格或空格占位**。
- **逻辑要求**：禁止任何感性类比（如：买菜、带孩子、点外卖）。必须通过严密的逻辑推导、事实陈述、因果链条来拆解核心。
- **语气**：直白。禁止任何寒暄，直接开始讲解知识点本身。
''';
    }

    final prompt = '''
你是一位资深的教育内容专家和产品经理导师。你的任务是将用户提供的学习资料转化为易于理解和记忆的知识卡片。

$modeInstructions

## 核心要求

### 0. 语言语言约束
- **强制要求**：无论原始学习资料使用何种语言（英文、日文、德文等），生成的知识卡片中的所有字段（title, category, content, flashcard 里的 question 和 answer）**必须全部且只能使用简体中文**。

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
  - **结构要求**：${mode == AiDeconstructionMode.grandma ? "采用极简大白话和生活类比。" : (mode == AiDeconstructionMode.phd ? "采用极简大白话，严密逻辑拆解，禁止类比，文内严禁多余空格。" : "采用\"是什么 → 为什么 → 怎么做\"的结构。")}

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
    "content": "# 标题\\n\\n[在此处填写详细的知识点正文内容，不少于 300 字]",
    "flashcard": {
      "question": "具体的测试问题",
      "answer": "简洁但完整的答案"
    }
  }
]

现在，请根据以上要求，分析用户提供的文本并生成知识卡片。
''';

    final content = [
      Content.text('$prompt\n\n## 用户输入的学习资料：\n\n${extraction.content}')
    ];

    if (kDebugMode) print('🤖 Generating knowledge cards...');

    final response = await model.generateContent(content);
    final responseText = response.text;

    if (responseText == null) {
      throw Exception('AI 未返回任何内容');
    }

    // 清理 JSON
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

    // 解析 JSON
    final jsonData = jsonDecode(cleanedResponse) as List;

    // 转换为 FeedItem
    final items = <FeedItem>[];
    for (int i = 0; i < jsonData.length; i++) {
      final item = jsonData[i];
      final id = 'custom_${DateTime.now().millisecondsSinceEpoch}_$i';

      items.add(FeedItem(
        id: id,
        moduleId: moduleId,
        title: item['title'] ?? 'Untitled',
        category: item['category'] ?? 'AI Generated',
        difficulty: item['difficulty'] ?? 'Medium',
        readingTimeMinutes: 5,
        isCustom: true, // 用户生成的内容，可删除
        pages: [
          OfficialPage(
            item['content'] ?? '',
            flashcardQuestion: item['flashcard']?['question'],
            flashcardAnswer: item['flashcard']?['answer'],
          ),
        ],
      ));
    }

    if (kDebugMode) print('✅ Generated ${items.length} knowledge cards');

    return items;
  }

  /// 流式生成知识卡片 - 支持超长文本分段处理
  static Stream<StreamingGenerationEvent> generateKnowledgeCardsStream(
    ExtractionResult extraction, {
    required String moduleId,
    required Future<bool> Function(int) onChunkProcess, // 传入需要扣除的积分数
    AiDeconstructionMode mode = AiDeconstructionMode.standard,
  }) async* {
    const int baseLimit = 15000;
    const double graceFactor = 1.2; // 20% 的宽容度

    final content = extraction.content;
    final List<String> chunks = [];

    if (content.length <= baseLimit * graceFactor) {
      // 在宽容范围内，只当做一个块处理
      chunks.add(content);
    } else {
      // 确实太长了，需要分段。
      // 采用“等分”策略，而不是固定大小切块，避免出现一个极小的尾巴
      final int count = (content.length / baseLimit).ceil();
      final int chunkSize = (content.length / count).ceil();

      for (int i = 0; i < count; i++) {
        final start = i * chunkSize;
        final end = (i + 1) * chunkSize > content.length
            ? content.length
            : (i + 1) * chunkSize;
        if (start < end) {
          chunks.add(content.substring(start, end));
        }
      }
    }

    final apiKey = ApiConfig.getApiKey();
    final proxyUrl = ApiConfig.geminiProxyUrl;
    final client = proxyUrl.isNotEmpty ? ProxyHttpClient(proxyUrl) : null;

    final model = GenerativeModel(
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

    // 已经计算好的 chunks 循环
    for (int chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
      final chunkContent = chunks[chunkIndex];

      if (chunks.length > 1) {
        yield StreamingGenerationEvent.status(
            '正在处理第 ${chunkIndex + 1}/${chunks.length} 段内容...');
      }

      // ========== 第一步：获取当前 Chunk 的大纲 ==========
      String modeOutlineInstructions = '';
      if (mode == AiDeconstructionMode.grandma) {
        modeOutlineInstructions = "采用“极简大白话”风格：识别出最基础、最通俗的核心知识点，标题要平实直白。";
      } else if (mode == AiDeconstructionMode.phd) {
        modeOutlineInstructions = "采用“智障博士生”风格：极简大白话，禁止多余空格，逻辑严密，直接提取逻辑支柱。";
      }

      final outlinePrompt = '''
你是一位资深的教育内容专家。请快速分析用户提供的学习资料，识别出其中的核心知识点。

$modeOutlineInstructions

## 任务
1. 阅读用户的学习资料
2. 识别出 2-8 个独立的核心知识点
3. 每个知识点用一个简洁的标题概括（10-20字）

## 输出格式
严格按照以下 JSON 格式输出（只输出 JSON，不要有其他文字）。
**重要提示：所有输出内容必须使用简体中文，即使原文是英文。**

严格按照以下 JSON 格式输出：

{
  "topics": [
    {"title": "知识点1的标题", "category": "分类", "difficulty": "Easy|Medium|Hard"},
    {"title": "知识点2的标题", "category": "分类", "difficulty": "Medium"}
  ]
}
''';

      final outlineContent = [
        Content.text('$outlinePrompt\n\n## 用户的学习资料：\n\n$chunkContent')
      ];

      try {
        final outlineResponse = await model.generateContent(outlineContent);

        // --- 扣费逻辑调整：根据单块权重扣费 ---
        // 单块处理通常对应 20 积分档次（由调用方根据 calculateRequiredCredits 计算总额）
        final chunkCredits =
            chunks.length == 1 && content.length <= 5000 ? 10 : 20;
        final canContinue = await onChunkProcess(chunkCredits);

        if (!canContinue) {
          yield StreamingGenerationEvent.error(
              chunks.length > 1 ? '积分不足，已停止处理后续分段' : '积分不足，无法开始生成');
          return;
        }

        final outlineText = outlineResponse.text;

        if (outlineText == null) continue;

        // 解析大纲
        String cleanedOutline = outlineText.trim();
        if (cleanedOutline.startsWith('```json')) {
          cleanedOutline = cleanedOutline.substring(7);
        }
        if (cleanedOutline.startsWith('```')) {
          cleanedOutline = cleanedOutline.substring(3);
        }
        if (cleanedOutline.endsWith('```')) {
          cleanedOutline =
              cleanedOutline.substring(0, cleanedOutline.length - 3);
        }
        cleanedOutline = cleanedOutline.trim();

        final outlineJson = jsonDecode(cleanedOutline) as Map<String, dynamic>;
        final String topicsField = outlineJson.containsKey('topics')
            ? 'topics'
            : (outlineJson.containsKey('items') ? 'items' : '');

        if (topicsField.isEmpty) continue;

        final topics =
            (outlineJson[topicsField] as List).cast<Map<String, dynamic>>();

        if (chunks.length > 1) {
          yield StreamingGenerationEvent.status(
              '第 ${chunkIndex + 1} 段发现 ${topics.length} 个知识点，正在生成...');
        } else {
          yield StreamingGenerationEvent.outline(topics.length);
        }

        // ========== 第二步：逐个生成卡片 ==========
        for (int i = 0; i < topics.length; i++) {
          final topic = topics[i];
          final String title = topic['title'] as String;
          final String category =
              topic['category'] as String? ?? 'AI Generated';
          final String difficulty = topic['difficulty'] as String? ?? 'Medium';

          yield StreamingGenerationEvent.status(
              '正在生成: $title (${i + 1}/${topics.length})');

          String modeInstructions = '';
          if (mode == AiDeconstructionMode.grandma) {
            modeInstructions = '采用“极简大白话”风格：极其通俗易懂，严禁术语，多用生活化类比。禁止寒暄，直接讲解。';
          } else if (mode == AiDeconstructionMode.phd) {
            modeInstructions = '采用“智障博士生”风格：极简大白话，严禁文中空格，禁止类比。重点在于硬核逻辑拆解。直接讲解。';
          }

          final cardPrompt = '''
你是一位资深的教育内容专家。请针对以下知识点，生成一张详细的知识卡片。

$modeInstructions

## 知识点标题
$title

## 参考资料（从中提取相关内容）
$chunkContent

## 要求
1. 正文内容：必须生成 300-800 字的详细解释。${mode == AiDeconstructionMode.grandma ? "采用极简大白话和生活类比。" : (mode == AiDeconstructionMode.phd ? "采用极简大白话，严密逻辑拆解，严禁文中多余空格。" : "采用\"是什么 → 为什么 → 怎么做\"的结构。")}
2. **Flashcard**：一个具体的测试问题 + 简洁但完整的答案（100-200字）
3. 使用 Markdown 格式
4. **语言要求**：输出的所有内容必须使用简体中文。

## 输出格式
严格按照以下 JSON 格式输出：

{
  "title": "$title",
  "category": "$category",
  "difficulty": "$difficulty",
  "content": "# 标题\\n\\n[在此处填写详细的知识点正文内容，不少于 300 字]",
  "flashcard": {
    "question": "具体的测试问题",
    "answer": "简洁但完整的答案"
  }
}
''';

          final cardContent = [Content.text(cardPrompt)];
          final cardResponse = await model.generateContent(cardContent);
          final cardText = cardResponse.text;

          if (cardText == null) continue;

          // 解析卡片
          String cleanedCard = cardText.trim();
          if (cleanedCard.startsWith('```json')) {
            cleanedCard = cleanedCard.substring(7);
          }
          if (cleanedCard.startsWith('```')) {
            cleanedCard = cleanedCard.substring(3);
          }
          if (cleanedCard.endsWith('```')) {
            cleanedCard = cleanedCard.substring(0, cleanedCard.length - 3);
          }
          cleanedCard = cleanedCard.trim();

          try {
            final cardJson = jsonDecode(cleanedCard) as Map<String, dynamic>;
            final id =
                'custom_${DateTime.now().millisecondsSinceEpoch}_${chunkIndex}_$i';

            final feedItem = FeedItem(
              id: id,
              moduleId: moduleId,
              title: cardJson['title'] ?? title,
              category: cardJson['category'] ?? category,
              difficulty: cardJson['difficulty'] ?? difficulty,
              readingTimeMinutes: 5,
              isCustom: true,
              pages: [
                OfficialPage(
                  cardJson['content'] ?? '',
                  flashcardQuestion: cardJson['flashcard']?['question'],
                  flashcardAnswer: cardJson['flashcard']?['answer'],
                ),
              ],
            );

            yield StreamingGenerationEvent.card(feedItem, i + 1, topics.length);
          } catch (e) {
            if (kDebugMode) print('❌ Failed to parse card: $e');
          }
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ Chunk processing error: $e');
        continue;
      }
    }

    yield StreamingGenerationEvent.complete();
  }

  /// 一键处理：提取 + 生成
  static Future<List<FeedItem>> processUrl(
    String url, {
    required String moduleId,
  }) async {
    final extraction = await extractFromUrl(url);
    return generateKnowledgeCards(extraction, moduleId: moduleId);
  }

  /// 一键处理：文本 + 生成
  static Future<List<FeedItem>> processText(
    String text, {
    required String moduleId,
    String? title,
  }) async {
    final extraction = extractFromText(text, title: title);
    return generateKnowledgeCards(extraction, moduleId: moduleId);
  }

  /// 检测是否为 YouTube 链接
  static bool _isYoutubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  /// 完全后台 AI 处理
  ///
  /// 工作流程：
  /// 1. 创建任务文档到 Firestore
  /// 2. 调用云函数启动处理（Fire-and-forget，不等待结果）
  /// 3. 监听 Firestore 文档获取实时进度更新
  /// 4. 即使关闭浏览器，任务也会在服务器端继续执行
  /// 5. 重新打开时可以恢复查看进度
  static Stream<StreamingGenerationEvent> startBackgroundJob(
    String content, {
    required String moduleId,
    bool isGrandmaMode = false,
  }) async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('未登录');

    yield StreamingGenerationEvent.status('正在提交任务...');

    // 使用 'reado' 数据库
    final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'reado',
    );

    try {
      // 1. 创建任务文档
      final docRef = db.collection('extraction_jobs').doc();
      await docRef.set({
        'userId': user.uid,
        'content': content,
        'moduleId': moduleId,
        'isGrandmaMode': isGrandmaMode,
        'status': 'pending',
        'progress': 0.0,
        'message': '等待服务器...',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final jobId = docRef.id;
      if (kDebugMode) print('📝 Created job: $jobId');

      yield StreamingGenerationEvent.status('任务已提交，正在启动处理...');

      // 2. 调用云函数启动处理 (Fire-and-forget，不等待返回)
      final callable = FirebaseFunctions.instance.httpsCallable(
        'processExtractionJob',
        options: HttpsCallableOptions(
          timeout: const Duration(minutes: 10),
        ),
      );

      // 不 await 这个调用，让它在后台运行
      callable.call({'jobId': jobId}).then((_) {
        if (kDebugMode) print('✅ Cloud function completed for $jobId');
      }).catchError((e) {
        if (kDebugMode) print('⚠️ Cloud function error (may be handled): $e');
      });

      // 3. 监听 Firestore 获取实时更新
      yield* listenToJob(db, jobId);
    } catch (e) {
      yield StreamingGenerationEvent.error('启动任务失败: $e');
    }
  }

  /// 🔥 提交任务后立即返回 (Fire-and-Forget)
  ///
  /// 用于用户点击生成后立刻关闭弹窗的场景
  /// 返回 jobId，用户可以之后在任务中心查看进度
  static Future<String> submitJobAndForget(
    String content, {
    required String moduleId,
    AiDeconstructionMode mode = AiDeconstructionMode.standard,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('未登录');

    // 使用 'reado' 数据库
    final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'reado',
    );

    // 1. 创建任务文档
    final docRef = db.collection('extraction_jobs').doc();
    await docRef.set({
      'userId': user.uid,
      'content': content,
      'moduleId': moduleId,
      'isGrandmaMode': mode == AiDeconstructionMode.grandma, // 兼容旧逻辑
      'deconstructionMode': mode.name,
      'status': 'pending',
      'progress': 0.0,
      'message': '等待服务器...',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final jobId = docRef.id;
    if (kDebugMode) print('📝 Created job (fire-and-forget): $jobId');

    // 2. 调用云函数启动处理 (Fire-and-forget)
    final callable = FirebaseFunctions.instance.httpsCallable(
      'processExtractionJob',
      options: HttpsCallableOptions(
        timeout: const Duration(minutes: 10),
      ),
    );

    // 不 await，让它在后台运行
    callable.call({'jobId': jobId}).then((_) {
      if (kDebugMode) print('✅ Cloud function completed for $jobId');
    }).catchError((e) {
      if (kDebugMode) print('⚠️ Cloud function error (may be handled): $e');
    });

    return jobId;
  }

  /// 监听单个任务的进度
  static Stream<StreamingGenerationEvent> listenToJob(
    FirebaseFirestore db,
    String jobId,
  ) async* {
    final controller = StreamController<StreamingGenerationEvent>();
    int yieldedCardsCount = 0;

    final docRef = db.collection('extraction_jobs').doc(jobId);

    final subscription = docRef.snapshots().listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;

      final status = data['status'] as String?;
      final message = data['message'] as String?;
      final cardsData = data['cards'] as List<dynamic>? ?? [];
      final totalCards = data['totalCards'] as int? ?? cardsData.length;

      // 1. 发送状态消息
      if (message != null) {
        controller.add(StreamingGenerationEvent.status(message));
      }

      // 2. 发送大纲信息
      if (data.containsKey('totalCards') &&
          yieldedCardsCount == 0 &&
          totalCards > 0) {
        controller.add(StreamingGenerationEvent.outline(totalCards));
      }

      // 3. 发送新生成的卡片
      if (cardsData.length > yieldedCardsCount) {
        for (int i = yieldedCardsCount; i < cardsData.length; i++) {
          try {
            final cardMap = cardsData[i] as Map<String, dynamic>;
            final item = _parseCardFromMap(cardMap);
            controller
                .add(StreamingGenerationEvent.card(item, i + 1, totalCards));
          } catch (e) {
            if (kDebugMode) print('Error parsing card: $e');
          }
        }
        yieldedCardsCount = cardsData.length;
      }

      // 4. 检查是否完成或失败
      if (status == 'completed') {
        controller.add(StreamingGenerationEvent.complete());
        controller.close();
      } else if (status == 'failed') {
        final error = data['error'] as String? ?? '未知错误';
        controller.add(StreamingGenerationEvent.error(error));
        controller.close();
      }
    }, onError: (e) {
      controller.add(StreamingGenerationEvent.error('连接错误: $e'));
      controller.close();
    });

    controller.onCancel = () {
      subscription.cancel();
    };

    yield* controller.stream;
  }

  /// 从 Map 解析 FeedItem
  static FeedItem _parseCardFromMap(Map<String, dynamic> cardMap) {
    try {
      // 1. 尝试使用标准的 fromJson (云函数已调整为兼容格式)
      return FeedItem.fromJson(cardMap);
    } catch (e) {
      if (kDebugMode) print('Parser: fallback to manual parse due to: $e');

      // 2. 备选方案：手动兼容处理
      final pages = cardMap['pages'] as List<dynamic>?;
      String pageContent = '';
      String? flashQ, flashA;

      if (pages != null && pages.isNotEmpty) {
        final firstPage = pages[0] as Map<String, dynamic>;
        // 兼容 content 和 markdownContent 两个字段
        pageContent = (firstPage['markdownContent'] ??
                firstPage['content'] ??
                'No content generated')
            .toString();
        flashQ = firstPage['flashcardQuestion']?.toString();
        flashA = firstPage['flashcardAnswer']?.toString();
      } else {
        pageContent = (cardMap['content'] ?? '').toString();
        final flashMap = cardMap['flashcard'] as Map<String, dynamic>?;
        flashQ = flashMap?['question']?.toString();
        flashA = flashMap?['answer']?.toString();
      }

      return FeedItem(
        id: (cardMap['id'] ?? 'temp_${DateTime.now().millisecondsSinceEpoch}')
            .toString(),
        moduleId:
            (cardMap['moduleId'] ?? cardMap['module'] ?? 'custom').toString(),
        title: (cardMap['title'] ?? '未命名知识点').toString(),
        category: (cardMap['category'] ?? 'AI Generated').toString(),
        difficulty: (cardMap['difficulty'] ?? 'Medium').toString(),
        createdAt: DateTime.now(),
        pages: [
          OfficialPage(
            pageContent,
            flashcardQuestion: flashQ,
            flashcardAnswer: flashA,
          )
        ],
        isCustom: true,
      );
    }
  }

  /// 检查是否有未完成的任务（用户重新打开应用时调用）
  static Future<String?> checkPendingJob() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'reado',
    );

    try {
      final snapshot = await db
          .collection('extraction_jobs')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['pending', 'processing'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
    } catch (e) {
      if (kDebugMode) print('Error checking pending jobs: $e');
    }
    return null;
  }

  /// 恢复监听已有的任务
  static Stream<StreamingGenerationEvent> resumeJob(String jobId) async* {
    final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'reado',
    );

    yield* listenToJob(db, jobId);
  }

  /// 从 YouTube 提取内容 (视频信息 + 字幕)
  static Future<ExtractionResult> _extractFromYoutube(String url) async {
    final ytClient = yt.YoutubeExplode();
    try {
      // 1. 获取视频基本信息
      final video = await ytClient.videos.get(url);
      final title = video.title;
      final description = video.description;
      final author = video.author;

      final buffer = StringBuffer();
      buffer.writeln('# $title\n');
      buffer.writeln('**频道**: $author');
      buffer.writeln('**时长**: ${video.duration}\n');

      // 2. 尝试获取字幕
      try {
        final manifest =
            await ytClient.videos.closedCaptions.getManifest(video.id);

        if (manifest.tracks.isNotEmpty) {
          // 优先获取自动生成的字幕（通常都有），或者第一个可用的
          final trackInfo = manifest.tracks.firstWhere(
            (t) => t.language.code == 'en' || t.language.code == 'zh',
            orElse: () => manifest.tracks.first,
          );

          final captions = await ytClient.videos.closedCaptions.get(trackInfo);

          buffer.writeln('## 视频字幕内容\n');

          // 将字幕组合成段落，避免太碎
          String currentSentence = '';

          // 尝试访问 captions 属性 (如果是 ClosedCaptionTrack)
          for (final caption in captions.captions) {
            currentSentence += ' ${caption.text}';
            if (currentSentence.length > 100 || caption.text.endsWith('.')) {
              buffer.write('$currentSentence\n');
              currentSentence = '';
            }
          }
          if (currentSentence.isNotEmpty) {
            buffer.write('$currentSentence\n');
          }
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ Failed to get captions: $e');
        buffer.writeln('\n> (未找到字幕，使用视频描述替代)\n');
        buffer.writeln('## 视频描述\n');
        buffer.writeln(description);
      }

      return ExtractionResult(
        title: title,
        content: buffer.toString(),
        sourceUrl: url,
        sourceType: SourceType.youtube,
      );
    } finally {
      ytClient.close();
    }
  }

  /// 从 PDF 字节数据提取内容
  static Future<ExtractionResult> extractFromPdfBytes(
    Uint8List bytes, {
    String filename = 'PDF Document',
  }) async {
    try {
      // 加载 PDF 文档
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // 提取所有文本
      // PdfTextExtractor 是 syncfusion 提供的强大提取器
      String text = PdfTextExtractor(document).extractText();

      // 释放资源
      document.dispose();

      if (text.trim().isEmpty) {
        throw Exception('未能从 PDF 中提取到文本，可能是扫描件或图片 PDF');
      }

      return ExtractionResult(
        title: filename,
        content: text,
        sourceType: SourceType.pdf,
      );
    } catch (e) {
      if (kDebugMode) print('❌ PDF extraction failed: $e');
      throw Exception('PDF 解析失败: $e');
    }
  }

  /// 从 DOCX 字节数据提取内容
  static Future<ExtractionResult> extractFromDocxBytes(
    Uint8List bytes, {
    String filename = 'Word Document',
  }) async {
    try {
      final text = docxToText(bytes);

      if (text.trim().isEmpty) {
        throw Exception('未能从文档中提取到文本');
      }

      return ExtractionResult(
        title: filename,
        content: text,
        sourceType: SourceType.text, // Treat as text source
      );
    } catch (e) {
      if (kDebugMode) print('❌ DOCX extraction failed: $e');
      throw Exception('Word 文档解析失败: $e');
    }
  }

  /// 从 TXT 字节数据提取内容
  static Future<ExtractionResult> extractFromTxtBytes(
    Uint8List bytes, {
    String filename = 'Text Document',
  }) async {
    try {
      final text = utf8.decode(bytes);

      if (text.trim().isEmpty) {
        throw Exception('文件内容为空');
      }

      return ExtractionResult(
        title: filename,
        content: text,
        sourceType: SourceType.text,
      );
    } catch (e) {
      if (kDebugMode) print('❌ TXT extraction failed: $e');
      throw Exception('文本文件解析失败: $e');
    }
  }

  /// 通用文件提取（不生成）
  static Future<ExtractionResult> extractContentFromFile(
    Uint8List bytes, {
    required String filename,
  }) async {
    final ext = filename.split('.').last.toLowerCase();

    switch (ext) {
      case 'pdf':
        return await extractFromPdfBytes(bytes, filename: filename);
      case 'docx':
        return await extractFromDocxBytes(bytes, filename: filename);
      case 'doc':
        throw Exception('暂不支持 .doc 格式 (老版本 Word)，请另存为 .docx 或 .pdf 后重试。');
      case 'txt':
      case 'md':
        return await extractFromTxtBytes(bytes, filename: filename);
      default:
        throw Exception('不支持的文件格式: .$ext');
    }
  }

  /// 通用文件处理（提取 + 生成）
  static Future<List<FeedItem>> processFile(
    Uint8List bytes, {
    required String filename,
    required String moduleId,
  }) async {
    final extraction = await extractContentFromFile(bytes, filename: filename);
    return generateKnowledgeCards(extraction, moduleId: moduleId);
  }

  /// (Legacy wrapper) 一键处理：PDF + 生成
  static Future<List<FeedItem>> processPdf(
    Uint8List bytes, {
    required String moduleId,
    String filename = 'PDF Document',
  }) async {
    return processFile(bytes, filename: filename, moduleId: moduleId);
  }
}
