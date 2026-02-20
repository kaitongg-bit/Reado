import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/router/pending_login_return_path.dart';
import '../../../../core/widgets/save_error_dialog.dart';
import '../../../models/feed_item.dart';
import '../../../models/knowledge_module.dart';
import '../../home/presentation/module_provider.dart';
import '../../home/presentation/home_page.dart';
import 'feed_provider.dart';
import 'widgets/feed_item_view.dart';

/// 游客阅读分享知识库的只读 Feed：不写进度、不展示收藏/Pin/编辑
/// 布局与正常学习页一致：上下滑切换卡片，卡片内左右滑看笔记
class SharedFeedPage extends ConsumerWidget {
  final String moduleId;
  final String ownerId;
  final int? initialIndex;

  const SharedFeedPage({
    super.key,
    required this.moduleId,
    required this.ownerId,
    this.initialIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedAsync = ref.watch(sharedModuleProvider((ownerId, moduleId)));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 登录后回跳路径（仅路径，不含 origin，与 module_detail_page 一致，避免解析截断）
    final returnPath =
        '/module/$moduleId?ref=$ownerId&afterLogin=save';

    return sharedAsync.when(
      data: (shared) {
        final items = shared.items;
        if (items.isEmpty) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text('分享的知识库'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(child: Text('暂无卡片')),
          );
        }
        final startIndex = (initialIndex != null &&
                initialIndex! >= 0 &&
                initialIndex! < items.length)
            ? initialIndex!
            : 0;
        return _SharedFeedBody(
          moduleId: moduleId,
          ownerId: ownerId,
          items: items,
          initialIndex: startIndex,
          returnUrl: returnPath,
          isDark: isDark,
          module: shared.module,
          ref: ref,
        );
      },
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/onboarding'),
          ),
        ),
        body: Center(child: Text('加载失败：$e')),
      ),
    );
  }
}

class _SharedFeedBody extends StatefulWidget {
  final String moduleId;
  final String ownerId;
  final List<FeedItem> items;
  final int initialIndex;
  final String returnUrl;
  final bool isDark;
  final KnowledgeModule module;
  final WidgetRef ref;

  const _SharedFeedBody({
    required this.moduleId,
    required this.ownerId,
    required this.items,
    required this.initialIndex,
    required this.returnUrl,
    required this.isDark,
    required this.module,
    required this.ref,
  });

  @override
  State<_SharedFeedBody> createState() => _SharedFeedBodyState();
}

class _SharedFeedBodyState extends State<_SharedFeedBody> {
  late PageController _pageController;
  int _focusedItemIndex = 0;
  bool _isVerticalNavLocked = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _focusedItemIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveToMyLibrary(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      PendingLoginReturnPath.set(widget.returnUrl);
      context.go('/onboarding');
      return;
    }
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 20),
            const Text('正在保存到你的知识库…'),
          ],
        ),
      ),
    );
    try {
      if (widget.module.isOfficial) {
        widget.ref
            .read(lastActiveModuleProvider.notifier)
            .setActiveModule(widget.moduleId);
        widget.ref.read(homeTabControlProvider.notifier).state = 1;
        if (mounted) Navigator.of(context).pop();
        if (mounted) context.go('/');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('已加入学习，去首页开始吧'),
                behavior: SnackBarBehavior.floating),
          );
        }
      } else {
        final dataService = widget.ref.read(dataServiceProvider);
        final newId = await dataService.copySharedModuleToMine(
            widget.ownerId, widget.moduleId);
        if (!mounted) {
          Navigator.of(context).pop();
          return;
        }
        await widget.ref.read(moduleProvider.notifier).refresh();
        await widget.ref.read(feedProvider.notifier).loadAllData();
        widget.ref.read(feedProvider.notifier).loadModule(newId);
        await Future.delayed(const Duration(milliseconds: 80));
        if (!mounted) return;
        Navigator.of(context).pop();
        context.go('/module/$newId');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('已保存到你的知识库'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        showSaveToLibraryErrorDialog(context, error: e, onRetry: () {
          _handleSaveToMyLibrary(context);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('分享的知识库'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _handleSaveToMyLibrary(context),
            icon: const Icon(Icons.bookmark_add_outlined, size: 18),
            label: const Text('保存到我的知识库'),
          ),
        ],
      ),
      body: PageView.builder(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.items.length,
        onPageChanged: (index) {
          setState(() {
            _focusedItemIndex = index;
            _isVerticalNavLocked = false;
          });
        },
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return _SharedOverscrollWrapper(
            hasPrev: index > 0 && !_isVerticalNavLocked,
            hasNext: index < widget.items.length - 1 && !_isVerticalNavLocked,
            onTriggerPrev: () {
              if (_isVerticalNavLocked) return;
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
            },
            onTriggerNext: () {
              if (_isVerticalNavLocked) return;
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
            },
            child: FeedItemView(
              key: ValueKey(item.id),
              feedItem: item,
              isSharedReadOnly: true,
              onViewModeChanged: (isNote) {
                if (_isVerticalNavLocked != isNote) {
                  Future.microtask(() {
                    if (mounted) setState(() => _isVerticalNavLocked = isNote);
                  });
                }
              },
              onNextTap: () {
                if (_isVerticalNavLocked) return;
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// 仅处理上下 overscroll 切换卡片，与学习页一致（卡片内左右滑由 FeedItemView 处理）
class _SharedOverscrollWrapper extends StatefulWidget {
  final Widget child;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback? onTriggerPrev;
  final VoidCallback? onTriggerNext;

  const _SharedOverscrollWrapper({
    required this.child,
    required this.hasPrev,
    required this.hasNext,
    this.onTriggerPrev,
    this.onTriggerNext,
  });

  @override
  State<_SharedOverscrollWrapper> createState() =>
      _SharedOverscrollWrapperState();
}

class _SharedOverscrollWrapperState extends State<_SharedOverscrollWrapper> {
  Offset _dragOffset = Offset.zero;

  void _handleScrollNotification(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification ||
        notification.dragDetails == null) return;
    if (notification.metrics.axis != Axis.vertical) return;

    final delta = notification.scrollDelta ?? 0;
    if (notification.metrics.extentBefore == 0 && delta < 0 && widget.hasPrev) {
      setState(() => _dragOffset += Offset(0, -delta * 0.8));
    } else if (notification.metrics.extentAfter == 0 &&
        delta > 0 &&
        widget.hasNext) {
      setState(() => _dragOffset += Offset(0, -delta * 0.8));
    }
  }

  void _handleScrollEnd(ScrollNotification notification) {
    if (notification is! ScrollEndNotification) return;
    final h = MediaQuery.of(context).size.height;
    final prevThreshold = h * 0.05;
    final nextThreshold = h * 0.015;
    if (_dragOffset.dy > prevThreshold &&
        widget.hasPrev &&
        widget.onTriggerPrev != null) {
      widget.onTriggerPrev!();
    } else if (_dragOffset.dy < -nextThreshold &&
        widget.hasNext &&
        widget.onTriggerNext != null) {
      widget.onTriggerNext!();
    }
    setState(() => _dragOffset = Offset.zero);
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
      final isReady = _dragOffset.dy.abs() > prevThreshold;
      textAlert = isReady ? '释放切换到上一篇' : '继续下拉';
      icon = Icons.arrow_upward;
    } else if (_dragOffset.dy < 0 && widget.hasNext) {
      progress = (_dragOffset.dy.abs() / nextThreshold).clamp(0.0, 1.0);
      final isReady = _dragOffset.dy.abs() > nextThreshold;
      textAlert = isReady ? '释放进入下一篇' : '继续上拉';
      icon = Icons.arrow_downward;
    }
    final isReady = progress >= 1.0;

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        _handleScrollNotification(n);
        if (n is ScrollEndNotification) _handleScrollEnd(n);
        return false;
      },
      child: Stack(
        children: [
          Transform.translate(
            offset: _dragOffset,
            child: widget.child,
          ),
          if ((_dragOffset.dy.abs() > 1) &&
              textAlert != null &&
              icon != null)
            Positioned(
              top: _dragOffset.dy > 0 ? 60 : null,
              bottom: _dragOffset.dy < 0 ? 60 : null,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: progress,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    transform: Matrix4.identity()
                      ..scale(isReady ? 1.1 : 1.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isReady
                          ? const Color(0xFF0D9488)
                          : Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isReady
                              ? const Color(0xFF0D9488).withOpacity(0.4)
                              : Colors.black12,
                          blurRadius: isReady ? 12 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isReady ? Icons.check_circle : icon,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          textAlert!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
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
