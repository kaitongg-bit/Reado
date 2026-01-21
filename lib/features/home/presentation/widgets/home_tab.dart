import 'dart:ui';
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Ambient Background - Top Left (Review)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8A65)
                        .withOpacity(isDark ? 0.15 : 0.2), // Coral glow
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),

          // Ambient Background - Bottom Right (Review)
          Positioned(
            bottom: 50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(isDark ? 0.1 : 0.15),
                    blurRadius: 150,
                    spreadRadius: 40,
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
                  // 1. Top Bar: Title & Avatar Menu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'QuickPM',
                        style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color ??
                                  (isDark ? Colors.white : Colors.black87),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      PopupMenuButton(
                        offset: const Offset(0, 50),
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Container(
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
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                isDark ? Colors.grey[800] : Colors.grey[100],
                            child: Icon(Icons.person,
                                color: isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        // Explicitly typed to avoid List<StatefulWidget> error
                        itemBuilder: (context) => <PopupMenuEntry>[
                          PopupMenuItem(
                            child: ListTile(
                              leading:
                                  const Icon(Icons.person_outline, size: 22),
                              title: const Text('Profile'),
                              contentPadding: EdgeInsets.zero,
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/profile');
                              },
                            ),
                          ),
                          PopupMenuItem(
                            child: ListTile(
                              leading:
                                  const Icon(Icons.settings_outlined, size: 22),
                              title: const Text('Settings'),
                              contentPadding: EdgeInsets.zero,
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Settings coming soon...')));
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
                                      isDark
                                          ? Icons.light_mode_outlined
                                          : Icons.dark_mode_outlined,
                                      size: 22),
                                  title:
                                      Text(isDark ? 'Light Mode' : 'Dark Mode'),
                                  contentPadding: EdgeInsets.zero,
                                  onTap: () {
                                    ref.read(themeProvider.notifier).setTheme(
                                        isDark
                                            ? ThemeMode.light
                                            : ThemeMode.dark);
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
                        hintText: 'Search knowledge...',
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
                            'Initialize Content',
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your knowledge vault is empty. Tap below to load 30+ official cards.',
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
                              label: const Text('Start Setup',
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

                  // 3. Knowledge Spaces Section
                  Text(
                    'Knowledge Spaces',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Knowledge Card: Product Manager (Module B)
                  _KnowledgeSpaceCard(
                    title: 'Product Management',
                    description:
                        'Zero to Hero: Essential PM skills & frameworks',
                    cardCount: pmCount,
                    progress: pmProgress,
                    color: Colors.transparent, // Using glassmorphism now
                    badgeText: 'Official',
                    onLoad: () => onLoadModule?.call('B'),
                  ),
                  const SizedBox(height: 20),

                  // Knowledge Card: Hardcore (Module A)
                  _KnowledgeSpaceCard(
                    title: 'CS Fundamentals',
                    description: 'Data structures, algorithms & system design',
                    cardCount: hardcoreCount,
                    progress: hardcoreProgress,
                    color: Colors.transparent,
                    badgeText: 'Technical',
                    onLoad: () => onLoadModule?.call('A'),
                  ),

                  const SizedBox(height: 100), // Bottom padding for FAB
                ],
              ),
            ),
          ),
        ],
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
        elevation: 8,
        highlightElevation: 12,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Glassmorphism Styles
    final backgroundColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white
            .withOpacity(0.85); // High opacity for light mode legibility

    final borderColor =
        isDark ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.2);

    final shadowColor =
        isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.15);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24), // Softer corners
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // The "Glass" Effect
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color ??
                                  (isDark ? Colors.white : Colors.black87),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A65).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFFF8A65).withOpacity(0.3)),
                      ),
                      child: Text(
                        badgeText.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFFF8A65),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Progress Section
                Row(
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey[200],
                          color: const Color(0xFFFF8A65), // Coral
                          minHeight: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$cardCount cards mastered',
                  style: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: onLoad,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8A65),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 8,
                          shadowColor: const Color(0xFFFF8A65).withOpacity(0.5),
                        ),
                        child: const Text('Continue Learning',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const AddMaterialModal(),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.grey[300]!),
                          foregroundColor:
                              isDark ? Colors.white : Colors.black87,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Icon(Icons.add, size: 20),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
