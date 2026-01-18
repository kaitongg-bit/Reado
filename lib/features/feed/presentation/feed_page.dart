import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/feed_item.dart';
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
        ref.read(feedProvider.notifier).searchItems(widget.searchQuery!)
      );
    } else {
      Future.microtask(() => 
        ref.read(feedProvider.notifier).loadModule(widget.moduleId)
      );
    }
  }

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedItems = ref.watch(feedProvider);

    if (feedItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.moduleId == 'SEARCH' ? '搜索结果' : 'Module ${widget.moduleId}')),
        body: const Center(child: Text('没有找到相关内容')),
      );
    }

    return Scaffold(
      backgroundColor: _isSingleView ? Colors.black : Colors.grey[100],
      appBar: _isSingleView ? null : AppBar(
        title: Text(widget.moduleId == 'SEARCH' ? '搜索结果' : '知识流'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_agenda_outlined),
            onPressed: () => setState(() => _isSingleView = true),
          ),
        ],
      ), 
      body: Stack(
        children: [
          // Content Area
          _isSingleView 
              ? _buildSingleView(feedItems)
              : _buildGridView(feedItems),

          // Floating Toggle (Only in Single View to allow switching back)
          if (_isSingleView)
            Positioned(
              top: 60,
              right: 20,
              child: FloatingActionButton.small(
                heroTag: 'view_toggle',
                backgroundColor: Colors.white.withOpacity(0.2),
                elevation: 0,
                child: const Icon(Icons.grid_view, color: Colors.white),
                onPressed: () => setState(() => _isSingleView = false),
              ),
            ),

          // Back Button (Only in Single View overlay, Grid has AppBar)
          if (_isSingleView)
            Positioned(
              top: 60,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
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
      itemBuilder: (context, index) {
        final item = items[index];
        return FeedItemView(feedItem: item);
      },
    );
  }

  Widget _buildGridView(List<FeedItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8, // Slightly squarer without the large image
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final previewText = _getPreviewText(item);

        return GestureDetector(
          onTap: () {
            // Click to enters Single View starting at this index
            setState(() {
              _isSingleView = true;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
               if (_verticalController.hasClients) {
                 _verticalController.jumpToPage(index);
               }
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Module Tag (Optional)
                if (item.moduleId == 'SEARCH')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getModuleColor(item.moduleId).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getModuleName(item.moduleId),
                        style: TextStyle(fontSize: 10, color: _getModuleColor(item.moduleId), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                // Title
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.3),
                ),
                const SizedBox(height: 8),

                // Preview Content
                Expanded(
                  child: Text(
                    previewText,
                    maxLines: 6, // Show more lines now
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Footer
                Row(
                  children: [
                    CircleAvatar(
                      radius: 8, 
                      backgroundColor: _getModuleColor(item.moduleId).withOpacity(0.2),
                      child: Icon(_getModuleIcon(item.moduleId), size: 10, color: _getModuleColor(item.moduleId)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'QuickPM', 
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                    const Spacer(),
                    Icon(
                      item.isFavorited ? Icons.favorite : Icons.favorite_border, 
                      size: 14, 
                      color: item.isFavorited ? Colors.redAccent : Colors.grey[400]
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  String _getPreviewText(FeedItem item) {
    // Try to find official content
    try {
      final content = item.pages.firstWhere(
        (p) => p is OfficialPage, 
        orElse: () => item.pages.first
      );
      
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
      case 'A': return Icons.auto_awesome;
      case 'B': return Icons.lightbulb;
      case 'C': return Icons.science;
      case 'D': return Icons.gavel;
      default: return Icons.article;
    }
  }

  Color _getModuleColor(String moduleId) {
    switch (moduleId) {
      case 'A': return Colors.blueAccent;
      case 'B': return Colors.orangeAccent;
      case 'C': return Colors.purpleAccent;
      case 'D': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  String _getModuleName(String moduleId) {
    switch (moduleId) {
      case 'A': return '硬核基础';
      case 'B': return '拆解案例';
      case 'C': return '全栈实操';
      case 'D': return '面经军火库';
      default: return '未知模块';
    }
  }
}
