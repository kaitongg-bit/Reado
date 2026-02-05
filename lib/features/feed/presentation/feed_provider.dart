import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/mock_data.dart';
import '../../../models/feed_item.dart';
import '../../../data/services/firestore_service.dart';
import '../../../core/services/content_generator_service.dart';
import '../../../config/api_config.dart';

// Global provider to track reviewed items in the current session (persist across navigation)
final reviewedSessionProvider = StateProvider<Set<String>>((ref) => {});

// Provider for the active review session IDs (Today's Review)
final reviewSessionIdsProvider = StateProvider<List<String>>((ref) => []);

// Provider for the library item IDs
final libraryIdsProvider = StateProvider<List<String>>((ref) => []);

// Loading state for feed data
final feedLoadingProvider = StateProvider<bool>((ref) => true);

// Provider to handle jump requests to specific items in the feed
// -1 means "jump to last", null means "no jump requested"
final feedInitialIndexProvider = StateProvider<int?>((ref) => null);

// Provider to persist the last active module ID
final lastActiveModuleProvider =
    StateNotifierProvider<LastActiveModuleNotifier, String?>((ref) {
  return LastActiveModuleNotifier();
});

class LastActiveModuleNotifier extends StateNotifier<String?> {
  LastActiveModuleNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final moduleId = prefs.getString('last_active_module');
      if (moduleId != null) {
        state = moduleId;
        print('📍 Last active module loaded: $moduleId');
      }
    } catch (e) {
      print('Failed to load last active module: $e');
    }
  }

  Future<void> setActiveModule(String moduleId) async {
    if (state == moduleId) return;
    state = moduleId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_active_module', moduleId);
      print('📍 Last active module saved: $moduleId');
    } catch (e) {
      print('Failed to save last active module: $e');
    }
  }
}

// Provider to persist the last focused item index PER MODULE
// Key: moduleId, Value: index
// CRITICAL: Do NOT use ref.watch on auth stream here - it causes provider rebuild!
final feedProgressProvider =
    StateNotifierProvider<FeedProgressNotifier, Map<String, int>>((ref) {
  final dataService = ref.watch(dataServiceProvider);
  return FeedProgressNotifier(dataService);
});

class FeedProgressNotifier extends StateNotifier<Map<String, int>> {
  final DataService _dataService;

  FeedProgressNotifier(this._dataService) : super({}) {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      // 1. Load Local FIRST (instant restore)
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('feed_progress');
      Map<String, int> localProgress = {};
      if (jsonStr != null) {
        print('📦 Local data found: $jsonStr');
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        localProgress =
            decoded.map((key, value) => MapEntry(key, value as int));
        state = localProgress; // Immediate local restore
        print('📦 Local progress loaded: $localProgress');
      } else {
        print('📦 No local data found');
      }

      // 2. Wait for Firebase Auth to initialize (up to 2 seconds)
      User? user = FirebaseAuth.instance.currentUser;
      for (int i = 0; i < 10 && user == null; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        user = FirebaseAuth.instance.currentUser;
      }

      // 3. Load Cloud (Authoritative) if user available
      if (user != null) {
        print('☁️ Fetching progress for user ${user.uid}...');
        final cloudProgress =
            await _dataService.fetchAllModuleProgress(user.uid);
        print('☁️ Cloud progress received: $cloudProgress');
        if (cloudProgress.isNotEmpty) {
          // Merge: Cloud overwrites Local for same keys
          final merged = {...localProgress, ...cloudProgress};
          print('🔀 Merged progress: $merged');

          if (merged.toString() != state.toString()) {
            state = merged;
            // Update Local Cache
            await prefs.setString('feed_progress', json.encode(merged));
            print('✅ Sync with Cloud complete. Final state: $state');
          }
        } else {
          print('☁️ Cloud returned empty, keeping local: $state');
        }
      }
    } catch (e) {
      print('❌ Failed to load progress: $e');
    }
  }

  Future<void> setProgress(String moduleId, int index) async {
    // Only update if changed
    if (state[moduleId] == index) return;

    print('💾 Saving progress: moduleId=$moduleId, index=$index');

    // CRITICAL: Must use this syntax to use variable as map key in Dart
    final newState = Map<String, int>.from(state);
    newState[moduleId] = index;
    state = newState;
    print('💾 New state: $state');

    try {
      // 1. Save Local IMMEDIATELY
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('feed_progress', json.encode(state));
      print('💾 Saved to local storage');

      // 2. Save Cloud (Fire & Forget)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _dataService.saveModuleProgress(user.uid, moduleId, index);
        print('💾 Saving to cloud for user ${user.uid}');
      }
    } catch (e) {
      print('❌ Failed to save progress: $e');
    }
  }
}

// DATA SOURCE PROVIDER
final dataServiceProvider = Provider<DataService>((ref) => FirestoreService());

// Content Generator Provider
final contentGeneratorProvider = Provider((ref) {
  try {
    final apiKey = ApiConfig.getApiKey();
    final proxyUrl = ApiConfig.geminiProxyUrl;
    return ContentGeneratorService(
      apiKey: apiKey,
      baseUrl: proxyUrl.isNotEmpty ? proxyUrl : null,
    );
  } catch (e) {
    print('⚠️ Gemini API Key not configured: $e');
    // Return with empty key, will fail on actual API call
    return ContentGeneratorService(apiKey: '');
  }
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
      print('❌ Basic load failed: $e');
      rethrow;
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

  Future<void> deleteFeedItem(String itemId) async {
    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = _allItems[index];
    if (!item.isCustom) return; // Only allow deleting custom items

    // Optimistic UI update
    _allItems = List.from(_allItems)..removeAt(index);
    state = List.from(state)..removeWhere((i) => i.id == itemId);

    await _dataService.deleteCustomFeedItem(itemId);
  }

  void deleteUserNote(String itemId, UserNotePage note) {
    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = _allItems[index];
    final newPages = List<CardPageContent>.from(item.pages)..remove(note);

    final newItem = item.copyWith(pages: newPages);
    updateItem(newItem);

    _dataService.deleteUserNote(itemId, note);
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

    // Persist to backend
    _dataService.updateUserNote(itemId, oldNote, newQ, newA);
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
