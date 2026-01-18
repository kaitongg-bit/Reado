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
        childAspectRatio: 0.7, // Portrait cards
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            // Click to enters Single View starting at this index
            // Switch mode
            setState(() {
              _isSingleView = true;
            });
            // Jump to page after build
            WidgetsBinding.instance.addPostFrameCallback((_) {
               if (_verticalController.hasClients) {
                 _verticalController.jumpToPage(index);
               }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getModuleColor(item.moduleId).withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Center(
                      child: Icon(_getModuleIcon(item.moduleId), size: 40, color: _getModuleColor(item.moduleId)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getModuleColor(item.moduleId).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getModuleName(item.moduleId),
                              // 搜索模式下可以高亮 Tag
                              style: TextStyle(fontSize: 10, color: _getModuleColor(item.moduleId), fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Spacer(),
                          // 这里的爱心只是装饰，暂不联动 Provider
                          const Icon(Icons.favorite_border, size: 14, color: Colors.grey),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
