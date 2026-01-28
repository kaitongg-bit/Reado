import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/mock_data.dart';
import '../../../models/feed_item.dart';
import '../../../data/services/firestore_service.dart';
import '../../../core/services/content_generator_service.dart';

// Global provider to track reviewed items in the current session (persist across navigation)
final reviewedSessionProvider = StateProvider<Set<String>>((ref) => {});

// Provider for the active review session IDs (Today's Review)
final reviewSessionIdsProvider = StateProvider<List<String>>((ref) => []);

// Provider for the library item IDs
final libraryIdsProvider = StateProvider<List<String>>((ref) => []);

// Loading state for feed data
final feedLoadingProvider = StateProvider<bool>((ref) => true);

// Provider to persist the last focused item index PER MODULE
// Key: moduleId, Value: index
final feedProgressProvider = StateProvider<Map<String, int>>((ref) => {});

// DATA SOURCE PROVIDER
final dataServiceProvider = Provider<DataService>((ref) => FirestoreService());

// Content Generator Provider
final contentGeneratorProvider = Provider((ref) {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY');
  if (apiKey.isEmpty) {
    print('⚠️ Gemini API Key missing via --dart-define');
  }
  return ContentGeneratorService(apiKey: apiKey);
});

class FeedNotifier extends StateNotifier<List<FeedItem>> {
  final DataService _dataService;
  final Ref _ref;

  // Source of Truth
  List<FeedItem> _allItems = [];

  List<FeedItem> get allItems => _allItems;

  /// 获取当前用户ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  FeedNotifier(this._dataService, this._ref) : super([]) {
    // Trigger initial load
    loadAllData();
  }

  Future<void> loadAllData() async {
    print('🔄 开始加载所有数据...');
    _ref.read(feedLoadingProvider.notifier).state = true;

    try {
      // 1. 获取官方内容（从 feed_items 集合）
      final officialResults = await Future.wait([
        _dataService.fetchFeedItems('A'),
        _dataService.fetchFeedItems('B'),
        _dataService.fetchFeedItems('C'),
        _dataService.fetchFeedItems('D'),
      ]);

      final officialItems = officialResults.expand((x) => x).toList();
      print('✅ 官方内容: ${officialItems.length} 个');

      // 2. 获取用户自定义内容（从 users/{uid}/custom_items）
      final currentUser = FirebaseAuth.instance.currentUser;
      List<FeedItem> customItems = [];

      if (currentUser != null) {
        customItems = await _dataService.fetchCustomFeedItems(currentUser.uid);
        print('✅ 自定义内容: ${customItems.length} 个');
      } else {
        print('⚠️ 用户未登录，跳过自定义内容');
      }

      // 3. 合并所有内容
      _allItems = [...officialItems, ...customItems];
      print('📊 总计: ${_allItems.length} 个知识点');

      // 🔔 关键修复：强制更新 state 以通知 allItemsProvider
      // 即使 state 内容不变，重新赋值也会触发 notifyListeners
      state = [...state];
    } catch (e) {
      print('Basic load failed: $e');
    } finally {
      print('🏁 加载状态结束');
      _ref.read(feedLoadingProvider.notifier).state = false;
    }
  }

  /// 动态添加自定义内容 (用于 AddMaterialModal)
  void addCustomItems(List<FeedItem> newItems) {
    if (newItems.isEmpty) return;
    _allItems = [..._allItems, ...newItems];
    // 直接追加到当前视图 (假设当前就在该 Module)
    state = [...state, ...newItems];
  }

  /// 加载指定模块的数据 (Feed Logic)
  void loadModule(String moduleId) {
    if (_allItems.isEmpty) {
      // Retry logic if called too early
      loadAllData().then((_) {
        state = _allItems.where((item) => item.module == moduleId).toList();
      });
    } else {
      state = _allItems.where((item) => item.module == moduleId).toList();
    }
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
  int get dailyLimit => _dailyLimit;

  void updateDailyLimit(int limit) {
    _dailyLimit = limit;
  }

  // Alias
  void setDailyLimit(int limit) => updateDailyLimit(limit);

  /// 获取“所有”卡片 (Library Mode)，支持筛选
  List<String> getLibraryIds({FeedItemMastery? filter}) {
    final favoritedItems = _allItems.where((item) => item.isFavorited).toList();
    List<FeedItem> filtered;
    if (filter == null) {
      filtered = favoritedItems;
    } else {
      filtered =
          favoritedItems.where((item) => item.masteryLevel == filter).toList();
    }
    return filtered.map((e) => e.id).toList();
  }

  /// 加载“所有”卡片 (Library Mode)，支持筛选
  void loadLibraryItems({FeedItemMastery? filter}) {
    state = _allItems
        .where((item) =>
            item.isFavorited && (filter == null || item.masteryLevel == filter))
        .toList();
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

    final hardItems =
        dueItems.where((i) => i.masteryLevel == FeedItemMastery.hard).toList();
    final mediumItems = dueItems
        .where((i) => i.masteryLevel == FeedItemMastery.medium)
        .toList();
    final easyItems = dueItems
        .where((i) =>
            i.masteryLevel == FeedItemMastery.easy ||
            i.masteryLevel == FeedItemMastery.unknown)
        .toList();

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

    return session.map((e) => e.id).toList();
  }

  // Practice Session
  List<String> getPracticeSessionIds() {
    return getDailyReviewIds(); // Reuse for simplicity or implement shuffle logic
  }

  // --- Actions ---

  Future<void> toggleFavorite(String itemId) async {
    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      final oldItem = _allItems[index];
      final newItem = oldItem.copyWith(
        isFavorited: !oldItem.isFavorited,
        nextReviewTime: !oldItem.isFavorited
            ? DateTime.now().add(const Duration(days: 1))
            : null,
      );

      updateItem(newItem);

      await _dataService.toggleFavorite(itemId, newItem.isFavorited);
    }
  }

  Future<void> updateMastery(String itemId, String levelStr) async {
    FeedItemMastery level;
    if (levelStr == 'hard')
      level = FeedItemMastery.hard;
    else if (levelStr == 'medium')
      level = FeedItemMastery.medium;
    else if (levelStr == 'easy')
      level = FeedItemMastery.easy;
    else
      level = FeedItemMastery.unknown;

    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      final oldItem = _allItems[index];
      final newItem = oldItem.copyWith(masteryLevel: level);

      updateItem(newItem);

      // ✅ 修复：保存mastery到Firestore
      await _dataService.updateMasteryLevel(itemId, levelStr);
    }
  }

  void updateItem(FeedItem newItem) {
    _allItems = [
      for (final item in _allItems)
        if (item.id == newItem.id) newItem else item
    ];
    state = [
      for (final item in state)
        if (item.id == newItem.id) newItem else item
    ];
  }

  void pinNoteToItem(String itemId, String question, String answer) async {
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
    await _dataService.saveUserNote(itemId, question, answer);
  }

  void deleteUserNote(String itemId, UserNotePage note) {
    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = _allItems[index];
    final newPages = List<CardPageContent>.from(item.pages)..remove(note);

    final newItem = item.copyWith(pages: newPages);
    updateItem(newItem);
    // TODO: Implement backend delete persistence
    // _dataService.deleteNote(...)
  }

  void updateUserNote(
      String itemId, UserNotePage oldNote, String newQ, String newA) {
    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = _allItems[index];
    final newPages = item.pages.map((p) {
      if (p == oldNote) {
        return UserNotePage(
          question: newQ,
          answer: newA,
          createdAt: (p as UserNotePage).createdAt,
        );
      }
      return p;
    }).toList();

    final newItem = item.copyWith(pages: newPages);
    updateItem(newItem);
    // TODO: Implement backend update persistence
  }

  int get totalDueCount {
    final now = DateTime.now();
    return _allItems.where((item) {
      return item.isFavorited &&
          item.nextReviewTime != null &&
          item.nextReviewTime!.isBefore(now);
    }).length;
  }

  // Seeding
  Future<void> seedDatabase() async {
    print("Seeding DB...");
    await _dataService.seedInitialData(MockData.initialFeedItems);
    await loadAllData();
    print("Done.");
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, List<FeedItem>>((ref) {
  final dataService = ref.watch(dataServiceProvider);
  return FeedNotifier(dataService, ref);
});

// 🔥 修复：提供对完整数据列表的访问，并在数据变化时触发rebuild
final allItemsProvider = Provider<List<FeedItem>>((ref) {
  // Watch feedProvider (state) to trigger rebuild
  ref.watch(feedProvider);
  // Then access the complete list from notifier
  return ref.read(feedProvider.notifier).allItems;
});
