import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../feed/presentation/feed_provider.dart';
import '../../../models/feed_item.dart';
import 'srs_review_page.dart';

class VaultPage extends ConsumerStatefulWidget {
  const VaultPage({super.key});

  @override
  ConsumerState<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends ConsumerState<VaultPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Library Filter State
  FeedItemMastery? _libraryFilter;
  
  // Track reviewed items in current session (global provider)
  // Removed local Set<String> _reviewedInSession;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initial Load: Today's Session
    Future.microtask(() {
      final notifier = ref.read(feedProvider.notifier);
      if (ref.read(reviewSessionIdsProvider).isEmpty) {
        final ids = notifier.getDailyReviewIds();
        ref.read(reviewSessionIdsProvider.notifier).state = ids;
      }
      // Force refresh library on init too
      ref.read(libraryIdsProvider.notifier).state = notifier.getLibraryIds(filter: _libraryFilter);
    });

    _tabController.addListener(() {
      // Logic handled in build/listener below now
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateLibraryFilter(FeedItemMastery? filter) {
    setState(() {
      _libraryFilter = filter;
    });
    // Trigger update logic
    final notifier = ref.read(feedProvider.notifier);
    ref.read(libraryIdsProvider.notifier).state = notifier.getLibraryIds(filter: filter);
  }

  void _showLimitSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Daily Limit Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('How many cards do you want to review per day?'),
              const SizedBox(height: 24),
              Row(
                children: [
                   _LimitOption(5, ref),
                   const SizedBox(width: 12),
                   _LimitOption(10, ref),
                   const SizedBox(width: 12),
                   _LimitOption(20, ref),
                   const SizedBox(width: 12),
                   _LimitOption(50, ref),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to Feed Changes -> Auto Refresh Library
    ref.listen<List<FeedItem>>(feedProvider, (previous, next) {
       final notifier = ref.read(feedProvider.notifier);
       ref.read(libraryIdsProvider.notifier).state = notifier.getLibraryIds(filter: _libraryFilter);
    });

    final allItems = ref.watch(feedProvider);
    
    // Get items for current tab from their respective ID providers
    final sessionIds = ref.watch(reviewSessionIdsProvider);
    final libraryIds = ref.watch(libraryIdsProvider);
    
    final sessionItems = sessionIds
        .map((id) => allItems.firstWhere((i) => i.id == id, orElse: () => allItems.first))
        .toList();
    
    final libraryItems = libraryIds
        .map((id) => allItems.firstWhere((i) => i.id == id, orElse: () => allItems.first))
        .toList();

    final reviewedSet = ref.watch(reviewedSessionProvider);
    
    // Pending in today's session
    final pendingCount = sessionItems.where((i) => !reviewedSet.contains(i.id)).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA), // Teal-50
      appBar: AppBar(
        title: const Text('My Vault', style: TextStyle(color: Color(0xFF134E4A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '$pendingCount Pending',
                style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF134E4A)),
            onPressed: _showLimitSettings,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0D9488),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF0D9488),
          tabs: const [
            Tab(text: "Today's Review"),
            Tab(text: "Library (All)"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Today
          _buildSessionList(sessionItems, ref.read(feedProvider.notifier)),
          
          // Tab 2: Library
          Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: libraryItems.isEmpty 
                  ? const Center(child: Text('No items found')) 
                  : _buildList(libraryItems, isLibrary: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList(List<FeedItem> items, FeedNotifier notifier) {
    if (items.isEmpty) return _buildEmptyState();

    final now = DateTime.now();
    
    // Pending = 未复习的 + 到期的（排除session中已复习的）
    final reviewedSet = ref.watch(reviewedSessionProvider);
    final pendingCount = items.where((i) {
      if (reviewedSet.contains(i.id)) return false; // 已复习
      return true;
    }).length;
    
    // Sort: 已复习的排到后面，未复习的按到期时间排序
    final sortedItems = List.of(items);
    sortedItems.sort((a, b) {
      final aReviewed = reviewedSet.contains(a.id);
      final bReviewed = reviewedSet.contains(b.id);
      if (!aReviewed && bReviewed) return -1;
      if (aReviewed && !bReviewed) return 1;
      // Both unreviewed: sort by due time
      if (!aReviewed && !bReviewed) {
        final aDue = a.nextReviewTime != null && a.nextReviewTime!.isBefore(now);
        final bDue = b.nextReviewTime != null && b.nextReviewTime!.isBefore(now);
        if (aDue && !bDue) return -1;
        if (!aDue && bDue) return 1;
      }
      return 0;
    });

    final totalPoolDue = notifier.totalDueCount;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedItems.length + 1,
      itemBuilder: (context, index) {
        if (index == sortedItems.length) {
          if (pendingCount == 0 && totalPoolDue > 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ElevatedButton.icon(
                onPressed: () {
                  final newIds = notifier.getDailyReviewIds();
                  // Append or replace? Usually load more means adding to existing
                  ref.read(reviewSessionIdsProvider.notifier).update((state) => [...state, ...newIds]);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loaded next batch!')));
                },
                icon: const Icon(Icons.refresh),
                label: Text('Load Next Batch ($totalPoolDue remaining)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            );
          }
          return const SizedBox(height: 50);
        }
        final item = sortedItems[index];
        final isDone = reviewedSet.contains(item.id);
        return _ReviewCard(
          item: item,
          isLibrary: false,
          isDone: isDone,
          onReviewed: () {
            ref.read(reviewedSessionProvider.notifier).update((state) => {...state, item.id});
          },
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'All', 
            isSelected: _libraryFilter == null, 
            onTap: () => _updateLibraryFilter(null)
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Hard', 
            isSelected: _libraryFilter == FeedItemMastery.hard, 
            onTap: () => _updateLibraryFilter(FeedItemMastery.hard)
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Medium', 
            isSelected: _libraryFilter == FeedItemMastery.medium, 
            onTap: () => _updateLibraryFilter(FeedItemMastery.medium)
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Easy', 
            isSelected: _libraryFilter == FeedItemMastery.easy, 
            onTap: () => _updateLibraryFilter(FeedItemMastery.easy)
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final notifier = ref.read(feedProvider.notifier);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))
              ],
            ),
            child: const Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF2DD4BF)),
          ),
          const SizedBox(height: 24),
          const Text(
            '今日待复习已完成！',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF134E4A)),
          ),
          const SizedBox(height: 12),
          const Text(
            '想继续复习？加载所有收藏的题目',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // 1. Get the IDs from notifier
              final ids = notifier.getPracticeSessionIds();
              // 2. Update the dedicated provider
              ref.read(reviewSessionIdsProvider.notifier).state = ids;
              
              Future.microtask(() {
                if (ids.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📚 还没有收藏的知识点哦，先去学习流收藏一些内容吧！'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('💪 加载了 ${ids.length} 个题目供复习！'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              });
            },
            icon: const Icon(Icons.library_books),
            label: const Text('加载全部收藏'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildList(List<FeedItem> items, {required bool isLibrary}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _ReviewCard(item: item, isLibrary: isLibrary, isDone: false);
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final FeedItem item;
  final bool isLibrary;
  final bool isDone; // New flag
  final VoidCallback? onReviewed; // Callback when reviewed

  const _ReviewCard({
    required this.item, 
    required this.isLibrary,
    required this.isDone,
    this.onReviewed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => SRSReviewPage(item: item)),
        );
        // 返回后调用回调（如果有）
        onReviewed?.call();
      },
      child: Opacity(
        opacity: isDone ? 0.6 : 1.0, // Fade out if done
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDone ? Colors.grey[100] : Colors.white, // Grey bg if done
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDone ? [] : [
              BoxShadow(
                color: const Color(0xFF0D9488).withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFE0F2F1)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDone ? Colors.grey[300] : _getModuleColor(item.moduleId).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDone ? Icons.check : _getModuleIcon(item.moduleId), 
                  color: isDone ? Colors.grey : _getModuleColor(item.moduleId)
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDone ? Colors.grey[600] : const Color(0xFF1E293B),
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // 只有评级过的才显示 mastery badge
                        if (item.masteryLevel != FeedItemMastery.unknown)
                          _buildMasteryBadge(item.masteryLevel),
                        const Spacer(),
                        if (!isLibrary)
                           Text(
                            isDone ? 'Reviewed' : 'Due Today',
                            style: TextStyle(
                              fontSize: 12, 
                              color: isDone ? Colors.green : Colors.orange[800], 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMasteryBadge(FeedItemMastery level) {
    Color color;
    String text;
    switch(level) {
      case FeedItemMastery.hard: color = Colors.red; text = 'Hard'; break;
      case FeedItemMastery.medium: color = Colors.orange; text = 'Medium'; break;
      case FeedItemMastery.easy: color = Colors.green; text = 'Easy'; break;
      default: color = Colors.grey; text = 'New';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
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
  
  IconData _getModuleIcon(String moduleId) {
    switch (moduleId) {
      case 'A': return Icons.auto_awesome;
      case 'B': return Icons.lightbulb;
      case 'C': return Icons.science;
      case 'D': return Icons.gavel;
      default: return Icons.article;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D9488) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.bold,
              fontSize: 12
            ),
          ),
        ),
      ),
    );
  }
}

class _LimitOption extends StatelessWidget {
  final int value;
  final WidgetRef ref;

  const _LimitOption(this.value, this.ref);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final notifier = ref.read(feedProvider.notifier);
        notifier.setDailyLimit(value);
        // Refresh the session IDs in the dedicated provider
        ref.read(reviewSessionIdsProvider.notifier).state = notifier.getDailyReviewIds();
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Daily limit set to $value')));
      },
      child: CircleAvatar(
        radius: 25,
        backgroundColor: const Color(0xFF0D9488).withOpacity(0.1),
        child: Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
      ),
    );
  }
}
