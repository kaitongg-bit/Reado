import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/feed_item.dart';
import '../../../../core/services/content_generator_service.dart';
import '../../../../data/services/firestore_service.dart';
import '../../feed/presentation/feed_provider.dart';

/// Content Generator Provider
///
/// 使用 Gemini 2.0 Flash Developer API
final contentGeneratorProvider = Provider((ref) {
  // 从环境变量读取 API Key
  const apiKey = String.fromEnvironment('GEMINI_API_KEY');

  if (apiKey.isEmpty) {
    throw Exception('Gemini API Key 未配置\n\n'
        '请使用以下命令运行：\n'
        'flutter run --dart-define=GEMINI_API_KEY=你的Key');
  }

  return ContentGeneratorService(apiKey: apiKey);
});

class AddMaterialModal extends ConsumerStatefulWidget {
  const AddMaterialModal({super.key});

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
      final service = ref.read(contentGeneratorProvider);
      final items = await service.generateFromText(_textController.text);
      setState(() {
        _generatedItems = items;
      });
    } catch (e) {
      setState(() {
        _error = '生成失败，请重试。\n错误信息: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
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
        await service.saveCustomFeedItem(item, currentUser.uid);
      }

      // 同时添加到内存 Provider（用于即时显示）
      final currentItems = ref.read(feedProvider);
      ref.read(feedProvider.notifier).state = [
        ...currentItems,
        ..._generatedItems!
      ];

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
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generate,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                  label: Text(_isGenerating ? 'AI 正在拆解知识点...' : '生成知识卡片'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A65),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
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
