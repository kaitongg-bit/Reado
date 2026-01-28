import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../models/feed_item.dart';
import '../../../../data/services/content_extraction_service.dart';
import '../../feed/presentation/feed_provider.dart';

class AddMaterialModal extends ConsumerStatefulWidget {
  final String? targetModuleId;
  const AddMaterialModal({super.key, this.targetModuleId});

  @override
  ConsumerState<AddMaterialModal> createState() => _AddMaterialModalState();
}

class _AddMaterialModalState extends ConsumerState<AddMaterialModal> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  bool _isGenerating = false;
  bool _isExtractingUrl = false;

  ExtractionResult? _extractionResult; // 存储提取结果
  List<FeedItem>? _generatedItems;
  String? _error;
  String? _urlError;

  String? _pickedFileName; // New: For storing picked file name
  PlatformFile? _pickedFile; // Holds the actual file object

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  /// AI 智能拆解 - 从粘贴的文本生成知识卡片
  Future<void> _generate() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final moduleId = widget.targetModuleId ?? 'custom';
      final newItems = await ContentExtractionService.processText(
        _textController.text,
        moduleId: moduleId,
      );

      if (!mounted) return;

      setState(() {
        _generatedItems = newItems;
        _isGenerating = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isGenerating = false;
      });
    }
  }

  /// 1. 仅选择文件，不解析
  Future<void> _pickFile() async {
    try {
      // Clear URL if picking file (Mutually exclusive check)
      if (_urlController.text.isNotEmpty) {
        _urlController.clear();
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
          _pickedFileName = _pickedFile!.name;
          _error = null;
          _urlError = null;
          _extractionResult = null; // Clear previous result
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  /// 2. 统一解析入口 (URL 或 File)
  Future<void> _performParse() async {
    setState(() {
      _isExtractingUrl = true; // Reusing this bool for general "Parsing" state
      _error = null;
      _urlError = null;
    });

    try {
      ExtractionResult? result;
      // Priority: File > URL (Since picking file clears URL usually, but let's check)
      if (_pickedFile != null) {
        final bytes = _pickedFile!.bytes;
        if (bytes == null) throw Exception('无法读取文件内容');
        result = await ContentExtractionService.extractContentFromFile(
          bytes,
          filename: _pickedFile!.name,
        );
      } else if (_urlController.text.trim().isNotEmpty) {
        final url = _urlController.text.trim();
        if (!url.startsWith('http')) throw Exception('请输入有效的 http/https 链接');
        result = await ContentExtractionService.extractFromUrl(url);
      } else {
        throw Exception('请先上传文件或粘贴链接');
      }

      if (!mounted) return;

      setState(() {
        _extractionResult = result;
        _isExtractingUrl = false;
        // _generatedItems is still null, waiting for AI
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString(); // Show global error
        _isExtractingUrl = false;
      });
    }
  }

  /// Old Upload method (kept temporarily or removed if replacing fully)
  /// replaced by split logic above.

  /// 开始 AI 生成
  Future<void> _startGeneration() async {
    if (_extractionResult == null) return;

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final moduleId = widget.targetModuleId ?? 'custom';
      final newItems = await ContentExtractionService.generateKnowledgeCards(
        _extractionResult!,
        moduleId: moduleId,
      );

      if (!mounted) return;

      setState(() {
        _generatedItems = newItems;
        _isGenerating = false;
        // 保留 _extractionResult 以便可能的后续操作，或者清空取决于需求
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isGenerating = false;
      });
    }
  }

  void _parseLocally() {
    if (_textController.text.trim().isEmpty) return;

    final text = _textController.text;
    final List<FeedItem> items = [];
    final lines = text.split('\n');

    List<String> headerStack = [];
    StringBuffer currentContent = StringBuffer();
    String? activeTitle; // 当前正在积累内容的标题

    void saveCurrent() {
      final contentStr = currentContent.toString().trim();
      if (contentStr.isNotEmpty) {
        String title = activeTitle ?? 'Overview';

        // 如果没有标题 (activeTitle 为 null)，尝试用正文第一行作为标题
        if (activeTitle == null) {
          final firstLine = contentStr.split('\n').first.trim();
          if (firstLine.isNotEmpty) {
            title = firstLine.length > 20
                ? '${firstLine.substring(0, 20)}...'
                : firstLine;
          }
        }

        // 智能优化：如果由于层级深导致标题只有"场景题"这种简单词，尝试拼接上一级
        // 比如: "Redis > 场景题"
        if (headerStack.length > 1 && title.length < 5) {
          final parent = headerStack[headerStack.length - 2];
          title = '$parent > $title';
        }

        // 尝试提取分类
        String category = 'Note';
        if (headerStack.isNotEmpty) {
          category = headerStack.first; // 最高层级作为分类
        }

        items.add(FeedItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() +
              items.length.toString(),
          moduleId: widget.targetModuleId ?? 'custom',
          title: title,
          pages: [OfficialPage("# $title\n\n$contentStr")],
          category: category,
          masteryLevel: FeedItemMastery.unknown,
        ));
      }
    }

    final headerRegex = RegExp(r'^(#+)\s+(.*)');

    for (var line in lines) {
      final match = headerRegex.firstMatch(line);

      // 忽略代码块中的 # (简单处理，不完美但有效)
      // 如果正处于代码块中... 这里暂时不搞那么复杂，假设 # 开头就是标题

      if (match != null) {
        // === 遇到新标题 ===
        // 1. 先结算上一段内容
        saveCurrent();

        // 2. 解析新标题信息
        final level = match.group(1)!.length;
        final titleRaw = match.group(2)!.trim();

        // 3. 维护标题栈
        if (level <= headerStack.length) {
          // 回退栈：保留 0 到 level-1
          headerStack = headerStack.sublist(0, level - 1);
        }
        headerStack.add(titleRaw);

        activeTitle = titleRaw;
        currentContent = StringBuffer(); // 重置正文缓冲
      } else {
        // === 遇到正文 ===
        currentContent.writeln(line);
      }
    }
    // 循环结束，结算最后一张
    saveCurrent();

    // Fallback: 全文无标题
    if (items.isEmpty && text.trim().isNotEmpty) {
      final firstLine = text.trim().split('\n').first;
      items.add(FeedItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        moduleId: widget.targetModuleId ?? 'custom',
        title: firstLine.length > 30
            ? '${firstLine.substring(0, 30)}...'
            : firstLine,
        pages: [OfficialPage(text)],
        category: 'Manual',
        masteryLevel: FeedItemMastery.unknown,
      ));
    }

    setState(() {
      _generatedItems = items;
    });
  }

  void _saveAll() async {
    if (_generatedItems == null) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('用户未登录');
      }

      // 保存到 Firestore
      final service = ref.read(dataServiceProvider);
      for (var item in _generatedItems!) {
        // 如果指定了 module，则覆盖
        final itemToSave = widget.targetModuleId != null
            ? item.copyWith(moduleId: widget.targetModuleId!)
            : item;
        await service.saveCustomFeedItem(itemToSave, currentUser.uid);
      }

      // 同时添加到内存 Provider（用于即时显示）
      ref.read(feedProvider.notifier).addCustomItems(_generatedItems!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('成功添加 ${_generatedItems!.length} 个知识点到 Firestore！')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 750),
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '添加学习资料',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B), // Slate 800
                        fontFamily:
                            'Plus Jakarta Sans', // Fallback to system if not avail
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: const Color(0xFFFF8A65),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8A65).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: '文本导入'),
                      Tab(text: '多模态 (AI)'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: TabBarView(
                      children: [
                        _buildPlainTextTab(),
                        _buildNotebookLMTab(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlainTextTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_generatedItems == null) ...[
            // Input State
            Expanded(
              child: Column(
                children: [
                  // Hint Box
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // Blue 50
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: Color(0xFF3B82F6), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF1E293B)),
                              children: [
                                TextSpan(
                                    text: '小贴士：',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: '使用 Markdown 标题 (如 '),
                                TextSpan(
                                    text: '# 标题',
                                    style: TextStyle(
                                        fontFamily: 'monospace',
                                        backgroundColor: Color(0xFFDBEAFE))),
                                TextSpan(
                                    text:
                                        ') 可手动拆分卡片，无需消耗 AI 额度。若无标题，将默认使用第一句话作为标题。'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Color(0xFF334155)),
                        decoration: const InputDecoration(
                          hintText:
                              '在此粘贴文章内容、笔记或网页文本...\n\n示例：\n# 什么是 Flutter\nFlutter 是 Google 开源的 UI 工具包...\n\n# 特点\n1. 跨平台\n2. 高性能...',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13))),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _isGenerating ? null : _parseLocally,
                    icon: const Icon(Icons.format_align_left),
                    label: const Text('直接导入'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      foregroundColor: const Color(0xFF64748B),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generate,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isGenerating ? 'AI 智能解析中...' : 'AI 智能拆解'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A65),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      shadowColor: const Color(0xFFFF8A65).withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Review State
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '已生成 ${_generatedItems!.length} 个知识点',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B)),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
                  onPressed: () {
                    setState(() {
                      _generatedItems = null;
                      _isGenerating = false;
                    });
                  },
                  tooltip: '重新编辑',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _generatedItems!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _generatedItems![index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${index + 1}',
                                  style: const TextStyle(
                                      color: Color(0xFF3B82F6),
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(item.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16))),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(item.category,
                                  style: const TextStyle(
                                      fontSize: 10, color: Color(0xFF64748B))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFFFEDD5)),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    const Icon(Icons.help_outline,
                                        size: 14, color: Color(0xFFF97316)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(
                                            '提问: ${(item.pages.first as OfficialPage).flashcardQuestion ?? "自动生成中..."}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF9A3412),
                                                fontWeight: FontWeight.w500)))
                                  ])
                                ])),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _generatedItems = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      foregroundColor: const Color(0xFF64748B),
                    ),
                    child: const Text('返回修改'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('确认并保存'),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildNotebookLMTab() {
    if (_generatedItems != null) {
      // Review State
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '已生成 ${_generatedItems!.length} 个知识点',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
                  onPressed: () {
                    setState(() {
                      _generatedItems = null;
                      _isExtractingUrl = false;
                      _extractionResult = null;
                    });
                  },
                  tooltip: '重新开始',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _generatedItems!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _generatedItems![index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Color(0xFF3B82F6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.category,
                                style: const TextStyle(
                                    fontSize: 10, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.help_outline,
                                    size: 14, color: Color(0xFFF97316)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '提问: ${(item.pages.first as OfficialPage).flashcardQuestion ?? "自动生成中..."}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF9A3412),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                              ])
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _generatedItems = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      foregroundColor: const Color(0xFF64748B),
                    ),
                    child: const Text('返回修改'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('确认并保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // --- Main Layout: Inputs (Left) + Buttons (Right) ---
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // === LEFT COLUMN: Inputs & Info ===
                  Expanded(
                    child: Column(
                      children: [
                        // 1. File Input Box
                        InkWell(
                          onTap: () {
                            if (!_isParsing && !_isGenerating) _pickFile();
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _pickedFile != null
                                    ? const Color(
                                        0xFF10B981) // Green if file selected
                                    : const Color(0xFFE2E8F0),
                                width: _pickedFile != null ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _pickedFile != null
                                      ? Icons.description
                                      : Icons.upload_file,
                                  size: 32,
                                  color: _pickedFile != null
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _pickedFileName ?? '支持PDF, Word, Markdown',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _pickedFile != null
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFF94A3B8),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_pickedFile != null) ...[
                                  const SizedBox(height: 4),
                                  const Text('已选择 (点击更换)',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.grey)),
                                ]
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 2. Link Input Box
                        TextField(
                          controller: _urlController,
                          style: const TextStyle(
                              fontSize: 15, color: Color(0xFF334155)),
                          decoration: InputDecoration(
                            hintText: '支持大部分网页、YouTube等',
                            hintStyle:
                                const TextStyle(color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.link,
                                color: Color(0xFF64748B)),
                            suffixIcon: _urlController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _urlController.clear();
                                      setState(() => _urlError = null);
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 20),
                          ),
                          onChanged: (_) {
                            if (_pickedFile != null) {
                              // Clear picked file if user types url
                              setState(() {
                                _pickedFile = null;
                                _pickedFileName = null;
                                _extractionResult = null;
                              });
                            }
                            setState(() => _urlError = null);
                          },
                        ),

                        // 3. Status / Info Area (Result or Error)
                        if (_error != null || _urlError != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error ?? _urlError!,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (_extractionResult != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4), // Green 50
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Color(0xFF10B981), size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _extractionResult!.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF065F46)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(left: 36),
                                  child: Text(
                                    '包含 ${_extractionResult!.content.length} 字符 · 预计耗时 ${_calculateEstimatedTime(_extractionResult!.content.length)}',
                                    style: const TextStyle(
                                        color: Color(0xFF047857), fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  // === RIGHT COLUMN: Buttons ===
                  SizedBox(
                    width: 120,
                    child: Column(
                      children: [
                        // Parse Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (_isParsing || _isGenerating)
                                ? null
                                : _performParse,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF1F5F9),
                              foregroundColor: const Color(0xFF1E293B),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.zero,
                            ),
                            child: _isParsing
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.auto_fix_high, size: 20),
                                      SizedBox(height: 4),
                                      Text('解析',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // AI Generation Button - Expanded to fill height
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  (_extractionResult != null && !_isGenerating)
                                      ? _startGeneration
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E293B),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    const Color(0xFFE2E8F0),
                                disabledForegroundColor:
                                    const Color(0xFF94A3B8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isGenerating
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.auto_awesome, size: 28),
                                        SizedBox(height: 8),
                                        Text('AI 拆解',
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Coming Soon
            Column(
              children: [
                Text(
                  '即将支持 / Coming Soon',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[400],
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildComingSoonChip('小红书', Icons.camera_alt),
                    _buildComingSoonChip('知乎', Icons.question_answer),
                    _buildComingSoonChip('微信公众号', Icons.rss_feed),
                    _buildComingSoonChip('Bilibili', Icons.tv),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Renaming getter to match new logic variable name if needed, but we used _isExtractingUrl in state
  bool get _isParsing => _isExtractingUrl; // Helper getter

  String _calculateEstimatedTime(int length) {
    // 粗略估算：假设每 1000 字处理需要 5-8 秒 + 网络延迟
    // 简单公式：基础 3秒 + 每1000字 3秒
    final seconds = 3 + (length / 1000 * 3).round();
    if (seconds < 60) {
      return '$seconds 秒';
    } else {
      return '${(seconds / 60).toStringAsFixed(1)} 分钟';
    }
  }

  // New Minimal Chip for Coming Soon Sources
  Widget _buildComingSoonChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
