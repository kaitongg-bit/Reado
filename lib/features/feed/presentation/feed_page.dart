import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/feed_item.dart';
import '../../../models/feed_item.dart';
import '../../home/presentation/module_provider.dart';
import '../../lab/presentation/add_material_modal.dart';
import 'feed_provider.dart';
import 'widgets/feed_item_view.dart';

class FeedPage extends ConsumerStatefulWidget {
  final String moduleId; // e.g. "A" or "SEARCH"
  final String? searchQuery;

  const FeedPage({super.key, required this.moduleId, this.searchQuery});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  final PageController _verticalController = PageController();

  // View Mode: true = Single (Full Page), false = Grid (2 Columns)
  late bool _isSingleView;

  @override
  void initState() {
    super.initState();
    bool isSearch = widget.moduleId == 'SEARCH';

    // Default: Search -> Grid, Normal -> Single
    _isSingleView = !isSearch;

    if (isSearch && widget.searchQuery != null) {
      Future.microtask(() =>
          ref.read(feedProvider.notifier).searchItems(widget.searchQuery!));
    } else {
      Future.microtask(
          () => ref.read(feedProvider.notifier).loadModule(widget.moduleId));
    }
  }

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  int _focusedItemIndex = 0;

  @override
  @override
  Widget build(BuildContext context) {
    final feedItems = ref.watch(feedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final moduleState = ref.watch(moduleProvider);
    final currentModule =
        moduleState.all.where((m) => m.id == widget.moduleId).firstOrNull;

    final title = widget.moduleId == 'SEARCH'
        ? '搜索结果'
        : (currentModule?.title ?? 'Module ${widget.moduleId}');

    if (feedItems.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(title,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme:
              IconThemeData(color: isDark ? Colors.white : Colors.black87),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.moduleId == 'SEARCH'
                    ? '没有找到相关内容'
                    : 'Knowledge Space Empty',
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
                  label: const Text('Add Material'),
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
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
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
            bottom: -50,
            right: -50,
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
                                '${feedItems[_focusedItemIndex].readingTimeMinutes} min',
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
                        // Right: Grid Toggle
                        GestureDetector(
                          onTap: () => setState(() => _isSingleView = false),
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
                              '双列',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark ? Colors.white : Colors.black87),
                            ),
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

  Widget _buildSingleView(List<FeedItem> items) {
    return PageView.builder(
      controller: _verticalController,
      scrollDirection: Axis.vertical,
      itemCount: items.length,
      onPageChanged: (index) {
        setState(() {
          _focusedItemIndex = index;
        });
      },
      itemBuilder: (context, index) {
        final item = items[index];
        return FeedItemView(
          feedItem: item,
          onNextTap: () {
            _verticalController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        );
      },
    );
  }

  Widget _buildGridView(List<FeedItem> items, bool isDark) {
    return GridView.builder(
      padding:
          const EdgeInsets.fromLTRB(16, 16, 16, 100), // More bottom padding
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final previewText = _getPreviewText(item);

        // Glassmorphism Card Style
        final backgroundColor = isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.65);

        final borderColor = isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.5);

        return GestureDetector(
          onTap: () {
            setState(() {
              _isSingleView = true;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_verticalController.hasClients) {
                _verticalController.jumpToPage(index);
              }
            });
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Module Tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (item.moduleId == 'SEARCH')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getModuleColor(item.moduleId)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getModuleName(item.moduleId),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _getModuleColor(item.moduleId),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        const Spacer(),
                        if (item.isFavorited)
                          const Icon(Icons.favorite,
                              size: 16, color: Colors.redAccent)
                      ],
                    ),

                    if (item.moduleId == 'SEARCH') const SizedBox(height: 8),

                    // Title
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.2,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Preview Content
                    Expanded(
                      child: Text(
                        previewText,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            height: 1.4),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Footer
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color:
                                _getModuleColor(item.moduleId).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getModuleIcon(item.moduleId),
                              size: 10, color: _getModuleColor(item.moduleId)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'QuickPM',
                          style: TextStyle(
                              fontSize: 10,
                              color:
                                  isDark ? Colors.grey[500] : Colors.grey[500]),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
        return '未知模块';
    }
  }
}
