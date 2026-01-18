import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/mock_data.dart';
import '../../../models/feed_item.dart';

class FeedNotifier extends StateNotifier<List<FeedItem>> {
  // Source of Truth
  List<FeedItem> _allItems = MockData.initialFeedItems;

  FeedNotifier() : super([]); 

  /// 加载指定模块的数据 (Feed Logic)
  void loadModule(String moduleId) {
    state = _allItems.where((item) => item.moduleId == moduleId).toList();
  }

  /// 搜索逻辑
  void searchItems(String query) {
    if (query.isEmpty) {
      state = [];
      return;
    }
    state = _allItems.where((item) {
      return item.title.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
  
  int _dailyLimit = 10;

  void setDailyLimit(int limit) {
    _dailyLimit = limit;
    // Reload if currently in review mode? Let UI handle triggering reload.
  }

  /// 加载“所有”卡片 (Library Mode)，支持筛选
  void loadLibraryItems({FeedItemMastery? filter}) {
    if (filter == null) {
      state = List.from(_allItems);
    } else {
      state = _allItems.where((item) => item.masteryLevel == filter).toList();
    }
  }
  
  /// 每日复习算法 (The Smart SRS Session)
  /// 需求：随机抽 50% Complex, 30% Medium, 20% Easy/Simple
  void loadDailyReviewSession() {
    final now = DateTime.now();
    // 1. Get Pool of Due Items
    final dueItems = _allItems.where((item) {
      // 只要设定了 nextReviewTime 且时间到了，或者 Mastery 为 Hard (Forgot) 的也可以强制从池子里捞？
      // 暂时严格按时间:
      if (item.nextReviewTime == null) return false;
      return item.nextReviewTime!.isBefore(now);
    }).toList();

    // 2. Check Limit
    if (dueItems.length <= _dailyLimit) {
      state = dueItems; // 不够每天的量，就全复习
      return;
    }

    // 3. Weighted Selection
    final hardItems = dueItems.where((i) => i.masteryLevel == FeedItemMastery.hard).toList();
    final mediumItems = dueItems.where((i) => i.masteryLevel == FeedItemMastery.medium).toList();
    final easyItems = dueItems.where((i) => i.masteryLevel == FeedItemMastery.easy || i.masteryLevel == FeedItemMastery.unknown).toList();

    // Shuffle pools
    hardItems.shuffle();
    mediumItems.shuffle();
    easyItems.shuffle();

    // Calculate quotas
    final hardCount = (_dailyLimit * 0.5).ceil();
    final mediumCount = (_dailyLimit * 0.3).ceil();
    // remaining for easy
    final easyCount = _dailyLimit - hardCount - mediumCount; 

    List<FeedItem> session = [];
    
    // Fill Hard
    session.addAll(hardItems.take(hardCount));
    
    // Fill Medium
    session.addAll(mediumItems.take(mediumCount));
    
    // Fill Easy
    session.addAll(easyItems.take(easyCount));

    // If we are short (e.g. not enough Hard items), fill with remaining from other buckets
    if (session.length < _dailyLimit) {
      final remainingNeeded = _dailyLimit - session.length;
      final usedIds = session.map((e) => e.id).toSet();
      
      final others = dueItems.where((i) => !usedIds.contains(i.id)).toList();
      others.shuffle();
      session.addAll(others.take(remainingNeeded));
    }

    // Final shuffle
    session.shuffle();
    state = session;
  }

  /// 更新单个 Item (用于 SRS 算法更新 或 Pin 笔记)
  void updateItem(FeedItem newItem) {
    // 1. Update Source of Truth
    _allItems = [
      for (final item in _allItems)
        if (item.id == newItem.id) newItem else item
    ];

    // 2. Update View State (if the item is currently visible)
    state = [
      for (final item in state)
        if (item.id == newItem.id) newItem else item
    ];
  }

  /// Pin 笔记逻辑
  void pinNoteToItem(String itemId, String question, String answer) async {
    // Find item in _allItems
    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = _allItems[index];
    final newItem = item.copyWith(
      pages: [
        ...item.pages,
        UserNotePage(
          question: question,
          answer: answer,
          createdAt: DateTime.now(),
        )
      ],
    );

    updateItem(newItem);
  }
}

/// 全局 Feed Provider
final feedProvider = StateNotifierProvider<FeedNotifier, List<FeedItem>>((ref) {
  return FeedNotifier();
});
