import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/feed_item.dart';
import '../../feed/presentation/feed_provider.dart';
import '../../home/presentation/home_page.dart';
import '../../home/presentation/module_provider.dart';

class SearchResultsPage extends ConsumerStatefulWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  ConsumerState<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends ConsumerState<SearchResultsPage> {
  List<FeedItem> _searchResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  void _performSearch() {
    setState(() => _isLoading = true);

    // Get all items and search
    final allItems = ref.read(allItemsProvider);
    final query = widget.query.toLowerCase();

    final results = allItems.where((item) {
      final titleMatch = item.title.toLowerCase().contains(query);

      // Search in page content
      final contentMatch = item.pages.any((page) {
        if (page is OfficialPage) {
          return page.markdownContent.toLowerCase().contains(query) ||
              (page.flashcardQuestion?.toLowerCase().contains(query) ?? false);
        }
        return false;
      });

      return titleMatch || contentMatch;
    }).toList();

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  void _navigateToCard(FeedItem item) {
    print('🔍 [Search] Navigating to: ${item.title}');
    print('🔍 [Search] Module: ${item.moduleId}');

    // 1. Find the index of this item in its module
    final moduleItems = ref
        .read(allItemsProvider)
        .where((i) => i.moduleId == item.moduleId)
        .toList();
    final index = moduleItems.indexWhere((i) => i.id == item.id);

    print('🔍 [Search] Target index: $index of ${moduleItems.length} items');

    // 2. Set the active module FIRST
    ref.read(lastActiveModuleProvider.notifier).setActiveModule(item.moduleId);

    // 3. Set the initial index for feed (this takes priority in FeedPage)
    ref.read(feedInitialIndexProvider.notifier).state =
        FeedNavigationIntent(moduleId: item.moduleId, index: index);

    // 4. Switch to Learning tab (this will trigger FeedPage rebuild)
    ref.read(homeTabControlProvider.notifier).state = 1;

    // 5. Pop back to home
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '搜索: ${widget.query}',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? _buildEmptyState(isDark)
              : _buildResultsList(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              '没有找到相关内容',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '试试其他关键词吧',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '找到 ${_searchResults.length} 个结果',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _searchResults.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _searchResults[index];
              return _buildResultCard(item, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(FeedItem item, bool isDark) {
    final page = item.pages.first as OfficialPage;

    // Extract preview text
    String previewText = page.markdownContent.replaceAll('\n', ' ').trim();
    if (previewText.length > 100) {
      previewText = '${previewText.substring(0, 100)}...';
    }

    // Get mastery color
    Color masteryColor;
    IconData masteryIcon;
    switch (item.masteryLevel) {
      case FeedItemMastery.easy:
        masteryColor = Colors.green;
        masteryIcon = Icons.check_circle;
        break;
      case FeedItemMastery.medium:
        masteryColor = Colors.blue;
        masteryIcon = Icons.circle;
        break;
      case FeedItemMastery.hard:
        masteryColor = Colors.orange;
        masteryIcon = Icons.warning_amber_rounded;
        break;
      default:
        masteryColor = Colors.grey;
        masteryIcon = Icons.circle_outlined;
    }

    return GestureDetector(
      onTap: () => _navigateToCard(item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  masteryIcon,
                  color: masteryColor,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              previewText,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A65).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getModuleName(item.moduleId),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFFF8A65),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (item.isFavorited) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.favorite,
                    size: 16,
                    color: Colors.red,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getModuleName(String moduleId) {
    try {
      final modules = ref.read(moduleProvider);
      final allModules = [...modules.officials, ...modules.custom];
      final module = allModules.firstWhere((m) => m.id == moduleId);
      return module.title;
    } catch (e) {
      return moduleId;
    }
  }
}
