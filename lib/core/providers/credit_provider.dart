import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/feed/presentation/feed_provider.dart';

class UserStats {
  final int credits;
  final int shareClicks;
  UserStats({required this.credits, required this.shareClicks});
}

class CreditNotifier extends StateNotifier<AsyncValue<UserStats>> {
  final DataService _dataService;
  final String? _userId;
  StreamSubscription? _subscription;

  CreditNotifier(this._dataService, this._userId)
      : super(const AsyncValue.loading()) {
    if (_userId != null) {
      _listenToStats();
      // --- 关键加固：全局确保用户文档存在 ---
      _syncProfile();
    }
  }

  Future<void> _syncProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _dataService.ensureUserDocument(user);
    }
  }

  void _listenToStats() {
    _subscription?.cancel();
    _subscription = _dataService.userStatsStream(_userId!).listen(
      (stats) {
        state = AsyncValue.data(UserStats(
          credits: stats['credits'] ?? 200,
          shareClicks: stats['shareClicks'] ?? 0,
        ));
      },
      onError: (e) => state = AsyncValue.error(e, StackTrace.current),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchStats() async => _listenToStats();

  // 消耗积分 (AI 功能)
  // 消耗积分 (AI 功能)
  Future<bool> useAI({int amount = 10}) async {
    final uid = _userId;
    if (uid == null) return false;

    UserStats? current = state.asData?.value;

    // 如果当前状态为空（可能是刚初始化还在 Loading），尝试主动拉取一次
    if (current == null) {
      try {
        final stats = await _dataService.fetchUserStats(uid);
        current = UserStats(
          credits: stats['credits'] ?? 200,
          shareClicks: stats['shareClicks'] ?? 0,
        );
        state = AsyncValue.data(current);
      } catch (e) {
        print('Error fetching stats in useAI: $e');
        return false;
      }
    }

    if (current.credits < amount) return false;

    try {
      state = AsyncValue.data(UserStats(
          credits: current.credits - amount, shareClicks: current.shareClicks));
      await _dataService.updateUserCredits(uid, -amount);
      return true;
    } catch (e) {
      state = AsyncValue.data(current);
      return false;
    }
  }

  // 奖励积分 (分享)
  Future<void> rewardShare({int amount = 50}) async {
    final current = state.asData?.value;
    if (current == null) return;
    try {
      state = AsyncValue.data(UserStats(
          credits: current.credits + amount, shareClicks: current.shareClicks));
      await _dataService.updateUserCredits(_userId!, amount);
    } catch (e) {
      state = AsyncValue.data(current);
    }
  }

  // 重新获取 (用于点击后刷新)
  Future<void> refresh() async => _fetchStats();
}

final creditProvider =
    StateNotifierProvider<CreditNotifier, AsyncValue<UserStats>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final dataService = ref.watch(dataServiceProvider);
  return CreditNotifier(dataService, userId);
});
