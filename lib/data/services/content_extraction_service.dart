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

/// 内容提取服务
class ContentExtractionService {
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
  }) async {
    final apiKey = ApiConfig.getApiKey();

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.7,
        topP: 0.9,
        topK: 40,
      ),
    );

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
