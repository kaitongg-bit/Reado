import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../feed/presentation/widgets/feed_item_view.dart';
import '../../feed/presentation/feed_provider.dart';
import '../../../models/feed_item.dart';

class SRSReviewPage extends ConsumerWidget {
  final FeedItem item;

  const SRSReviewPage({super.key, required this.item});

  void _handleReview(BuildContext context, WidgetRef ref, int intervalDays, FeedItemMastery mastery) {
    // 1. Calculate new review time
    final now = DateTime.now();
    DateTime nextReview;
    
    if (intervalDays == 0) {
      // Forgot: 10 minutes later (simulated)
      nextReview = now.add(const Duration(minutes: 10));
    } else {
      nextReview = now.add(Duration(days: intervalDays));
    }

    // 2. Create updated item
    final updatedItem = item.copyWith(
      nextReviewTime: nextReview,
      intervalDays: intervalDays,
      masteryLevel: mastery,
    );


    // 3. Update Provider
    ref.read(feedProvider.notifier).updateItem(updatedItem);

    // 4. Feedback & Close
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked as ${intervalDays == 0 ? "Forgot" : (intervalDays == 1 ? "Hazy" : "Easy")}'),
        duration: const Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. The Content (Reuse FeedItemView)
          // We wrap it in a SafeArea to avoid overlap
          Positioned.fill(
            bottom: 100, // Leave space for SRS Bar
            child: FeedItemView(feedItem: item),
          ),
          
          // 2. Custom Back Button (since FeedItemView might hide AppBar)
          Positioned(
            top: 50,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.1),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // 3. SRS Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SRSButton(
                    label: 'Forgot', 
                    color: const Color(0xFFEF4444), 
                    icon: Icons.refresh,
                    onTap: () => _handleReview(context, ref, 0, FeedItemMastery.hard),
                  ),
                  _SRSButton(
                    label: 'Hazy', 
                    color: const Color(0xFFF59E0B), 
                    icon: Icons.sentiment_neutral,
                    onTap: () => _handleReview(context, ref, 1, FeedItemMastery.medium),
                  ),
                  _SRSButton(
                    label: 'Easy', 
                    color: const Color(0xFF10B981), 
                    icon: Icons.check_circle,
                    onTap: () => _handleReview(context, ref, 3, FeedItemMastery.easy),
                  ),
                ],
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

  const _SRSButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
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
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
