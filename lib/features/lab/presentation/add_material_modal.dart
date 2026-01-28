import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  List<FeedItem>? _generatedItems;
  String? _error;
  String? _urlError;

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

  /// 从 URL 提取内容并生成知识卡片
  Future<void> _extractFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _urlError = '请输入 URL');
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() => _urlError = '请输入有效的 URL (以 http:// 或 https:// 开头)');
      return;
    }

    setState(() {
      _isExtractingUrl = true;
      _urlError = null;
    });

    try {
      final moduleId = widget.targetModuleId ?? 'custom';
      final newItems = await ContentExtractionService.processUrl(
        url,
        moduleId: moduleId,
      );

      if (!mounted) return;

      setState(() {
        _generatedItems = newItems;
        _isExtractingUrl = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _urlError = e.toString();
        _isExtractingUrl = false;
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
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                      fontSize: 16, height: 1.5, color: Color(0xFF334155)),
                  decoration: const InputDecoration(
                    hintText: '在此粘贴文章内容、笔记或网页文本...\nAI 将自动为您提取结构化知识点。',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                  ),
                ),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_generatedItems == null) ...[
            // Input State - URL Mode
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEFF6FF).withOpacity(0.8),
                    const Color(0xFFF3E8FF).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.link_rounded,
                        size: 36, color: Color(0xFF3B82F6)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '从 URL 提取内容',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '粘贴文章链接，AI 自动提取并生成知识卡片',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // URL Input
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _urlError != null
                      ? Colors.red.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: _urlController,
                style: const TextStyle(fontSize: 15, color: Color(0xFF334155)),
                decoration: InputDecoration(
                  hintText: 'https://example.com/article',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.link, color: Color(0xFF64748B)),
                  suffixIcon: _urlController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _urlController.clear();
                            setState(() => _urlError = null);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: (_) => setState(() => _urlError = null),
              ),
            ),

            if (_urlError != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _urlError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Extract Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExtractingUrl ? null : _extractFromUrl,
                icon: _isExtractingUrl
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isExtractingUrl ? '正在提取并生成...' : '提取并生成知识卡片'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            const Spacer(),

            // Supported Sources
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '支持的来源',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSourceChip('博客文章', Icons.article, true),
                      _buildSourceChip('新闻网站', Icons.newspaper, true),
                      _buildSourceChip('技术文档', Icons.description, true),
                      _buildSourceChip('YouTube', Icons.play_circle, false),
                      _buildSourceChip('PDF', Icons.picture_as_pdf, false),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Review State (共用，与文本导入一致)
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
                          child: Row(
                            children: [
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
                              ),
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
        ],
      ),
    );
  }

  Widget _buildSourceChip(String label, IconData icon, bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.white : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAvailable
              ? const Color(0xFF3B82F6).withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isAvailable ? const Color(0xFF3B82F6) : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isAvailable ? const Color(0xFF3B82F6) : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!isAvailable) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Soon',
                style: TextStyle(fontSize: 8, color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
