import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/mock_data.dart';
import '../../../models/feed_item.dart';
import '../../../data/services/firestore_service.dart';
import '../../../core/services/content_generator_service.dart';
import '../../../config/api_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../data/services/content_extraction_service.dart';
import 'package:flutter/foundation.dart';

// Global provider to track reviewed items in the current session (persist across navigation)
final reviewedSessionProvider = StateProvider<Set<String>>((ref) => {});

// Provider for the active review session IDs (Today's Review)
final reviewSessionIdsProvider = StateProvider<List<String>>((ref) => []);

// Provider for the library item IDs
final libraryIdsProvider = StateProvider<List<String>>((ref) => []);

// Loading state for feed data
final feedLoadingProvider = StateProvider<bool>((ref) => true);

// Navigation Intent Class
class FeedNavigationIntent {
  final String moduleId;
  final int index;

  FeedNavigationIntent({required this.moduleId, required this.index});
}

// Provider to handle jump requests to specific items in the feed
final feedInitialIndexProvider =
    StateProvider<FeedNavigationIntent?>((ref) => null);

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
      // print('Failed to save last active module: $e');
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
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('feed_progress');
      Map<String, int> localProgress = {};
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        localProgress =
            decoded.map((key, value) => MapEntry(key, value as int));
        state = localProgress;
      }

      User? user = FirebaseAuth.instance.currentUser;
      for (int i = 0; i < 10 && user == null; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        user = FirebaseAuth.instance.currentUser;
      }

      if (user != null) {
        final cloudProgress =
            await _dataService.fetchAllModuleProgress(user.uid);
        if (cloudProgress.isNotEmpty) {
          final merged = {...localProgress, ...cloudProgress};
          if (merged.toString() != state.toString()) {
            state = merged;
            await prefs.setString('feed_progress', json.encode(merged));
          }
        }
      }
    } catch (e) {
      // Quiet fail
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
  List<FeedItem> _sharedItems = []; // 🆕 持久化存储通过 loadSharedModule 加载的项

  // Track active background job listeners
  final Map<String, StreamSubscription> _jobSubscriptions = {};

  // 当前激活的模块ID，用于恢复过滤状态
  String? _activeModuleId;

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

      // 3. 合并所有内容 (保留已经存在的共享内容)
      final existingIds = _allItems.map((e) => e.id).toSet();
      final newOfficialAndCustom = [...officialItems, ...customItems];
      final dedupedNew = newOfficialAndCustom
          .where((i) => !existingIds.contains(i.id))
          .toList();

      // Ensure we keep what we already have (like shared items loaded before loadAllData finished)
      // 🌟 核心修复：始终合并 _sharedItems，防止其被官方加载流覆盖
      _allItems = [..._sharedItems, ...dedupedNew];

      // 4. 排序：按时间正序 (从旧到新，符合阅读习惯)
      _allItems.sort((a, b) {
        final dateA = a.createdAt ?? DateTime(1970);
        final dateB = b.createdAt ?? DateTime(1970);
        return dateA.compareTo(dateB); // 升序
      });

      print('📊 总计: ${_allItems.length} 个知识点 (已包含共享和本地数据)');

      // 🔔 关键修复：刷新 state
      _refreshState();
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

    // 1. 去重检查：防止后台监听和手动刷新导致数据冲突
    final existingIds = _allItems.map((e) => e.id).toSet();
    final uniqueNewItems =
        newItems.where((i) => !existingIds.contains(i.id)).toList();

    if (uniqueNewItems.isEmpty) return;

    // 2. 同步全量数据
    _allItems.addAll(uniqueNewItems);

    // 3. 统一排序：按创建时间正序排列 (从旧到新，让新知识卡片出现在列表底部)
    _allItems.sort((a, b) {
      final dateA = a.createdAt ?? DateTime.now();
      final dateB = b.createdAt ?? DateTime.now();
      return dateA.compareTo(dateB); // ASC: Oldest first
    });

    // 4. 更新当前视图 state：确保全局数据同步并应用过滤
    _refreshState();
  }

  /// 监听特定的后台任务，并将生成的卡片实时同步到 Feed
  void observeJob(String jobId) {
    if (_jobSubscriptions.containsKey(jobId)) return;

    if (kDebugMode) print('📡 FeedNotifier: Observing background job $jobId');

    final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'reado',
    );

    final subscription =
        ContentExtractionService.listenToJob(db, jobId).listen((event) {
      if (event.type == StreamingEventType.card && event.card != null) {
        addCustomItems([event.card!]);
      } else if (event.type == StreamingEventType.complete ||
          event.type == StreamingEventType.error) {
        _jobSubscriptions[jobId]?.cancel();
        _jobSubscriptions.remove(jobId);
        if (kDebugMode)
          print('🏁 FeedNotifier: Job $jobId finished, observer removed.');
      }
    });

    _jobSubscriptions[jobId] = subscription;
  }

  @override
  void dispose() {
    for (final sub in _jobSubscriptions.values) {
      sub.cancel();
    }
    _jobSubscriptions.clear();
    super.dispose();
  }

  /// 加载指定模块的数据 (Feed Logic)
  void loadModule(String moduleId) {
    _activeModuleId = moduleId;
    if (_allItems.isEmpty) {
      // Retry logic if called too early
      loadAllData().then((_) {
        _refreshState();
      });
    } else {
      _refreshState();
    }
  }

  /// 内部方法：根据当前的过滤器刷新 state
  void _refreshState() {
    if (_activeModuleId == null) {
      // 如果没有激活模块（如全局搜索或共享空间初期），显示全量
      state = [..._allItems];
    } else {
      state =
          _allItems.where((item) => item.moduleId == _activeModuleId).toList();
    }
    print(
        '✨ FeedNotifier State Refreshed: ${state.length} items (Module: $_activeModuleId)');
  }

  /// 加载别人分享的模块 (Shared Module Logic)
  Future<int> loadSharedModule(String moduleId, String ownerId) async {
    print('🔄 Loading shared module: $moduleId from owner: $ownerId');
    _ref.read(feedLoadingProvider.notifier).state = true;
    try {
      List<FeedItem> sharedItems = [];

      // 🆕 Handle official modules
      if (['A', 'B', 'C', 'D'].contains(moduleId)) {
        sharedItems = await _dataService.fetchFeedItems(moduleId);
      } else {
        sharedItems =
            await _dataService.fetchCustomFeedItemsByModule(ownerId, moduleId);
      }

      if (sharedItems.isNotEmpty) {
        // Add to allItems if not exists
        final existingIds = _allItems.map((e) => e.id).toSet();
        final newItems =
            sharedItems.where((i) => !existingIds.contains(i.id)).toList();

        // Sort new items
        newItems.sort((a, b) {
          final dateA = a.createdAt ?? DateTime.now();
          final dateB = b.createdAt ?? DateTime.now();
          return dateA.compareTo(dateB);
        });

        // Add to sharedItems tracker to persist across loadAllData refreshes
        final existingSharedIds = _sharedItems.map((e) => e.id).toSet();
        final brandNewShared = sharedItems
            .where((i) => !existingSharedIds.contains(i.id))
            .toList();
        _sharedItems.addAll(brandNewShared);

        _allItems.addAll(newItems);

        // Re-sort all items just in case (ASC)
        _allItems.sort((a, b) {
          final dateA = a.createdAt ?? DateTime.now();
          final dateB = b.createdAt ?? DateTime.now();
          return dateA.compareTo(dateB);
        });

        // 🆕 IMPORTANT: If we are jump starting a shared module,
        // we might want to pre-fill progress or set active module
        _ref.read(lastActiveModuleProvider.notifier).setActiveModule(moduleId);

        // Show only these items in the feed/module view
        // Don't override state HERE if we align with loadModule logic later.
        // But ModuleDetailPage uses allItemsProvider which watches notifier.
        // If we update state, it notifies listeners.
        // We can set state to just these items so UI updates effectively if viewing feed?
        // But ModuleDetailPage views 'allItemsProvider' filtered by module locally.

        // Update state from allItems to trigger listeners without losing data
        // For shared modules, we typically want to see all shared items,
        // but loadSharedModule is usually called from ModuleDetailPage which
        // filters from allItemsProvider itself.
        _refreshState();

        return sharedItems.length;
      } else {
        print('⚠️ Shared module is empty or not found');
        return 0;
      }
    } catch (e) {
      print('❌ Failed to load shared module: $e');
      throw e;
    } finally {
      _ref.read(feedLoadingProvider.notifier).state = false;
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
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Optimistic UI update
    _allItems = List.from(_allItems)..removeAt(index);
    state = List.from(state)..removeWhere((i) => i.id == itemId);

    if (item.isCustom) {
      await _dataService.deleteCustomFeedItem(itemId);
    } else {
      // For official items, we "hide" them for this user
      await _dataService.hideOfficialFeedItem(currentUser.uid, itemId);
    }
  }

  Future<void> hideFeedItem(String itemId) async {
    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Optimistic UI update
    _allItems = List.from(_allItems)..removeAt(index);
    state = List.from(state)..removeWhere((i) => i.id == itemId);

    await _dataService.hideOfficialFeedItem(currentUser.uid, itemId);
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
  Future<void> seedDatabase({bool force = false}) async {
    print("Seeding DB...");
    await _dataService.seedInitialData(MockData.initialFeedItems, force: force);
    await loadAllData();
    print("Done.");
  }

  /// 刷新所有数据
  Future<void> refreshAll() async {
    await loadAllData();
  }
}

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final feedProvider = StateNotifierProvider<FeedNotifier, List<FeedItem>>((ref) {
  ref.watch(authStateProvider); // Rebuild on login/logout
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
