import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../feed/presentation/widgets/feed_item_view.dart';
import '../../feed/presentation/feed_provider.dart';
import '../../../models/feed_item.dart';

class SRSReviewPage extends ConsumerStatefulWidget {
  final List<FeedItem> items;
  final int initialIndex;

  const SRSReviewPage({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<SRSReviewPage> createState() => _SRSReviewPageState();
}

class _SRSReviewPageState extends ConsumerState<SRSReviewPage> {
  late PageController _verticalController;
  late int _currentIndex;
  bool _isVerticalNavLocked = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _verticalController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  void _handleReview(
      FeedItem currentItem, int intervalDays, FeedItemMastery mastery) async {
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

    // 4. Feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '标记为 ${intervalDays == 0 ? "生疏" : (intervalDays == 1 ? "一般" : "熟练")}'),
          duration: const Duration(milliseconds: 500),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.9),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    // 5. Navigate to Next or Pop
    if (_currentIndex < widget.items.length - 1) {
      _verticalController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Optimized Ambient Background (Gradients are much cheaper than BoxShadows)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.2,
                  colors: [
                    (isDark ? const Color(0xFFFF8A65) : const Color(0xFFFFCCBC))
                        .withOpacity(isDark ? 0.08 : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomRight,
                  radius: 1.2,
                  colors: [
                    (isDark ? Colors.blueAccent : Colors.blue[100]!)
                        .withOpacity(isDark ? 0.05 : 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. The Content (Vertical PageView)
          Positioned.fill(
            bottom: 60,
            child: SafeArea(
              child: RepaintBoundary(
                child: PageView.builder(
                  physics:
                      const NeverScrollableScrollPhysics(), // 🔒 TikTok Mud style
                  controller: _verticalController,
                  scrollDirection: Axis.vertical,
                  itemCount: widget.items.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                      _isVerticalNavLocked = false;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    return _OverscrollNavigatable(
                      hasPrev: index > 0 && !_isVerticalNavLocked,
                      hasNext: index < widget.items.length - 1 &&
                          !_isVerticalNavLocked,
                      onTriggerPrev: () {
                        if (_isVerticalNavLocked) return;
                        _verticalController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      onTriggerNext: () {
                        if (_isVerticalNavLocked) return;
                        _verticalController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: Consumer(
                        builder: (context, ref, child) {
                          final currentItem = ref.watch(feedProvider.select(
                            (items) => items.firstWhere(
                              (i) => i.id == item.id,
                              orElse: () => item,
                            ),
                          ));
                          return FeedItemView(
                            feedItem: currentItem,
                            isReviewMode: true,
                            onViewModeChanged: (isNote) {
                              if (_isVerticalNavLocked != isNote) {
                                Future.microtask(() {
                                  if (mounted)
                                    setState(
                                        () => _isVerticalNavLocked = isNote);
                                });
                              }
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 3. Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: RepaintBoundary(
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
                            '复习 ${_currentIndex + 1}/${widget.items.length}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[700]),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.items[_currentIndex].readingTimeMinutes} 分钟',
                          style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. SRS Bottom Bar
          Positioned(
            bottom: 12,
            left: 50,
            right: 50,
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter:
                      ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Reduced blur
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E1E).withOpacity(0.75)
                          : Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Consumer(
                      builder: (context, ref, child) {
                        final item = widget.items[_currentIndex];
                        final currentItem = ref.watch(feedProvider.select(
                          (items) => items.firstWhere(
                            (i) => i.id == item.id,
                            orElse: () => item,
                          ),
                        ));
                        final currentMastery = currentItem.masteryLevel;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _SRSButton(
                              label: '生疏',
                              color: const Color(0xFFEF4444),
                              icon: Icons.refresh,
                              isDark: isDark,
                              isSelected:
                                  currentMastery == FeedItemMastery.hard,
                              onTap: () => _handleReview(
                                  currentItem, 0, FeedItemMastery.hard),
                            ),
                            _SRSButton(
                              label: '一般',
                              color: const Color(0xFFF59E0B),
                              icon: Icons.sentiment_neutral,
                              isDark: isDark,
                              isSelected:
                                  currentMastery == FeedItemMastery.medium,
                              onTap: () => _handleReview(
                                  currentItem, 1, FeedItemMastery.medium),
                            ),
                            _SRSButton(
                              label: '熟练',
                              color: const Color(0xFF10B981),
                              icon: Icons.check_circle,
                              isDark: isDark,
                              isSelected:
                                  currentMastery == FeedItemMastery.easy,
                              onTap: () => _handleReview(
                                  currentItem, 3, FeedItemMastery.easy),
                            ),
                          ],
                        );
                      },
                    ),
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
  final bool isSelected;

  const _SRSButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
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

// -----------------------------------------------------------------------------
// Overscroll Navigation Logic ("The Mud Effect") - Adapted from FeedPage
// -----------------------------------------------------------------------------

class _OverscrollNavigatable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTriggerPrev;
  final VoidCallback? onTriggerNext;
  final bool hasPrev;
  final bool hasNext;

  const _OverscrollNavigatable({
    required this.child,
    this.onTriggerPrev,
    this.onTriggerNext,
    this.hasPrev = false,
    this.hasNext = false,
  });

  @override
  State<_OverscrollNavigatable> createState() => _OverscrollNavigatableState();
}

class _OverscrollNavigatableState extends State<_OverscrollNavigatable>
    with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  late AnimationController _resetController;
  late Animation<Offset> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _resetController.addListener(() {
      setState(() {
        _dragOffset = _resetAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      if (notification.dragDetails != null) {
        if (notification.metrics.axis == Axis.vertical) {
          if (notification.metrics.extentBefore == 0 &&
              notification.scrollDelta! < 0) {
            if (widget.hasPrev) {
              _handleOverscroll(Offset(0, notification.scrollDelta!));
            }
          } else if (notification.metrics.extentAfter == 0 &&
              notification.scrollDelta! > 0) {
            if (widget.hasNext) {
              _handleOverscroll(Offset(0, notification.scrollDelta!));
            }
          }
        }
      }
    } else if (notification is OverscrollNotification) {
      if (notification.dragDetails != null) {
        if (notification.metrics.axis == Axis.vertical) {
          if (widget.hasPrev && notification.overscroll < 0) {
            _handleOverscroll(Offset(0, notification.overscroll));
          } else if (widget.hasNext && notification.overscroll > 0) {
            _handleOverscroll(Offset(0, notification.overscroll));
          }
        }
      }
    } else if (notification is ScrollEndNotification) {
      _handleDragEnd();
    }
  }

  void _handleOverscroll(Offset delta) {
    setState(() {
      double dampingY =
          0.8 * (1.0 - (_dragOffset.dy.abs() / 1500).clamp(0.0, 1.0));
      if (_dragOffset.dy < 0 || delta.dy > 0) dampingY = 1.0;
      _dragOffset = Offset(0, _dragOffset.dy - delta.dy * dampingY);
    });
    const threshold = 100.0;
    if ((_dragOffset.dy.abs() - threshold).abs() < 5) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleDragEnd() {
    final h = MediaQuery.of(context).size.height;
    final prevThreshold = h * 0.05;
    final nextThreshold = h * 0.015;

    if (_dragOffset.dy > prevThreshold && widget.hasPrev) {
      HapticFeedback.mediumImpact();
      widget.onTriggerPrev?.call();
    } else if (_dragOffset.dy.abs() > nextThreshold &&
        _dragOffset.dy < 0 &&
        widget.hasNext) {
      HapticFeedback.mediumImpact();
      widget.onTriggerNext?.call();
    }

    _resetAnimation =
        Tween<Offset>(begin: _dragOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
    );
    _resetController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final prevThreshold = h * 0.05;
    final nextThreshold = h * 0.015;

    double progress = 0.0;
    String? textAlert;
    IconData? icon;

    if (_dragOffset.dy > 0 && widget.hasPrev) {
      progress = (_dragOffset.dy.abs() / prevThreshold).clamp(0.0, 1.0);
      textAlert = progress >= 1.0 ? "释放切换到上一个" : "继续下拉";
      icon = Icons.arrow_upward;
    } else if (_dragOffset.dy < 0 && widget.hasNext) {
      progress = (_dragOffset.dy.abs() / nextThreshold).clamp(0.0, 1.0);
      textAlert = progress >= 1.0 ? "释放切换到下一个" : "继续上拉";
      icon = Icons.arrow_downward;
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _handleScrollNotification(notification);
        return false;
      },
      child: Stack(
        children: [
          Transform.translate(
            offset: _dragOffset,
            child: widget.child,
          ),
          if (_dragOffset.dy.abs() > 1 && textAlert != null && icon != null)
            Positioned(
              top: _dragOffset.dy > 0 ? 60 : null,
              bottom: _dragOffset.dy < 0 ? 60 : null,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: progress,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: progress >= 1.0
                            ? const Color(0xFF0D9488)
                            : Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(progress >= 1.0 ? Icons.check_circle : icon,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(textAlert,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
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
