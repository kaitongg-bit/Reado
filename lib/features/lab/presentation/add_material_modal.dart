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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '添加学习资料',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_generatedItems == null) ...[
              // Input State
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: '在此粘贴文章内容、笔记或网页文本...',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFFAFAFA),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _isGenerating ? null : _parseLocally,
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('直接/Markdown导入'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                        label: Text(_isGenerating ? 'AI 解析中...' : 'AI 智能拆解'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8A65),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Review State
              Text(
                'AI 已识别 ${_generatedItems!.length} 个知识点:',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _generatedItems!.length,
                  itemBuilder: (context, index) {
                    final item = _generatedItems![index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Text(item.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold))),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(item.difficulty,
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.blue)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (item.pages.first as OfficialPage).markdownContent,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.flash_on,
                                    size: 16, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Q: ${(item.pages.first as OfficialPage).flashcardQuestion ?? "N/A"}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          )
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
                          _generatedItems = null; // Back to edit
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('返回修改'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('保存加入知识库'),
                    ),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}
