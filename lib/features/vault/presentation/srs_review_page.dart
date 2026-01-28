import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../feed/presentation/widgets/feed_item_view.dart';
import '../../feed/presentation/feed_provider.dart';
import '../../../models/feed_item.dart';

class SRSReviewPage extends ConsumerStatefulWidget {
  final FeedItem item;

  const SRSReviewPage({super.key, required this.item});

  @override
  ConsumerState<SRSReviewPage> createState() => _SRSReviewPageState();
}

class _SRSReviewPageState extends ConsumerState<SRSReviewPage> {
  void _handleReview(
      FeedItem currentItem, int intervalDays, FeedItemMastery mastery) {
    // 1. Calculate new review time
    final now = DateTime.now();
    DateTime nextReview;

    if (intervalDays == 0) {
      // Forgot: 10 minutes later (simulated)
      nextReview = now.add(const Duration(minutes: 10));
    } else {
      nextReview = now.add(Duration(days: intervalDays));
    }

    // 2. Create updated item (using currentItem to preserve favorite state)
    final updatedItem = currentItem.copyWith(
      nextReviewTime: nextReview,
      interval: intervalDays,
      masteryLevel: mastery,
    );

    // 3. Update Provider
    ref.read(feedProvider.notifier).updateItem(updatedItem);

    // ✅ 保存mastery到Firestore
    String masteryStr;
    switch (mastery) {
      case FeedItemMastery.hard:
        masteryStr = 'hard';
        break;
      case FeedItemMastery.medium:
        masteryStr = 'medium';
        break;
      case FeedItemMastery.easy:
        masteryStr = 'easy';
        break;
      default:
        masteryStr = 'unknown';
    }
    ref.read(feedProvider.notifier).updateMastery(currentItem.id, masteryStr);

    // 4. Feedback & Close
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '标记为 ${intervalDays == 0 ? "忘记" : (intervalDays == 1 ? "模糊" : "简单")}'),
        duration: const Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(feedProvider);
    final currentItem = items.firstWhere(
      (i) => i.id == widget.item.id,
      orElse: () => widget.item,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // We rely on Stack background but allow body to be transparent?
      // FeedItemView likely has its own background. We need to check that.
      // Assuming for now we put the cool background BEHIND everything.
      body: Stack(
        children: [
          // Ambient Background - Top Left
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8A65)
                        .withOpacity(isDark ? 0.15 : 0.2),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),

          // Ambient Background - Bottom Right
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
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

          // 1. The Content
          Positioned.fill(
            bottom: 100, // Leave space for SRS Bar
            child: SafeArea(
              child: FeedItemView(
                feedItem: currentItem,
                isReviewMode: true,
                // Note: FeedItemView needs to be transparent ideally,
                // IF it has a white/black background hardcoded, we might lose the effect.
              ),
            ),
          ),

          // 2. Custom Top Header (Glassmorphism)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  bottom: 10,
                  left: 16,
                  right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Icon(Icons.close,
                          size: 20,
                          color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),

                  // Info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '复习模式',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[700]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${currentItem.readingTimeMinutes} 分钟',
                        style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. SRS Bottom Bar (Glassmorphism Pannel)
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E1E).withOpacity(0.85)
                        : Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SRSButton(
                        label: '忘记',
                        color: const Color(0xFFEF4444),
                        icon: Icons.refresh,
                        isDark: isDark,
                        onTap: () =>
                            _handleReview(currentItem, 0, FeedItemMastery.hard),
                      ),
                      _SRSButton(
                        label: '模糊',
                        color: const Color(0xFFF59E0B),
                        icon: Icons.sentiment_neutral,
                        isDark: isDark,
                        onTap: () => _handleReview(
                            currentItem, 1, FeedItemMastery.medium),
                      ),
                      _SRSButton(
                        label: '简单',
                        color: const Color(0xFF10B981),
                        icon: Icons.check_circle,
                        isDark: isDark,
                        onTap: () =>
                            _handleReview(currentItem, 3, FeedItemMastery.easy),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SRSButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _SRSButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
