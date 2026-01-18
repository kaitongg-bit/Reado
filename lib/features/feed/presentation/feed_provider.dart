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
  /// 只显示已收藏的知识点
  void loadLibraryItems({FeedItemMastery? filter}) {
    // 先过滤出已收藏的
    final favoritedItems = _allItems.where((item) => item.isFavorited).toList();
    
    if (filter == null) {
      state = favoritedItems;
    } else {
      state = favoritedItems.where((item) => item.masteryLevel == filter).toList();
    }
  }
  
  /// 每日复习算法 (The Smart SRS Session)
  /// 需求：随机抽 50% Complex, 30% Medium, 20% Easy/Simple
  /// 仅包含已收藏的知识点
  void loadDailyReviewSession() {
    final now = DateTime.now();
    // 1. Get Pool of Due Items (只包含已收藏的)
    final dueItems = _allItems.where((item) {
      // 必须收藏过 + 设定了复习时间 + 时间到了
      if (!item.isFavorited) return false;
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

  /// 主动练习模式：加载一批已收藏的知识点（即使还没到复习时间）
  /// 用于用户想要额外复习的场景
  void loadPracticeSession() {
    final now = DateTime.now();
    
    // 获取所有已收藏的知识点，但排除今天已经复习过的
    // (nextReviewTime在未来 = 今天已复习过，设置了下次复习时间)
    final favoritedItems = _allItems.where((item) {
      if (!item.isFavorited) return false;
      // 允许：1) 没有复习时间的（新收藏） 2) 已经到期的
      if (item.nextReviewTime == null) return true;
      return item.nextReviewTime!.isBefore(now);
    }).toList();
    
    if (favoritedItems.isEmpty) {
      state = [];
      return;
    }

    // 如果已收藏的不够每日限额，就全部加载
    if (favoritedItems.length <= _dailyLimit) {
      favoritedItems.shuffle();
      state = favoritedItems;
      return;
    }

    // 按权重分配（类似每日复习）
    final hardItems = favoritedItems.where((i) => i.masteryLevel == FeedItemMastery.hard).toList();
    final mediumItems = favoritedItems.where((i) => i.masteryLevel == FeedItemMastery.medium).toList();
    final easyItems = favoritedItems.where((i) => i.masteryLevel == FeedItemMastery.easy || i.masteryLevel == FeedItemMastery.unknown).toList();

    hardItems.shuffle();
    mediumItems.shuffle();
    easyItems.shuffle();

    final hardCount = (_dailyLimit * 0.5).ceil();
    final mediumCount = (_dailyLimit * 0.3).ceil();
    final easyCount = _dailyLimit - hardCount - mediumCount;

    List<FeedItem> session = [];
    session.addAll(hardItems.take(hardCount));
    session.addAll(mediumItems.take(mediumCount));
    session.addAll(easyItems.take(easyCount));

    // 如果不够，从剩余中补充
    if (session.length < _dailyLimit) {
      final remainingNeeded = _dailyLimit - session.length;
      final usedIds = session.map((e) => e.id).toSet();
      final others = favoritedItems.where((i) => !usedIds.contains(i.id)).toList();
      others.shuffle();
      session.addAll(others.take(remainingNeeded));
    }

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

  /// 获取剩余待复习总数 (包括未加载到当前 Session 的，但只算已收藏的)
  int get totalDueCount {
    final now = DateTime.now();
    return _allItems.where((item) {
      return item.isFavorited && 
             item.nextReviewTime != null && 
             item.nextReviewTime!.isBefore(now);
    }).length;
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

  /// 收藏/取消收藏 (添加到复习池)
  void toggleFavorite(String itemId) {
    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = _allItems[index];
    final newFavoritedState = !item.isFavorited;
    
    final newItem = item.copyWith(
      isFavorited: newFavoritedState,
      // 收藏时设置初始复习时间为明天
      nextReviewTime: newFavoritedState ? DateTime.now().add(const Duration(days: 1)) : null,
      // 取消收藏时重置掌握程度
      masteryLevel: newFavoritedState ? item.masteryLevel : FeedItemMastery.unknown,
    );

    updateItem(newItem);
  }
}

/// 全局 Feed Provider
final feedProvider = StateNotifierProvider<FeedNotifier, List<FeedItem>>((ref) {
  return FeedNotifier();
});
