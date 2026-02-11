import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/providers/credit_provider.dart';
import '../../../feed/presentation/feed_provider.dart';
import '../../../../models/feed_item.dart';
import '../../../../models/knowledge_module.dart';
import '../module_provider.dart';
import '../../../lab/presentation/add_material_modal.dart';
import '../../../lab/presentation/widgets/tutorial_pulse.dart'; // Import TutorialPulseding_provider.dart';
import '../../../onboarding/providers/onboarding_provider.dart';

// Helper provider for the filter tab state
final _homeModuleFilterProvider = StateProvider.autoDispose<int>(
    (ref) => 0); // 0: Official, 1: Personal, 2: Recent

class HomeTab extends ConsumerWidget {
  final Function(String moduleId)? onLoadModule;

  final VoidCallback? onJumpToFeed;

  const HomeTab({super.key, this.onLoadModule, this.onJumpToFeed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filterIndex = ref.watch(_homeModuleFilterProvider);

    // Data Sources
    final feedItems = ref.watch(allItemsProvider);
    final moduleState = ref.watch(moduleProvider);

    // Filter Modules
    List<KnowledgeModule> displayedModules = [];
    if (filterIndex == 0) {
      // Official (A & B) + any other official ones
      // Use the 'isOfficial' flag if available, or fallback to defaults
      displayedModules = moduleState.officials;
    } else if (filterIndex == 1) {
      // Personal
      displayedModules = moduleState.custom;
    } else {
      // Recent - For now combine all
      displayedModules = [...moduleState.custom, ...moduleState.officials];
      // In a real app, we would sort by 'lastAccessTime' or similar.
      // For now, let's just reverse them to show something different or keep as is.
      // displayedModules = displayedModules.reversed.toList();
    }

    // Theme Colors
    final bgOrange = const Color(0xFFFFE0B2); // Background orange

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : bgOrange,
      body: Stack(
        children: [
          // 1. Top Orange Background
          Container(
            height:
                MediaQuery.of(context).size.height * 0.55, // Increased height
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFCC80),
            ),
          ),

          // 2. White Content Sheet
          Container(
            margin: const EdgeInsets.only(top: 220), // Pushed down
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(36)),
            ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(36)),
              child: Column(
                children: [
                  // Tabs Area (The "Calendar" replacement)
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _FilterTabItem(
                            label: '官方',
                            isSelected: filterIndex == 0,
                            onTap: () => ref
                                .read(_homeModuleFilterProvider.notifier)
                                .state = 0),
                        _FilterTabItem(
                            label: '个人',
                            isSelected: filterIndex == 1,
                            onTap: () => ref
                                .read(_homeModuleFilterProvider.notifier)
                                .state = 1),
                        _FilterTabItem(
                            label: '最近在学',
                            isSelected: filterIndex == 2,
                            onTap: () => ref
                                .read(_homeModuleFilterProvider.notifier)
                                .state = 2),
                      ],
                    ),
                  ),

                  // Module List
                  Expanded(
                    child: displayedModules.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  '这里空空如也',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            itemCount: displayedModules.length +
                                1, // Add space at bottom
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              if (index == displayedModules.length) {
                                return const SizedBox(
                                    height: 80); // Bottom padding
                              }

                              final module = displayedModules[index];
                              // Calculate progress
                              final mItems = feedItems
                                  .where((i) => i.moduleId == module.id)
                                  .toList();
                              final count = mItems.length;
                              final learned = mItems
                                  .where((i) =>
                                      i.masteryLevel != FeedItemMastery.unknown)
                                  .length;
                              final progress =
                                  count > 0 ? learned / count : 0.0;

                              // Highlight logic: First item in list gets the "Yellow" style
                              final isHighlighted = index == 0;

                              return _WideKnowledgeCard(
                                title: module.title,
                                description: module.description,
                                progress: progress,
                                cardCount: count,
                                isHighlighted: isHighlighted,
                                onTap: () {
                                  if (onLoadModule != null) {
                                    onLoadModule!(module.id);
                                  } else {
                                    context.push('/module/${module.id}');
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Header & Search Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Top Bar: Greeting + Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Greeting Column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${_getGreeting()}, ${_getUserName()}",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF5D4037),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          _buildSimpleQuote(isDark, feedItems.length),
                        ],
                      ),

                      // Right Actions
                      Row(
                        children: [
                          // Credits
                          Consumer(builder: (ctx, ref, _) {
                            final credits =
                                ref.watch(creditProvider).value?.credits ?? 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(children: [
                                Icon(Icons.stars,
                                    size: 16,
                                    color: isDark
                                        ? Colors.amber
                                        : const Color(0xFFE65100)),
                                const SizedBox(width: 4),
                                Text('$credits',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFFE65100))),
                              ]),
                            );
                          }),
                          const SizedBox(width: 12),
                          // Task Icon
                          Consumer(builder: (context, ref, child) {
                            final highlight = ref
                                .watch(onboardingProvider)
                                .highlightTaskCenter;
                            return TutorialPulse(
                              isActive: highlight,
                              child: GestureDetector(
                                onTap: () {
                                  // Clear highlight when clicked
                                  ref
                                      .read(onboardingProvider.notifier)
                                      .setHighlightTaskCenter(false);
                                  context.push('/task-center');
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.task_alt,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF3E2723),
                                      size: 20),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(width: 12),
                          // Avatar
                          GestureDetector(
                            onTap: () => context.push('/profile'),
                            child: _buildAvatar(),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Two Elegant Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ElegantMenuButton(
                          title: 'AI 拆解',
                          icon: Icons.auto_awesome,
                          color: const Color(0xFFFF5252), // Red Accent
                          bgColor: const Color(0xFFFFEBEE), // Pink/Red Light
                          onTap: () {
                            final onboardingState =
                                ref.read(onboardingProvider);
                            final shouldShowTutorial = !onboardingState
                                    .hasSeenDeconstructionTutorial ||
                                onboardingState.isAlwaysShowTutorial;

                            showDialog(
                              context: context,
                              builder: (context) => AddMaterialModal(
                                isTutorialMode: shouldShowTutorial,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ElegantMenuButton(
                          title: 'AI 笔记',
                          icon: Icons.menu_book,
                          color: const Color(0xFF1976D2), // Blue Accent
                          bgColor: const Color(0xFFE3F2FD), // Blue Light
                          onTap: () => onJumpToFeed?.call(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Search Row
                  Row(
                    children: [
                      // Search Bar
                      Expanded(
                        child: GestureDetector(
                          // In a real app, this might navigate to a specific search page or focus a field
                          onTap: () => context.push('/search'),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : const Color(0xFFFFF3E0), // Light beige
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Icon(Icons.search,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.orangeAccent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '搜索知识...',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Explore Button
                      _CircleActionButton(
                        icon: Icons.explore,
                        color: Colors.black87,
                        onTap: () => context.push('/explore'),
                      ),
                      const SizedBox(width: 8),

                      // Add Button (+)
                      _CircleActionButton(
                        icon: Icons.add,
                        color: Colors.black87,
                        isPrimary: true,
                        onTap: () => _showCreateModuleDialog(context, ref),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleQuote(bool isDark, int totalItems) {
    final quotes = [
      '今天学了吗？你这个囤囤鼠 🐹',
      '卷又卷不赢，躺又躺不平？那就学一点点吧 📖',
      '你的大脑正在渴望新的知识，快喂喂它 💡',
      '现在的努力，是为了以后能理直气壮地摸鱼 🐟',
      '碎片时间也是时间，哪怕入脑一个点也是赚到 ✨',
      '知识入脑带来的多巴胺，比短视频香多了 🧠',
      if (totalItems < 5) '💡 还没开始？点击下方导入官方卡片开启旅程吧',
    ];
    final index = DateTime.now().minute % quotes.length;

    return Text(
      quotes[index],
      style: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
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

  Widget _buildAvatar() {
    return Builder(
      builder: (context) {
        final user = FirebaseAuth.instance.currentUser;
        ImageProvider? imageProvider;
        if (user?.photoURL != null && user!.photoURL!.startsWith('assets/')) {
          imageProvider = AssetImage(user.photoURL!);
        } else {
          imageProvider =
              const AssetImage('assets/images/avatars/avatar_1.png');
        }
        return CircleAvatar(
          radius: 16,
          backgroundColor: Colors.transparent,
          backgroundImage: imageProvider,
        );
      },
    );
  }

  void _showCreateModuleDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

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

class _ElegantMenuButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ElegantMenuButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56, // Fixed comfortable height
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.8), // Glass-ish
          borderRadius: BorderRadius.circular(30), // Pill shape
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.white.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // Icon Circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF333333),
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTabItem(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFCC80) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.bold,
                fontSize: 15,
                color: isSelected
                    ? const Color(0xFF3E2723)
                    : (isDark ? Colors.grey : Colors.grey[400]),
              ),
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFE65100),
                shape: BoxShape.circle,
              ),
            )
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isPrimary;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.icon,
    required this.color,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFF1A237E)
              : (isDark ? Colors.white24 : Colors.white),
          shape: BoxShape.circle,
          boxShadow: [
            if (!isPrimary)
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(
          icon,
          color: isPrimary
              ? Colors.white
              : (isDark ? Colors.white : const Color(0xFF1A237E)),
          size: 24,
        ),
      ),
    );
  }
}

class _WideKnowledgeCard extends StatelessWidget {
  final String title;
  final String description;
  final double progress;
  final int cardCount;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _WideKnowledgeCard({
    required this.title,
    required this.description,
    required this.progress,
    required this.cardCount,
    this.isHighlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Highlight colors
    final bg = isHighlighted
        ? (isDark
            ? const Color(0xFF3E2723)
            : const Color(0xFFFFF3E0)) // Pale Yellow/Orange for highlight
        : (isDark ? Colors.white10 : Colors.white);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100, // Fixed height for consistency
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: isHighlighted
              ? null
              : Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            if (isHighlighted)
              BoxShadow(
                color: Colors.orange.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF2D2D2D),
                        ),
                      ),
                      if (isHighlighted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8A65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('RECENT',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '$cardCount items',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark ? Colors.white54 : const Color(0xFF8D6E63),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '·',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: isDark
                                ? Colors.white12
                                : const Color(0xFFEFEBE9),
                            color: const Color(0xFFFF8A65),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right Arrow or Icon
            Icon(Icons.arrow_forward_ios,
                size: 14, color: isDark ? Colors.white30 : Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
