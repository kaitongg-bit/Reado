import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/feed_item.dart';
import '../../../../core/services/content_generator_service.dart';
import '../../../../data/services/firestore_service.dart';
import '../../feed/presentation/feed_provider.dart';

class AddMaterialModal extends ConsumerStatefulWidget {
  final String? targetModuleId;
  const AddMaterialModal({super.key, this.targetModuleId});

  @override
  ConsumerState<AddMaterialModal> createState() => _AddMaterialModalState();
}

class _AddMaterialModalState extends ConsumerState<AddMaterialModal> {
  final TextEditingController _textController = TextEditingController();
  bool _isGenerating = false;
  List<FeedItem>? _generatedItems;
  String? _error;

  Future<void> _generate() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final generator = ref.read(contentGeneratorProvider);
      final newItems = await generator.generateFromText(_textController.text);

      // Override module ID immediately so preview is correct
      final correctedItems = newItems.map((item) {
        return widget.targetModuleId != null
            ? item.copyWith(moduleId: widget.targetModuleId!)
            : item;
      }).toList();

      if (!mounted) return;

      setState(() {
        _generatedItems = correctedItems;
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // Blue 50
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5),
              ],
            ),
            child: const Icon(Icons.auto_graph_outlined,
                size: 48, color: Color(0xFF3B82F6)),
          ),
          const SizedBox(height: 24),
          const Text(
            'NotebookLM 深度解析',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '上传 PDF、Word 文档或粘贴 Bilibili/YouTube 视频链接。\nAI 将自动构建知识图谱并生成深度问答。',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF64748B), height: 1.5, fontSize: 14),
            ),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildUploadButton(Icons.link, '粘贴链接', Colors.blue),
              const SizedBox(width: 20),
              _buildUploadButton(Icons.upload_file, '上传文件', Colors.indigo),
            ],
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF), // Purple 100
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD8B4FE)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.star_border, size: 16, color: Color(0xFF9333EA)),
              SizedBox(width: 8),
              Text(
                '即将推出',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9333EA)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {}, // Pending implementation
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.1), width: 2),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
