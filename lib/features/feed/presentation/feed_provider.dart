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
  final onProgressUpdated = (String moduleId) {
    ref.read(moduleLastAccessedAtProvider.notifier).touch(moduleId);
  };
  return FeedProgressNotifier(dataService, onProgressUpdated: onProgressUpdated);
});

class FeedProgressNotifier extends StateNotifier<Map<String, int>> {
  final DataService _dataService;
  final void Function(String moduleId)? onProgressUpdated;

  FeedProgressNotifier(this._dataService, {this.onProgressUpdated})
      : super({}) {
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
    onProgressUpdated?.call(moduleId);

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

/// 各模块最后学习/访问时间（ms），用于「最近在学」排序
final moduleLastAccessedAtProvider =
    StateNotifierProvider<ModuleLastAccessedAtNotifier, Map<String, int>>((ref) {
  final dataService = ref.watch(dataServiceProvider);
  return ModuleLastAccessedAtNotifier(dataService);
});

class ModuleLastAccessedAtNotifier extends StateNotifier<Map<String, int>> {
  final DataService _dataService;

  ModuleLastAccessedAtNotifier(this._dataService) : super({}) {
    _load();
  }

  static const String _prefsKey = 'feed_progress_last_at';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKey);
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        state = decoded.map((key, value) => MapEntry(key, value as int));
      }
      User? user = FirebaseAuth.instance.currentUser;
      for (int i = 0; i < 10 && user == null; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        user = FirebaseAuth.instance.currentUser;
      }
      if (user != null) {
        final cloud = await _dataService.fetchModuleLastAccessed(user.uid);
        if (cloud.isNotEmpty) {
          final merged = {...state, ...cloud};
          state = merged;
          await prefs.setString(_prefsKey, json.encode(merged));
        }
      }
    } catch (e) {
      // Quiet fail
    }
  }

  void touch(String moduleId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (state[moduleId] == now) return;
    final newState = Map<String, int>.from(state);
    newState[moduleId] = now;
    state = newState;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_prefsKey, json.encode(state));
    });
  }
}

// DATA SOURCE PROVIDER
final dataServiceProvider = Provider<DataService>((ref) => FirestoreService());

/// 分享时是否开放笔记（个人设置）
final shareNotesPublicProvider =
    FutureProvider.family<bool, String>((ref, userId) async {
  return ref.watch(dataServiceProvider).getShareNotesPublic(userId);
});

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

  // Track active filter state
  String? _currentModuleId;
  String? _currentSearchQuery;

  // Source of Truth
  List<FeedItem> _allItems = [];

  // Track active background job listeners
  final Map<String, StreamSubscription> _jobSubscriptions = {};

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

      // 4. 排序：按时间正序 (从旧到新，符合阅读习惯: 最先生成的在上面)
      _allItems.sort((a, b) {
        final dateA = a.createdAt ?? DateTime(1970);
        final dateB = b.createdAt ?? DateTime(1970);
        return dateA.compareTo(dateB); // 升序 (ASC)
      });

      print('📊 总计: ${_allItems.length} 个知识点 (已按时间正序排序)');

      // 5. 更新 State (Respect active filter)
      if (mounted) {
        _refreshState();
      }
    } catch (e) {
      print('❌ Basic load failed: $e');
      rethrow;
    } finally {
      print('🏁 加载状态结束');
      if (mounted) {
        _ref.read(feedLoadingProvider.notifier).state = false;
      }
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
    _allItems = [..._allItems, ...uniqueNewItems]; // Append new items

    // 3. 统一排序：按创建时间正序排列 (从旧到新)
    _allItems.sort((a, b) {
      final dateA = a.createdAt ?? DateTime(1970);
      final dateB = b.createdAt ?? DateTime(1970);
      return dateA.compareTo(dateB); // ASC
    });

    // 4. 更新当前视图 state (Respect active filter)
    if (!mounted) return;
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
    _currentModuleId = moduleId;
    _currentSearchQuery = null; // Clear search on module switch

    if (_allItems.isEmpty) {
      // Retry logic if called too early
      loadAllData().then((_) {
        if (!mounted) return;
        _refreshState();
      });
    } else {
      if (!mounted) return;
      _refreshState();
    }
  }

  /// Apply current filters to _allItems and update state
  void _refreshState() {
    List<FeedItem> filtered = _allItems;

    // 1. Apply Search
    if (_currentSearchQuery != null && _currentSearchQuery!.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.title
            .toLowerCase()
            .contains(_currentSearchQuery!.toLowerCase());
      }).toList();
    }
    // 2. Apply Module Filter
    else if (_currentModuleId != null) {
      if (_currentModuleId == 'AI_NOTES') {
        filtered = filtered.where((item) {
          return item.id == 'b002' || item.pages.any((p) => p is UserNotePage);
        }).toList();
      } else if (_currentModuleId != 'ALL') {
        filtered =
            filtered.where((item) => item.module == _currentModuleId).toList();
      }
    }

    state = filtered;
  }

  /// 搜索逻辑
  void searchItems(String query) {
    if (!mounted) return;
    _currentSearchQuery = query;
    _refreshState();
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
    if (!mounted) return;
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
    if (!mounted) return;
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
    if (!mounted) return;
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
    if (!mounted) return;
    _allItems = List.from(_allItems)..removeAt(index);
    state = List.from(state)..removeWhere((i) => i.id == itemId);

    await _dataService.hideOfficialFeedItem(currentUser.uid, itemId);
  }

  /// 将自定义知识卡移动到另一个知识库（仅支持 isCustom 的卡片）
  /// 本地更新 item.moduleId，使移出方和移入方的数量都立即生效，无需刷新
  Future<void> moveFeedItem(String itemId, String targetModuleId) async {
    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = _allItems[index];
    if (!item.isCustom) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await _dataService.moveCustomFeedItem(
        currentUser.uid, itemId, targetModuleId);

    if (!mounted) return;
    // 不删除项，只改所属知识库，这样移出方列表立即少一张、移入方数量立即多一张
    final updated = item.copyWith(moduleId: targetModuleId);
    _allItems = [
      for (var i = 0; i < _allItems.length; i++)
        i == index ? updated : _allItems[i],
    ];
    _refreshState();
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

  /// 更新自定义卡某一页的正文（原位编辑保存）
  Future<void> updateFeedItemPageContent(
      String itemId, int pageIndex, String newMarkdownContent) async {
    final userId = currentUserId;
    if (userId == null) return;

    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = _allItems[index];
    if (pageIndex < 0 || pageIndex >= item.pages.length) return;

    final page = item.pages[pageIndex];
    if (page is! OfficialPage) return;

    await _dataService.updateCustomFeedItemPageContent(
        userId, itemId, pageIndex, newMarkdownContent);

    final newPage = OfficialPage(
      newMarkdownContent,
      flashcardQuestion: page.flashcardQuestion,
      flashcardAnswer: page.flashcardAnswer,
    );
    final newPages = List<CardPageContent>.from(item.pages);
    newPages[pageIndex] = newPage;
    final newItem = item.copyWith(pages: newPages);
    updateItem(newItem);
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
