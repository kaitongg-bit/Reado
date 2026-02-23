import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../core/widgets/app_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/adhd_provider.dart';
import '../../../models/feed_item.dart';

import '../../home/presentation/module_provider.dart';
import '../../lab/presentation/add_material_modal.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../onboarding/presentation/widgets/tutorial_overlay.dart';
import 'feed_provider.dart';
import 'widgets/feed_item_view.dart';

class FeedPage extends ConsumerStatefulWidget {
  final String moduleId; // e.g. "A" or "SEARCH"
  final String? searchQuery;
  final int? initialIndex; // Optional: jump to specific item

  const FeedPage(
      {super.key, required this.moduleId, this.searchQuery, this.initialIndex});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  late PageController _verticalController;
  final GlobalKey _allCardsKey = GlobalKey();

  // View Mode: true = Single (Full Page), false = Grid (2 Columns)
  late bool _isSingleView;

  @override
  void initState() {
    super.initState();
    bool isSearch = widget.moduleId == 'SEARCH';

    // Handle special case: initialIndex = -1 means "jump to last item"
    // OR from global provider intent
    final intent = ref.read(feedInitialIndexProvider);
    final bool jumpToLast = widget.initialIndex ==
        -1; // || providerInitialIndex == -1; // Removed legacy int check

    // Priority: jumpToLast > widget.initialIndex > intent > savedProgress
    int savedIndex = 0;
    if (jumpToLast) {
      savedIndex = 0;
    } else if (widget.initialIndex != null && widget.initialIndex! >= 0) {
      savedIndex = widget.initialIndex!;
    } else if (intent != null &&
        intent.moduleId == widget.moduleId &&
        intent.index >= 0) {
      savedIndex = intent.index;
    } else {
      final progressMap = ref.read(feedProgressProvider);
      savedIndex = progressMap[widget.moduleId] ?? 0;
    }

    _focusedItemIndex = savedIndex;
    _verticalController = PageController(initialPage: savedIndex);

    // If we have an explicit starting index, mark position as "restored"
    // to prevent the progress provider from overriding it during build
    if (widget.initialIndex != null || intent != null) {
      _initialPositionRestored = true;
    }

    // Default: Search -> Grid, Normal -> Single
    _isSingleView = !isSearch;
    _bodyEditController = TextEditingController();

    if (isSearch && widget.searchQuery != null) {
      Future.microtask(() =>
          ref.read(feedProvider.notifier).searchItems(widget.searchQuery!));
    } else {
      Future.microtask(() {
        ref.read(feedProvider.notifier).loadModule(widget.moduleId);
        ref
            .read(lastActiveModuleProvider.notifier)
            .setActiveModule(widget.moduleId);
      });

      if (jumpToLast) {
        print('🚀 [JUMP TO LAST] Scheduled for: ${widget.moduleId}');
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          final items = ref.read(feedProvider);
          if (items.isNotEmpty) {
            final lastIndex = items.length - 1;
            print('🚀 [JUMP TO LAST] Executing at index $lastIndex');
            setState(() {
              _focusedItemIndex = lastIndex;
              _initialPositionRestored = true;
            });
            if (_verticalController.hasClients) {
              _verticalController.jumpToPage(lastIndex);
            }
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _bodyEditController.dispose();
    super.dispose();
  }

  int _focusedItemIndex = 0;
  bool _isEditingBody = false;
  late TextEditingController _bodyEditController;
  int? _editingPageIndex;
  bool _initialPositionRestored = false;

  void _tryRestorePosition(int itemCount) {
    if (_initialPositionRestored || !mounted) return;

    final intent = ref.read(feedInitialIndexProvider);

    // Special case: Jump to last (Not currently using intent logic, but keeping legacy check if needed or removed)
    // Legacy support for "Start Learning" usually sets tab index, not specific feed index

    // PRIORITY: Use intent if set (e.g., from search navigation) AND matches this module
    if (intent != null &&
        intent.moduleId == widget.moduleId &&
        intent.index >= 0) {
      print(
          '🔍 [FROM PROVIDER] Using intent for ${widget.moduleId}: ${intent.index}');
      if (intent.index < itemCount) {
        setState(() => _focusedItemIndex = intent.index);
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && _verticalController.hasClients) {
            _verticalController.jumpToPage(intent.index);
            print('✅ Jumped to provider index ${intent.index}');
          }
        });
        _initialPositionRestored = true;
      }
      return;
    }

    final progressMap = ref.read(feedProgressProvider);

    // If progressMap is completely empty, progress loading might not be complete yet
    // Wait for it to load (will be triggered by ref.listen when data arrives)
    if (progressMap.isEmpty) {
      // 1. Check if we have LOCAL data that hasn't been merged to provider yet
      // This is rare but possible if init happens super fast.
      // But feedProgressNotifier loads local immediately.
      // So if it's empty, it means truly no data or empty local.
      // We'll give it a retry mechanism or wait for listener.
      print('🔄 Progress map is empty, waiting for load...');
      return;
    }

    // Progress is loaded. Use saved value for this module, or 0 if never saved.
    final savedIndex = progressMap[widget.moduleId] ?? 0;
    print(
        '🎯 Restoring position for ${widget.moduleId}: $savedIndex (current: $_focusedItemIndex)');

    // Validate index is within bounds
    if (savedIndex >= 0 && savedIndex < itemCount) {
      // Only restore if we're NOT already at the correct position
      if (_focusedItemIndex != savedIndex) {
        print('🎯 Jumping to page $savedIndex');
        // IMPORTANT: Must update state so UI builds the right initial page
        setState(() => _focusedItemIndex = savedIndex);

        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && _verticalController.hasClients) {
            _verticalController.jumpToPage(savedIndex);
            print('✅ Position restored to $savedIndex');
          }
        });
      }
      _initialPositionRestored = true;
    } else if (itemCount > 0) {
      // 如果没有保存进度，或者进度越界，也视为已尝试恢复，防止反复跳转
      _initialPositionRestored = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedItems = ref.watch(feedProvider);
    final onboardingState = ref.watch(onboardingProvider);

    // 🎧 Listen for Auto-Jump triggers (Progress Update)
    ref.listen<Map<String, int>>(feedProgressProvider, (previous, next) {
      final newIndex = next[widget.moduleId];
      // Only jump if we have data and the view is ready
      if (newIndex != null &&
          feedItems.isNotEmpty &&
          newIndex < feedItems.length) {
        // 只有当索引确实发生变化且非当前页面时才强制跳转（处理多端同步）
        if (_focusedItemIndex != newIndex) {
          if (!_isSingleView) {
            setState(() {
              _isSingleView = true;
              _focusedItemIndex = newIndex;
            });
          } else {
            setState(() => _focusedItemIndex = newIndex);
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_verticalController.hasClients) {
              _verticalController.jumpToPage(newIndex);
            }
          });
        }
      }
    });

    // 🎧 Listen for Global Jump Intent (e.g. from Search)
    ref.listen<FeedNavigationIntent?>(feedInitialIndexProvider, (prev, next) {
      if (next != null &&
          next.moduleId == widget.moduleId &&
          feedItems.isNotEmpty) {
        int targetIndex = next.index;
        // if (targetIndex == -1) targetIndex = feedItems.length - 1; // Legacy

        if (targetIndex >= 0 && targetIndex < feedItems.length) {
          setState(() {
            _focusedItemIndex = targetIndex;
            _isSingleView = true;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_verticalController.hasClients) {
              _verticalController.jumpToPage(targetIndex);
            }
          });
        }
        // Consume intent AFTER processing successfully
        Future.microtask(() {
          // Careful: Only consume if it matches current module
          // Actually, since it's a global provider, consuming it is checking off "the" request.
          // If we consumed it, we assume we handled it.
          ref.read(feedInitialIndexProvider.notifier).state = null;
        });
      }
    });

    // 🎧 Listen for Data Load to apply pending progress (Data Update)
    ref.listen<List<FeedItem>>(feedProvider, (prev, next) {
      if (next.isNotEmpty && (prev == null || prev.isEmpty)) {
        // Data just arrived! Check if we have a saved position to restore.
        _tryRestorePosition(next.length);
      }
    });

    // 🔄 CRITICAL: Try to restore position on EVERY build until successful
    // This handles the case where progress loads AFTER data
    if (!_initialPositionRestored && feedItems.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryRestorePosition(feedItems.length);
      });
    }

    // 🛡️ Guard: Check for stale data from previous module to avoid index resets
    if (widget.moduleId != 'SEARCH' &&
        widget.moduleId != 'ALL' &&
        widget.moduleId != 'AI_NOTES' &&
        feedItems.isNotEmpty) {
      if (feedItems.first.moduleId != widget.moduleId) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: const Center(child: CircularProgressIndicator()),
        );
      }
    }

    if (feedItems.isNotEmpty && _isSingleView) {
      // Safety check: Ensure index is valid for current data
      if (_focusedItemIndex >= feedItems.length) {
        _focusedItemIndex = 0;
        _verticalController = PageController(initialPage: 0);
        // Update provider to 0 safely
        Future.microtask(() {
          ref
              .read(feedProgressProvider.notifier)
              .setProgress(widget.moduleId, 0);
        });
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final moduleState = ref.watch(moduleProvider);
    final currentModule =
        moduleState.all.where((m) => m.id == widget.moduleId).firstOrNull;

    if (feedItems.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.moduleId == 'SEARCH' ? '没有找到相关内容' : '知识库为空',
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              if (currentModule != null && !currentModule.isOfficial) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          AddMaterialModal(targetModuleId: widget.moduleId),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('添加内容'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A65),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ]
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _isSingleView
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                      color: (isDark ? Colors.black : Colors.white)
                          .withOpacity(0.5)),
                ),
              ),
              title: Text(
                widget.moduleId == 'ALL'
                    ? '全部知识'
                    : widget.moduleId == 'AI_NOTES'
                        ? 'AI 笔记'
                        : widget.moduleId == 'SEARCH'
                            ? '搜索结果'
                            : '知识模块',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              iconTheme:
                  IconThemeData(color: isDark ? Colors.white : Colors.black87),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton(
                    onPressed: () => setState(() => _isSingleView = true),
                    style: TextButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      '单列',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
      body: Stack(
        children: [
          // Global App Background
          const AppBackground(),

          // Content Area
          SafeArea(
            top: false, // Handle top padding manually in FeedItemView
            bottom: false,
            child: _isSingleView
                ? _buildSingleView(feedItems)
                : _buildGridView(feedItems, isDark),
          ),

          // Custom Top Header (Single View Only) - Z-INDEX: 50 (highest)
          if (_isSingleView && feedItems.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                // OPAQUE background (not transparent) following theme
                color: isDark ? const Color(0xFF121212) : Colors.white,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Info
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _getModuleColor(
                                          feedItems[_focusedItemIndex].moduleId)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: _getModuleColor(
                                              feedItems[_focusedItemIndex]
                                                  .moduleId)
                                          .withOpacity(0.4)),
                                ),
                                child: Text(
                                  _getModuleName(
                                      feedItems[_focusedItemIndex].moduleId),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _getModuleColor(
                                          feedItems[_focusedItemIndex]
                                              .moduleId)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${feedItems[_focusedItemIndex].readingTimeMinutes} 分钟',
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            if (_isEditingBody)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      final item =
                                          feedItems[_focusedItemIndex];
                                      final pageIndex = _editingPageIndex;
                                      if (pageIndex == null) return;
                                      try {
                                        await ref
                                            .read(feedProvider.notifier)
                                            .updateFeedItemPageContent(
                                                item.id,
                                                pageIndex,
                                                _bodyEditController.text);
                                        if (mounted) {
                                          setState(() {
                                            _isEditingBody = false;
                                            _editingPageIndex = null;
                                          });
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text('正文已保存')));
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      '保存失败: $e')));
                                        }
                                      }
                                    },
                                    child: const Text('保存'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditingBody = false;
                                        _editingPageIndex = null;
                                      });
                                    },
                                    child: const Text('取消'),
                                  ),
                                ],
                              )
                            else ...[
                              // Right: View All (back to detail page)
                              GestureDetector(
                                key: _allCardsKey,
                                onTap: () {
                                  if (onboardingState.isTutorialActive &&
                                      !onboardingState.hasSeenAllCardsPhase2 &&
                                      onboardingState.hasSeenAllCardsPhase1) {
                                    ref
                                        .read(onboardingProvider.notifier)
                                        .completeStep('all_cards_p2');
                                  }
                                  context.push('/module/${widget.moduleId}');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.15)
                                        : Colors.black.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.2)
                                          : Colors.black.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Text(
                                    '全部',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // More Options (Delete)
                              PopupMenuButton<String>(
                              icon: Icon(Icons.more_horiz,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54),
                              padding: EdgeInsets.zero,
                              onSelected: (value) async {
                                final item = feedItems[_focusedItemIndex];
                                if (value == 'edit_body') {
                                  final idx = item.pages
                                      .indexWhere((p) => p is OfficialPage);
                                  if (idx >= 0) {
                                    final page =
                                        item.pages[idx] as OfficialPage;
                                    _bodyEditController.text =
                                        page.markdownContent;
                                    setState(() {
                                      _editingPageIndex = idx;
                                      _isEditingBody = true;
                                    });
                                  }
                                  return;
                                }
                                if (value == 'move') {
                                  final modules = ref
                                      .read(moduleProvider)
                                      .custom
                                      .where((m) => m.id != widget.moduleId)
                                      .toList();
                                  if (modules.isEmpty) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  '请先创建其他知识库后再移动')));
                                    }
                                    return;
                                  }
                                  final target = await showDialog<String>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('移动到知识库'),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: modules
                                              .map((m) => ListTile(
                                                    title: Text(m.title),
                                                    subtitle: m.description
                                                        .isNotEmpty
                                                        ? Text(m.description,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis)
                                                        : null,
                                                    onTap: () =>
                                                        Navigator.pop(ctx, m.id),
                                                  ))
                                              .toList(),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx),
                                            child: const Text('取消')),
                                      ],
                                    ),
                                  );
                                  if (target != null && mounted) {
                                    await ref
                                        .read(feedProvider.notifier)
                                        .moveFeedItem(item.id, target);
                                    final bool isLast = _focusedItemIndex ==
                                        feedItems.length - 1;
                                    if (mounted && _isSingleView) {
                                      if (isLast && _focusedItemIndex > 0) {
                                        setState(() => _focusedItemIndex--);
                                        _verticalController
                                            .jumpToPage(_focusedItemIndex);
                                      } else {
                                        ref
                                            .read(feedProgressProvider.notifier)
                                            .setProgress(
                                                widget.moduleId,
                                                _focusedItemIndex);
                                      }
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('已移动到目标知识库')));
                                  }
                                  return;
                                }
                                if (value == 'delete' || value == 'hide') {
                                  final isHide = value == 'hide';
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title:
                                          Text(isHide ? '隐藏此知识卡？' : '彻底删除知识卡？'),
                                      content: Text(isHide
                                          ? '知识卡将被隐藏，您可以在“个人中心 - 隐藏的内容”中恢复。'
                                          : '警告：此操作不可逆！该知识卡将永久从云端移除。'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('取消'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text(isHide ? '隐藏' : '彻底删除',
                                              style: const TextStyle(
                                                  color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    final bool isLast = _focusedItemIndex ==
                                        feedItems.length - 1;

                                    if (isHide) {
                                      await ref
                                          .read(feedProvider.notifier)
                                          .hideFeedItem(item.id);
                                    } else {
                                      await ref
                                          .read(feedProvider.notifier)
                                          .deleteFeedItem(item.id);
                                    }

                                    // 🚀 CRITICAL: Handle auto-scroll / refresh UI immediately
                                    if (mounted && _isSingleView) {
                                      if (isLast && _focusedItemIndex > 0) {
                                        setState(() => _focusedItemIndex--);
                                        _verticalController
                                            .jumpToPage(_focusedItemIndex);
                                      } else {
                                        ref
                                            .read(feedProgressProvider.notifier)
                                            .setProgress(widget.moduleId,
                                                _focusedItemIndex);
                                      }
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              isHide ? '已隐藏知识卡' : '已移除知识卡')),
                                    );
                                  }
                                }
                              },
                              itemBuilder: (context) {
                                final isCustom = feedItems.isNotEmpty &&
                                    _focusedItemIndex < feedItems.length &&
                                    feedItems[_focusedItemIndex].isCustom;
                                final item = feedItems.isNotEmpty &&
                                        _focusedItemIndex < feedItems.length
                                    ? feedItems[_focusedItemIndex]
                                    : null;
                                final hasBodyPage = item != null &&
                                    item.pages
                                        .any((p) => p is OfficialPage);
                                final list = <PopupMenuItem<String>>[
                                  if (isCustom && hasBodyPage)
                                    const PopupMenuItem(
                                      value: 'edit_body',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_note,
                                              color: Colors.green, size: 20),
                                          SizedBox(width: 8),
                                          Text('编辑正文',
                                              style: TextStyle(
                                                  color: Colors.green)),
                                        ],
                                      ),
                                    ),
                                  if (isCustom)
                                    const PopupMenuItem(
                                      value: 'move',
                                      child: Row(
                                        children: [
                                          Icon(
                                              Icons.drive_file_move_outline,
                                              color: Colors.blue,
                                              size: 20),
                                          SizedBox(width: 8),
                                          Text('移动',
                                              style: TextStyle(color: Colors.blue)),
                                        ],
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'hide',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility_off_outlined,
                                            color: Colors.orange, size: 20),
                                        SizedBox(width: 8),
                                        Text('隐藏',
                                            style:
                                                TextStyle(color: Colors.orange)),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline,
                                            color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Text('永久删除',
                                            style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ];
                                return list;
                              },
                            ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (onboardingState.isTutorialActive &&
              onboardingState.hasSeenAllCardsPhase1 &&
              !onboardingState.hasSeenAllCardsPhase2)
            TutorialOverlay(
              targetKey: _allCardsKey,
              text: '如果要查看全部知识卡或者切换知识卡，就需要点击“全部”。',
              onDismiss: () {
                ref
                    .read(onboardingProvider.notifier)
                    .completeStep('all_cards_p2');
              },
            ),
        ],
      ),
    );
  }

  bool _isVerticalNavLocked = false;

  Widget _buildSingleView(List<FeedItem> items) {
    return PageView.builder(
      physics: const NeverScrollableScrollPhysics(), // 🔒 Disable default swipe
      controller: _verticalController,
      scrollDirection: Axis.vertical,
      itemCount: items.length,
      onPageChanged: (index) {
        setState(() {
          _focusedItemIndex = index;
          // Reset lock when changing items (failsafe, though view should reset it)
          _isVerticalNavLocked = false;
        });

        // 💾 Persist reading position per module
        ref
            .read(feedProgressProvider.notifier)
            .setProgress(widget.moduleId, index);

        // 🎓 Tutorial: Complete AI Notes step if they see b002
        final onboarding = ref.read(onboardingProvider);
        if (onboarding.isTutorialActive &&
            !onboarding.hasSeenAiNotesTutorial &&
            items[index].id == 'b002') {
          ref.read(onboardingProvider.notifier).completeStep('ai_notes');
        }
      },
      itemBuilder: (context, index) {
        final item = items[index];
        return _OverscrollNavigatable(
          hasPrev: index > 0 && !_isVerticalNavLocked,
          hasNext: index < items.length - 1 && !_isVerticalNavLocked,
          onTriggerPrev: () {
            if (_isVerticalNavLocked) return;
            _verticalController.previousPage(
              duration: const Duration(milliseconds: 300), // Faster transition
              curve: Curves.easeOutCubic,
            );
          },
          onTriggerNext: () {
            if (_isVerticalNavLocked) return;
            _verticalController.nextPage(
              duration: const Duration(milliseconds: 300), // Faster transition
              curve: Curves.easeOutCubic,
            );
          },
          onTriggerBack: () {
            // Allow back gesture even if locked?
            // Ideally yes, user might want to exit to grid.
            // But if "slide switching stuff" implies ALL slides, maybe.
            // Let's keep Back enabled as it's horizontal.
            setState(() {
              _isSingleView = false;
            });
          },
          child: FeedItemView(
            key: ValueKey(item.id),
            feedItem: item,
            isEditingBody: _isEditingBody && index == _focusedItemIndex,
            bodyEditController: _isEditingBody && index == _focusedItemIndex
                ? _bodyEditController
                : null,
            editingPageIndex: _isEditingBody && index == _focusedItemIndex
                ? _editingPageIndex
                : null,
            onViewModeChanged: (isNote) {
              // Defer state update to avoid build collisions
              if (_isVerticalNavLocked != isNote) {
                Future.microtask(() {
                  if (mounted) setState(() => _isVerticalNavLocked = isNote);
                });
              }
            },
            onNextTap: () {
              if (_isVerticalNavLocked) return;
              _verticalController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<FeedItem> items, bool isDark) {
    return Column(
      children: [
        // Search Bar at top
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            16,
            8,
          ),
          child: TextField(
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: '搜索当前知识库...',
              hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[400]),
              prefixIcon: Icon(Icons.search,
                  color: isDark ? Colors.grey[500] : Colors.grey[400]),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (value) {
              // TODO: Implement search functionality
              print('Searching for: $value');
            },
          ),
        ),
        // Grid View with Footer
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(feedProvider.notifier).refreshAll(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(), // 确保即使内容少也能触发下拉
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];
                        final previewText = _getPreviewText(item);
                        final isFocused = index == _focusedItemIndex;

                        final backgroundColor = isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.white.withOpacity(0.65);

                        final borderColor = isFocused
                            ? Colors.blueAccent
                            : (isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.5));

                        return GestureDetector(
                          onTap: () {
                            // 🚀 核心关键：标记已恢复状态，防止 build 中的自动恢复逻辑把用户“抓”回去
                            _initialPositionRestored = true;

                            ref
                                .read(feedProgressProvider.notifier)
                                .setProgress(widget.moduleId, index);

                            setState(() {
                              _focusedItemIndex = index;
                              _isSingleView = true;
                            });

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_verticalController.hasClients) {
                                _verticalController.jumpToPage(index);
                              }
                            });
                          },
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Builder(builder: (context) {
                                    final content = Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: kIsWeb
                                            ? (isDark
                                                ? Colors.black.withOpacity(0.8)
                                                : Colors.white
                                                    .withOpacity(0.95))
                                            : backgroundColor,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: borderColor,
                                            width: isFocused ? 2 : 1),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isDark
                                                ? Colors.black.withOpacity(0.2)
                                                : Colors.grey.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              if (item.moduleId == 'SEARCH')
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: _getModuleColor(
                                                            item.moduleId)
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    _getModuleName(
                                                        item.moduleId),
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color: _getModuleColor(
                                                            item.moduleId),
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                              const Spacer(),
                                              if (item.pages.length > 1)
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .only(right: 4),
                                                  child: Icon(
                                                    Icons.push_pin,
                                                    size: 14,
                                                    color: isDark
                                                        ? Colors.amber.shade300
                                                        : Colors.amber.shade700,
                                                  ),
                                                ),
                                              if (item.isFavorited)
                                                const Padding(
                                                  padding:
                                                      EdgeInsets.only(right: 4),
                                                  child: Icon(Icons.favorite,
                                                      size: 16,
                                                      color: Colors.redAccent),
                                                ),
                                              if (item.isCustom)
                                                SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      PopupMenuButton<String>(
                                                    padding: EdgeInsets.zero,
                                                    icon: Icon(Icons.more_horiz,
                                                        size: 16,
                                                        color: isDark
                                                            ? Colors.white70
                                                            : Colors.black54),
                                                    onSelected: (value) {
                                                      if (value == 'delete') {
                                                        _showDeleteDialog(item);
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      const PopupMenuItem(
                                                        value: 'delete',
                                                        height: 32,
                                                        child: Text('删除',
                                                            style: TextStyle(
                                                                fontSize: 13,
                                                                color: Colors
                                                                    .red)),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                            ],
                                          ),
                                          if (item.moduleId == 'SEARCH')
                                            const SizedBox(height: 8),
                                          Text(
                                            item.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              height: 1.2,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Expanded(
                                            child: Text(
                                              previewText,
                                              maxLines: 5,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? Colors.grey[400]
                                                      : Colors.grey[600],
                                                  height: 1.4),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: _getModuleColor(
                                                          item.moduleId)
                                                      .withOpacity(0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                    _getModuleIcon(
                                                        item.moduleId),
                                                    size: 10,
                                                    color: _getModuleColor(
                                                        item.moduleId)),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '抖书',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: isDark
                                                        ? Colors.grey[500]
                                                        : Colors.grey[500]),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    );

                                    return kIsWeb
                                        ? content
                                        : BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 15, sigmaY: 15),
                                            child: content,
                                          );
                                  }),
                                ),
                              ),
                              if (isFocused)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(0, 2))
                                      ],
                                    ),
                                    child: const Text("在看",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: Text(
                        'Reado 2026 Inc',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withOpacity(0.15)
                              : Colors.black.withOpacity(0.1),
                          fontSize: 12,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(FeedItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除知识卡片？'),
        content: const Text('删除后无法恢复，确定要删除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(feedProvider.notifier).deleteFeedItem(item.id);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getPreviewText(FeedItem item) {
    // Try to find official content
    try {
      final content = item.pages
          .firstWhere((p) => p is OfficialPage, orElse: () => item.pages.first);

      if (content is OfficialPage) {
        String text = content.markdownContent
            .replaceAll(RegExp(r'[#*\[\]`>]'), '') // Simple Markdown stripping
            .replaceAll(RegExp(r'\n+'), ' ')
            .trim();
        return text;
      } else if (content is UserNotePage) {
        return content.question;
      }
    } catch (e) {
      return '';
    }
    return '';
  }

  IconData _getModuleIcon(String moduleId) {
    switch (moduleId) {
      case 'A':
        return Icons.auto_awesome;
      case 'B':
        return Icons.lightbulb;
      case 'C':
        return Icons.science;
      case 'D':
        return Icons.gavel;
      default:
        return Icons.article;
    }
  }

  Color _getModuleColor(String moduleId) {
    switch (moduleId) {
      case 'A':
        return Colors.blueAccent;
      case 'B':
        return Colors.orangeAccent;
      case 'C':
        return Colors.purpleAccent;
      case 'D':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _getModuleName(String moduleId) {
    // 1. Try to find in loaded modules (Official + Custom)
    final allModules = ref.read(moduleProvider).all;
    final module = allModules.where((m) => m.id == moduleId).firstOrNull;
    if (module != null) return module.title;

    // 2. Fallback for hardcoded constants if not in list yet
    switch (moduleId) {
      case 'A':
        return '硬核基础';
      case 'B':
        return '拆解案例';
      case 'C':
        return '全栈实操';
      case 'D':
        return '面经军火库';
      default:
        return '知识库';
    }
  }
}

// -----------------------------------------------------------------------------
// Overscroll Navigation Logic ("The Mud Effect")
// -----------------------------------------------------------------------------

class _OverscrollNavigatable extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onTriggerPrev;
  final VoidCallback? onTriggerNext;
  final VoidCallback? onTriggerBack; // Trigger for "Back to Grid"
  final bool hasPrev;
  final bool hasNext;

  const _OverscrollNavigatable({
    required this.child,
    this.onTriggerPrev,
    this.onTriggerNext,
    this.onTriggerBack,
    this.hasPrev = false,
    this.hasNext = false,
  });

  @override
  ConsumerState<_OverscrollNavigatable> createState() =>
      _OverscrollNavigatableState();
}

class _OverscrollNavigatableState extends ConsumerState<_OverscrollNavigatable>
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

    // 🆕 ADHD First-Time Check
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _checkAndShowAdhdNotice(context);
    });
  }

  Future<void> _checkAndShowAdhdNotice(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('has_shown_adhd_notice') ?? false;

    if (!hasShown) {
      if (!mounted) return;

      // Ensure it's enabled
      final adhdState = ref.read(adhdSettingsProvider);
      if (adhdState.isEnabled) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber),
                SizedBox(width: 12),
                Text('已启用沉浸阅读模式'),
              ],
            ),
            content: const Text(
                '为了帮助提升阅读专注力，我们默认开启了 ADHD 辅助变色模式。\n\n如需关闭或调整，请点击页面右上角的设置。'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('知道了'),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to settings or toggle off directly
                  ref.read(adhdSettingsProvider.notifier).setEnabled(false);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('已关闭辅助模式')));
                },
                child: const Text('关闭'),
              ),
            ],
          ),
        );
        prefs.setBool('has_shown_adhd_notice', true);
      }
    }
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      if (notification.dragDetails != null) {
        // Vertical Logic
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
        // Horizontal Logic (Swipe Right to Back)
        // Check for Left Edge Pull (pixels <= 0) and Delta < 0 (moving finger right)
        if (notification.metrics.axis == Axis.horizontal) {
          if (notification.metrics.pixels <= 0 &&
              notification.scrollDelta! < 0) {
            _handleOverscroll(Offset(notification.scrollDelta!, 0));
          }
        }
      }
    } else if (notification is OverscrollNotification) {
      if (notification.dragDetails != null) {
        // Vertical
        if (notification.metrics.axis == Axis.vertical) {
          if (widget.hasPrev && notification.overscroll < 0) {
            _handleOverscroll(Offset(0, notification.overscroll));
          } else if (widget.hasNext && notification.overscroll > 0) {
            _handleOverscroll(Offset(0, notification.overscroll));
          }
        }
        // Horizontal (Left Override) -> Swipe Right (negative overscroll)
        if (notification.metrics.axis == Axis.horizontal) {
          // If we are at the first page (index 0) and trying to swipe right
          if (notification.overscroll < 0) {
            _handleOverscroll(Offset(notification.overscroll, 0));
          }
        }
      }
    } else if (notification is ScrollEndNotification) {
      _handleDragEnd();
    }
  }

  void _handleOverscroll(Offset delta) {
    setState(() {
      // Damping
      double dampingX = 1.0;
      double dampingY =
          0.8 * (1.0 - (_dragOffset.dy.abs() / 1500).clamp(0.0, 1.0));

      // 🔥 Pro adjustment: If pulling UP for Next (dy < 0), remove resistance
      // Make it linear (1.0) so it feels extremely light and responsive
      if (_dragOffset.dy < 0 || delta.dy > 0) {
        dampingY = 1.0;
      }

      // If we are dragging horizontal, we want 1:1 feel initially for "Back"
      if (delta.dx != 0) {
        dampingX = 1.0;
      }

      double newX = _dragOffset.dx - delta.dx * dampingX;
      double newY = _dragOffset.dy - delta.dy * dampingY;

      // Axis Lock: If we started vertical, stick to vertical. If horizontal, stick to horizontal.
      // Allow slight diagonal but prioritize dominant axis
      if (_dragOffset.dy.abs() > 5 && _dragOffset.dx.abs() < 20) newX = 0;
      if (_dragOffset.dx.abs() > 5 && _dragOffset.dy.abs() < 20) newY = 0;

      _dragOffset = Offset(newX, newY);
    });

    final threshold = 100.0;
    // Haptic
    if ((_dragOffset.distance - threshold).abs() < 5) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleDragEnd() {
    // Asymmetric thresholds (easier to go next)
    final h = MediaQuery.of(context).size.height;
    final prevThreshold = h * 0.05; // 5% for Prev
    final nextThreshold =
        h * 0.015; // 1.5% for Next (Extremely easy, almost instant)

    final backThreshold = MediaQuery.of(context).size.width * 0.25;

    bool triggered = false;

    // Vertical Trigger
    if (_dragOffset.dy > 0 && widget.hasPrev) {
      // Prev logic
      if (_dragOffset.dy.abs() > prevThreshold) {
        HapticFeedback.mediumImpact();
        if (widget.onTriggerPrev != null) widget.onTriggerPrev!();
        triggered = true;
      }
    } else if (_dragOffset.dy < 0 && widget.hasNext) {
      // Next logic
      if (_dragOffset.dy.abs() > nextThreshold) {
        HapticFeedback.mediumImpact();
        if (widget.onTriggerNext != null) widget.onTriggerNext!();
        triggered = true;
      }
    }

    // Horizontal Trigger (Back)
    if (!triggered && _dragOffset.dx > backThreshold) {
      HapticFeedback.mediumImpact();
      if (widget.onTriggerBack != null) {
        widget.onTriggerBack!();
      }
    }

    // Reset
    _resetAnimation =
        Tween<Offset>(begin: _dragOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
    );
    _resetController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    // Asymmetric thresholds for UI feedback too
    final h = MediaQuery.of(context).size.height;
    final prevThreshold = h * 0.05;
    final nextThreshold = h * 0.015;

    double progress = 0.0;
    String? textAlert;
    IconData? icon;

    // Determine UI State
    if (_dragOffset.dy > 0 && widget.hasPrev) {
      progress = (_dragOffset.dy.abs() / prevThreshold).clamp(0.0, 1.0);
      bool isReady = _dragOffset.dy.abs() > prevThreshold;
      textAlert = isReady ? "释放切换到上一篇" : "继续下拉";
      icon = Icons.arrow_upward;
    } else if (_dragOffset.dy < 0 && widget.hasNext) {
      progress = (_dragOffset.dy.abs() / nextThreshold).clamp(0.0, 1.0);
      bool isReady = _dragOffset.dy.abs() > nextThreshold;
      textAlert = isReady ? "释放进入下一篇" : "继续上拉";
      icon = Icons.arrow_downward;
    } else if (_dragOffset.dx > 0 && widget.onTriggerBack != null) {
      final backThreshold = MediaQuery.of(context).size.width * 0.25;
      progress = (_dragOffset.dx.abs() / backThreshold).clamp(0.0, 1.0);
      bool isReady = _dragOffset.dx.abs() > backThreshold;
      textAlert = isReady ? "释放返回列表" : "左滑返回";
      icon = Icons.grid_view;
    }

    // Is the action ready to be triggered?
    bool isReady = progress >= 1.0;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _handleScrollNotification(notification);
        return false; // Allow bubbling
      },
      child: Stack(
        children: [
          Transform.translate(
            offset: _dragOffset,
            child: widget.child,
          ),

          // Visual Indicators
          if ((_dragOffset.dx.abs() > 1 || _dragOffset.dy.abs() > 1) &&
              textAlert != null &&
              icon != null)
            Positioned(
              top: _dragOffset.dy > 0
                  ? 60
                  : (_dragOffset.dx > 0
                      ? MediaQuery.of(context).size.height / 2 - 20
                      : null),
              bottom: _dragOffset.dy < 0 ? 60 : null,
              left: _dragOffset.dx > 0 ? 20 : 0,
              right: _dragOffset.dx > 0 ? null : 0,
              child: Opacity(
                opacity: progress,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    transform: Matrix4.identity()
                      ..scale(isReady ? 1.1 : 1.0), // Pop effect
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: isReady
                            ? const Color(0xFF0D9488) // Teal when ready!
                            : Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: isReady
                                  ? const Color(0xFF0D9488).withOpacity(0.4)
                                  : Colors.black12,
                              blurRadius: isReady ? 12 : 4,
                              offset: const Offset(0, 2))
                        ]),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isReady ? Icons.check_circle : icon, // Icon change
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          textAlert,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
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
