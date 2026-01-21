import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../feed/presentation/feed_provider.dart';
import '../../../../models/feed_item.dart';
import '../../../lab/presentation/add_material_modal.dart';
import '../../../../core/theme/theme_provider.dart';

class HomeTab extends ConsumerWidget {
  final Function(String moduleId)? onLoadModule; // 加载模块的回调

  const HomeTab({super.key, this.onLoadModule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔥 使用 allItemsProvider 获取完整数据（不受 loadModule 影响）
    final feedItems = ref.watch(allItemsProvider);
    final hardcoreItems = feedItems.where((i) => i.moduleId == 'A').toList();
    final pmItems = feedItems
        .where((i) => i.moduleId == 'B')
        .toList(); // Assuming B is PM Foundation

    final hardcoreCount = hardcoreItems.length;
    final hardcoreLearned = hardcoreItems
        .where((i) => i.masteryLevel != FeedItemMastery.unknown)
        .length;
    final hardcoreProgress =
        hardcoreCount == 0 ? 0.0 : hardcoreLearned / hardcoreCount;

    final pmCount = pmItems.length;
    final pmLearned =
        pmItems.where((i) => i.masteryLevel != FeedItemMastery.unknown).length;
    final pmProgress = pmCount == 0 ? 0.0 : pmLearned / pmCount;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar: Title & Avatar Menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'QuickPM',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton(
                    offset: const Offset(0, 50),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey
                              : Colors.grey[300],
                      child: Icon(Icons.person,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87),
                    ),
                    itemBuilder: (context) => <PopupMenuEntry>[
                      PopupMenuItem(
                        child: ListTile(
                          leading: const Icon(Icons.person, size: 20),
                          title: const Text('个人主页'),
                          contentPadding: EdgeInsets.zero,
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('个人主页功能开发中...')));
                          },
                        ),
                      ),
                      PopupMenuItem(
                        child: ListTile(
                          leading: const Icon(Icons.settings, size: 20),
                          title: const Text('设置'),
                          contentPadding: EdgeInsets.zero,
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('设置功能开发中...')));
                          },
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        child: Consumer(
                          builder: (context, ref, _) {
                            final isDark =
                                ref.watch(themeProvider) != ThemeMode.light;
                            return ListTile(
                              leading: Icon(
                                  isDark ? Icons.light_mode : Icons.dark_mode,
                                  size: 20),
                              title: Text(isDark ? '浅色模式' : '深色模式'),
                              contentPadding: EdgeInsets.zero,
                              onTap: () {
                                ref.read(themeProvider.notifier).setTheme(
                                    isDark ? ThemeMode.light : ThemeMode.dark);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Search Bar
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search knowledge cards...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF333333)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF333333)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.orangeAccent),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    context.push('/search?q=$value');
                  }
                },
              ),
              const SizedBox(height: 32),

              // 初始化数据库按钮（显眼位置）
              if (pmCount == 0 && hardcoreCount == 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_download,
                          color: Colors.orangeAccent, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        '数据库为空',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '点击下方按钮初始化 30 个官方知识点',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.showSnackBar(const SnackBar(
                              content: Text('🔄 正在初始化数据库...'),
                              duration: Duration(seconds: 2),
                            ));

                            try {
                              await ref
                                  .read(feedProvider.notifier)
                                  .seedDatabase();
                              await ref
                                  .read(feedProvider.notifier)
                                  .loadAllData();

                              messenger.showSnackBar(const SnackBar(
                                content: Text('✅ 数据初始化成功！已导入 30 个知识点'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 3),
                              ));
                            } catch (e) {
                              messenger.showSnackBar(SnackBar(
                                content: Text('❌ 初始化失败: $e'),
                                backgroundColor: Colors.red,
                              ));
                            }
                          },
                          icon: const Icon(Icons.rocket_launch),
                          label: const Text('初始化数据库',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (pmCount == 0 && hardcoreCount == 0)
                const SizedBox(height: 24),

              // 3. Knowledge Spaces Section
              const Text(
                'Knowledge Spaces',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Knowledge Card: Product Manager (Module B)
              _KnowledgeSpaceCard(
                title: '产品经理基础',
                description: '从零开始学习产品经理核心技能',
                cardCount: pmCount,
                progress: pmProgress,
                color: const Color(0xFF252525),
                badgeText: 'Official',
                onLoad: () => onLoadModule?.call('B'),
              ),
              const SizedBox(height: 16),

              // Knowledge Card: Hardcore (Module A)
              _KnowledgeSpaceCard(
                title: '硬核基础',
                description: '计算机科学与编程基础知识',
                cardCount: hardcoreCount,
                progress: hardcoreProgress,
                color: const Color(0xFF252525),
                badgeText: 'Official',
                onLoad: () => onLoadModule?.call('A'),
              ),

              const SizedBox(height: 80), // Bottom padding for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddMaterialModal(),
          );
        },
        backgroundColor: const Color(0xFFFF8A65), // Coral color
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _KnowledgeSpaceCard extends StatelessWidget {
  final String title;
  final String description;
  final int cardCount;
  final double progress; // 0.0 to 1.0
  final Color color;
  final String badgeText;
  final VoidCallback? onLoad;

  const _KnowledgeSpaceCard({
    required this.title,
    required this.description,
    required this.cardCount,
    required this.progress,
    required this.color,
    required this.badgeText,
    this.onLoad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Progress Bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[800],
            color: const Color(0xFFFF8A65), // Coral
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 12),

          // Stats
          Text(
            '${(progress * 100).toInt()}% · $cardCount cards',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onLoad,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A65),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text('Load',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddMaterialModal(),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFF8A65)),
                    foregroundColor: const Color(0xFFFF8A65),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('+ Add Material',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
