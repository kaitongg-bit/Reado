import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock_data.dart';
import '../../../models/feed_item.dart';

// Global provider to track reviewed items in the current session (persist across navigation)
final reviewedSessionProvider = StateProvider<Set<String>>((ref) => {});

// Provider for the active review session IDs (Today's Review)
final reviewSessionIdsProvider = StateProvider<List<String>>((ref) => []);

// Provider for the library item IDs
final libraryIdsProvider = StateProvider<List<String>>((ref) => []);

class FeedNotifier extends StateNotifier<List<FeedItem>> {
  // Source of Truth
  List<FeedItem> _allItems = MockData.initialFeedItems;
  
  List<FeedItem> get allItems => _allItems;


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

  /// 获取“所有”卡片 (Library Mode)，支持筛选
  List<String> getLibraryIds({FeedItemMastery? filter}) {
    final favoritedItems = _allItems.where((item) => item.isFavorited).toList();
    List<FeedItem> filtered;
    if (filter == null) {
      filtered = favoritedItems;
    } else {
      filtered = favoritedItems.where((item) => item.masteryLevel == filter).toList();
    }
    return filtered.map((e) => e.id).toList();
  }

  /// 加载“所有”卡片 (Library Mode)，支持筛选
  /// 只显示已收藏的知识点
  void loadLibraryItems({FeedItemMastery? filter}) {
    state = _allItems.where((item) => item.isFavorited && (filter == null || item.masteryLevel == filter)).toList();
  }
  
  /// 获取每日复习的 ID 列表
  List<String> getDailyReviewIds() {
    final now = DateTime.now();
    final dueItems = _allItems.where((item) {
      if (!item.isFavorited) return false;
      if (item.nextReviewTime == null) return false;
      return item.nextReviewTime!.isBefore(now);
    }).toList();

    if (dueItems.length <= _dailyLimit) {
      return dueItems.map((e) => e.id).toList();
    }

    final hardItems = dueItems.where((i) => i.masteryLevel == FeedItemMastery.hard).toList();
    final mediumItems = dueItems.where((i) => i.masteryLevel == FeedItemMastery.medium).toList();
    final easyItems = dueItems.where((i) => i.masteryLevel == FeedItemMastery.easy || i.masteryLevel == FeedItemMastery.unknown).toList();

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

    if (session.length < _dailyLimit) {
      final remainingNeeded = _dailyLimit - session.length;
      final usedIds = session.map((e) => e.id).toSet();
      final others = dueItems.where((i) => !usedIds.contains(i.id)).toList();
      others.shuffle();
      session.addAll(others.take(remainingNeeded));
    }

    session.shuffle();
    return session.map((e) => e.id).toList();
  }

  /// 获取主动练习模式的 ID 列表
  List<String> getPracticeSessionIds() {
    final favoritedItems = _allItems.where((item) => item.isFavorited).toList();
    if (favoritedItems.isEmpty) return [];

    if (favoritedItems.length <= _dailyLimit) {
      favoritedItems.shuffle();
      return favoritedItems.map((e) => e.id).toList();
    }

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

    if (session.length < _dailyLimit) {
      final remainingNeeded = _dailyLimit - session.length;
      final usedIds = session.map((e) => e.id).toSet();
      final others = favoritedItems.where((i) => !usedIds.contains(i.id)).toList();
      others.shuffle();
      session.addAll(others.take(remainingNeeded));
    }

    session.shuffle();
    return session.map((e) => e.id).toList();
  }

  /// 每日复习算法 (The Smart SRS Session)
  void loadDailyReviewSession() {
    state = _allItems.where((item) {
      if (!item.isFavorited) return false;
      if (item.nextReviewTime == null) return false;
      return item.nextReviewTime!.isBefore(DateTime.now());
    }).take(_dailyLimit).toList(); 
    // This is a simplified version for the 'state' which is used by other parts, 
    // but VaultPage will now use getDailyReviewIds().
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
