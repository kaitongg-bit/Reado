import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../feed/presentation/feed_provider.dart';
import '../../../models/feed_item.dart';
import '../../../models/knowledge_module.dart';
import 'module_provider.dart';
import 'home_page.dart'; // Import for homeTabControlProvider
import '../../lab/presentation/add_material_modal.dart';

class ModuleDetailPage extends ConsumerWidget {
  final String moduleId;

  const ModuleDetailPage({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moduleState = ref.watch(moduleProvider);
    final feedItems = ref.watch(allItemsProvider);

    // Find the module
    final module = [...moduleState.officials, ...moduleState.custom]
        .firstWhere((m) => m.id == moduleId,
            orElse: () => KnowledgeModule(
                  id: moduleId,
                  title: '未知知识库',
                  description: '',
                  ownerId: 'unknown',
                  isOfficial: false,
                ));

    // Get module items
    final moduleItems =
        feedItems.where((item) => item.moduleId == moduleId).toList();
    final cardCount = moduleItems.length;
    final learned = moduleItems
        .where((i) => i.masteryLevel != FeedItemMastery.unknown)
        .length;
    final progress = cardCount > 0 ? learned / cardCount : 0.0;

    // Get current progress for this module
    final currentProgress = ref.watch(feedProgressProvider);
    final currentModuleIndex = currentProgress[moduleId] ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // TODO: Implement share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('分享功能即将推出')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      // TODO: More options
                    },
                  ),
                ],
              ),
            ),

            // Module Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    module.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Tags
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildTag('$cardCount 张卡片', isDark),
                      _buildTag(module.isOfficial ? '官方' : '私有', isDark),
                      _buildTag('${(progress * 100).toInt()}% 已掌握', isDark),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // 1. Filter items for this module to find how many we have
                            final moduleItems = feedItems
                                .where((item) => item.moduleId == moduleId)
                                .toList();

                            // 2. Determine random starting index
                            int targetIndex = 0;
                            if (moduleItems.isNotEmpty) {
                              targetIndex =
                                  Random().nextInt(moduleItems.length);
                            }

                            // 3. Save active module
                            ref
                                .read(lastActiveModuleProvider.notifier)
                                .setActiveModule(moduleId);

                            // 4. Set progress to the random index
                            ref
                                .read(feedProgressProvider.notifier)
                                .setProgress(moduleId, targetIndex);

                            // 5. Switch to Feed tab via provider
                            ref.read(homeTabControlProvider.notifier).state = 1;

                            // 6. Pop back to HomePage
                            context.pop();
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('开始学习',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFCDFF64),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  AddMaterialModal(targetModuleId: moduleId),
                            );
                          },
                          icon: const Icon(Icons.add, color: Colors.black),
                          iconSize: 28,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Card List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: moduleItems.length,
                itemBuilder: (context, index) {
                  final item = moduleItems[index];
                  final isCurrentlyViewing = index == currentModuleIndex;
                  return _buildCompactCard(
                      context, item, index, isDark, ref, isCurrentlyViewing);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFCDFF64).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFCDFF64).withOpacity(0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFCDFF64) : const Color(0xFF7C9A00),
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, FeedItem item, int index,
      bool isDark, WidgetRef ref, bool isCurrentlyViewing) {
    // Get preview text
    String previewText = '';
    if (item.pages.isNotEmpty) {
      final firstPage = item.pages.first;
      if (firstPage is OfficialPage) {
        previewText = firstPage.markdownContent
            .replaceAll(RegExp(r'[#*\[\]`>]'), '')
            .replaceAll(RegExp(r'\n+'), ' ')
            .trim();
        if (previewText.length > 60) {
          previewText = '${previewText.substring(0, 60)}...';
        }
      }
    }

    return GestureDetector(
      onTap: () {
        // Save the active module and card index
        ref
            .read(lastActiveModuleProvider.notifier)
            .setActiveModule(item.moduleId);
        ref
            .read(feedProgressProvider.notifier)
            .setProgress(item.moduleId, index);

        // Switch HomePage tab to Feed (index 1)
        ref.read(homeTabControlProvider.notifier).state = 1;

        // Simply pop back to HomePage!
        context.pop();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrentlyViewing
              ? (isDark
                  ? const Color(0xFFCDFF64).withOpacity(0.1)
                  : const Color(0xFFCDFF64).withOpacity(0.05))
              : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentlyViewing
                ? const Color(0xFFCDFF64)
                : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2)),
            width: isCurrentlyViewing ? 2.0 : 1.0,
          ),
          boxShadow: isCurrentlyViewing
              ? [
                  BoxShadow(
                    color: const Color(0xFFCDFF64).withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            // Index
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isCurrentlyViewing
                    ? const Color(0xFFCDFF64)
                    : (item.masteryLevel != FeedItemMastery.unknown
                        ? const Color(0xFFCDFF64).withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2)),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCurrentlyViewing
                      ? (isDark ? Colors.black87 : const Color(0xFF7C9A00))
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isCurrentlyViewing
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (previewText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      previewText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Arrow
            Icon(
              isCurrentlyViewing
                  ? Icons.play_circle_filled
                  : Icons.chevron_right,
              color: isCurrentlyViewing
                  ? (isDark ? const Color(0xFFCDFF64) : const Color(0xFF7C9A00))
                  : (isDark ? Colors.grey[600] : Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
