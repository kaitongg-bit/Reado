import 'dart:ui';
import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../feed/presentation/feed_provider.dart';
import '../../../../models/feed_item.dart';
import '../module_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeTab extends ConsumerWidget {
  final Function(String moduleId)? onLoadModule; // 加载模块的回调

  const HomeTab({super.key, this.onLoadModule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFeedLoading = ref.watch(feedLoadingProvider);
    final moduleState = ref.watch(moduleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Loading State
    if (isFeedLoading || moduleState.isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFFF8A65)),
              const SizedBox(height: 16),
              Text(
                '正在准备知识库...',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Data Preparation
    final feedItems = ref.watch(allItemsProvider);

    // Calculate stats for Official Modules (Legacy A/B logic)
    final hardcoreItems = feedItems.where((i) => i.moduleId == 'A').toList();
    final pmItems = feedItems.where((i) => i.moduleId == 'B').toList();

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

    // 3. Main Content
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 0. Full Screen Background Gradient (Subtle)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1E1E1E),
                        const Color(0xFF121212),
                      ]
                    : [
                        const Color(0xFFFFF6F3), // Light warm tint top-left
                        const Color(0xFFF3F6FF), // Light cool tint bottom-right
                      ],
              ),
            ),
          ),

          // 1. Ambient Background - Top Left (Warmer/Orange)
          Positioned(
            top: -120,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8A65).withOpacity(
                        isDark ? 0.15 : 0.25), // Stronger visibility
                    blurRadius: 140,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),

          // 2. Ambient Background - Bottom Right (Cooler/Blue)
          Positioned(
            bottom: -50,
            right: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF64B5F6).withOpacity(
                        isDark ? 0.12 : 0.2), // Stronger visibility
                    blurRadius: 160,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Bar: Greeting & Avatar Menu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getUserName(),
                            style: TextStyle(
                              color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color ??
                                  (isDark ? Colors.white : Colors.black87),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: ClipOval(
                            child: FirebaseAuth
                                        .instance.currentUser?.photoURL !=
                                    null
                                ? Image.network(
                                    FirebaseAuth
                                        .instance.currentUser!.photoURL!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => CircleAvatar(
                                      backgroundColor: isDark
                                          ? Colors.grey[800]
                                          : Colors.grey[100],
                                      child: Icon(Icons.person,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87),
                                    ),
                                  )
                                : CircleAvatar(
                                    backgroundColor: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[100],
                                    child: Icon(Icons.person,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 2. Search Bar (Glassmorphism)
                  Container(
                    decoration: BoxDecoration(boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]),
                    child: TextField(
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: '搜索知识...',
                        hintStyle: TextStyle(
                            color:
                                isDark ? Colors.grey[500] : Colors.grey[400]),
                        prefixIcon: Icon(Icons.search,
                            color:
                                isDark ? Colors.grey[500] : Colors.grey[400]),
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.transparent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: Colors.orangeAccent, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          context.push('/search?q=$value');
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 初始化数据库按钮（显眼位置）
                  if (pmCount == 0 && hardcoreCount == 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.orangeAccent.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orangeAccent.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ]),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cloud_download_outlined,
                                color: Colors.orangeAccent, size: 32),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '初始化内容',
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '您的知识库是空的。点击下方加载 30+ 官方卡片。',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);

                                // Check if user is logged in (though official cards don't strictly require it,
                                // it's better for consistent state)
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) {
                                  messenger.showSnackBar(const SnackBar(
                                    content: Text('⚠️ 请先登录后再初始化内容'),
                                    backgroundColor: Colors.orange,
                                  ));
                                  return;
                                }

                                messenger.showSnackBar(const SnackBar(
                                  content: Text('🔄 正在从云端导入 30+ 知识卡片...'),
                                  duration: Duration(seconds: 2),
                                ));

                                try {
                                  await ref
                                      .read(feedProvider.notifier)
                                      .seedDatabase();

                                  // After seeding, trigger a refresh of the module progress as well
                                  await ref
                                      .read(moduleProvider.notifier)
                                      .refresh();

                                  if (context.mounted) {
                                    messenger.showSnackBar(const SnackBar(
                                      content: Text('✅ 数据初始化成功！已入脑 30+ 官方卡片'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 3),
                                    ));
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    print('❌ Seeding failed: $e');
                                    messenger.showSnackBar(SnackBar(
                                      content: Text('❌ 初始化失败: $e'),
                                      backgroundColor: Colors.red,
                                      action: SnackBarAction(
                                        label: '详情',
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('错误详情'),
                                              content: Text(e.toString()),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: const Text('好的'),
                                                )
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ));
                                  }
                                }
                              },
                              icon: const Icon(Icons.rocket_launch),
                              label: const Text('开始设置',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (pmCount == 0 && hardcoreCount == 0)
                    const SizedBox(height: 32),

                  // 3. Knowledge Spaces Section (Unified)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '我的知识库',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _showCreateModuleDialog(context, ref),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8A65).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      const Color(0xFFFF8A65).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: 16,
                                    color: const Color(0xFFFF8A65),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '新建',
                                    style: TextStyle(
                                      color: const Color(0xFFFF8A65),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => context.push('/explore'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      const Color(0xFF0D9488).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.explore_outlined,
                                    size: 16,
                                    color: const Color(0xFF0D9488),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '探索',
                                    style: TextStyle(
                                      color: const Color(0xFF0D9488),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(builder: (context, constraints) {
                    // Responsive: 2+ cards per row
                    final cardWidth = 160.0; // Smaller cards
                    final crossAxisCount =
                        (constraints.maxWidth ~/ (cardWidth + 16)).clamp(2, 4);

                    // Combine all modules
                    final allModules = [
                      ...moduleState.officials,
                      ...moduleState.custom,
                    ];

                    if (allModules.isEmpty) {
                      return GestureDetector(
                        onTap: () => _showCreateModuleDialog(context, ref),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[300]!,
                                style: BorderStyle.solid,
                              )),
                          child: Column(
                            children: [
                              Icon(Icons.add_circle_outline,
                                  size: 48,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                "创建你的第一个知识库",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: allModules.map((m) {
                        // Calculate stats
                        int count = 0;
                        double progress = 0.0;

                        if (m.id == 'A') {
                          count = hardcoreCount;
                          progress = hardcoreProgress;
                        } else if (m.id == 'B') {
                          count = pmCount;
                          progress = pmProgress;
                        } else {
                          final mItems = feedItems
                              .where((i) => i.moduleId == m.id)
                              .toList();
                          count = mItems.length;
                          final learned = mItems
                              .where((i) =>
                                  i.masteryLevel != FeedItemMastery.unknown)
                              .length;
                          progress = count > 0 ? learned / count : 0.0;
                        }
                        final mastered = (progress * count).toInt();

                        return SizedBox(
                          width: (constraints.maxWidth -
                                  16 * (crossAxisCount - 1)) /
                              crossAxisCount,
                          child: _KnowledgeSpaceCard(
                            moduleId: m.id,
                            title: m.title,
                            description: m.description,
                            cardCount: count,
                            masteredCount: mastered,
                            progress: progress,
                            color: Colors.transparent,
                            badgeText: m.isOfficial ? '官方' : '私有',
                            onLoad: () => onLoadModule?.call(m.id),
                          ),
                        );
                      }).toList(),
                    );
                  }),
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return '早上好';
    } else if (hour >= 12 && hour < 18) {
      return '下午好';
    } else if (hour >= 18 && hour < 22) {
      return '晚上好';
    } else {
      return '夜深了';
    }
  }

  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null &&
        user.displayName != null &&
        user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return 'kita'; // Default fallback
  }

  void _showCreateModuleDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController(); // Simple controller

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        title: const Text('创建知识库'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '例如：面试准备',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                hintText: '这个知识库是关于什么的？',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                Navigator.pop(context); // Close dialog
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    throw Exception('请先登录以创建您的专属知识库');
                  }

                  await ref.read(moduleProvider.notifier).createModule(
                        title,
                        descController.text.trim(),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✨ 知识库 "$title" 已准备就绪!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ 创建失败: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A65),
              foregroundColor: Colors.white,
            ),
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeSpaceCard extends StatelessWidget {
  final String moduleId; // Added moduleId
  final String title;
  final String description;
  final int cardCount;
  final int masteredCount;
  final double progress; // 0.0 to 1.0
  final Color color;
  final String badgeText;
  final VoidCallback? onLoad;

  const _KnowledgeSpaceCard({
    required this.moduleId,
    required this.title,
    required this.description,
    required this.cardCount,
    required this.masteredCount,
    required this.progress,
    required this.color,
    required this.badgeText,
    this.onLoad,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Simplified compact card
    return GestureDetector(
      onTap: () => context.push('/module/$moduleId'),
      child: Container(
        height: 140, // Fixed height for uniformity
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title and badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A65).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Color(0xFFFF8A65),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$cardCount 张卡片',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey[200],
                          color: const Color(0xFFFF8A65),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
