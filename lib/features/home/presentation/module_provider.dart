import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/knowledge_module.dart';
import '../../../data/services/firestore_service.dart';
import '../../feed/presentation/feed_provider.dart';

// State definition
class ModuleState {
  final List<KnowledgeModule> officials;
  final List<KnowledgeModule> custom;
  final bool isLoading;

  ModuleState({
    this.officials = const [],
    this.custom = const [],
    this.isLoading = false,
  });

  List<KnowledgeModule> get all => [...officials, ...custom];

  ModuleState copyWith({
    List<KnowledgeModule>? officials,
    List<KnowledgeModule>? custom,
    bool? isLoading,
  }) {
    return ModuleState(
      officials: officials ?? this.officials,
      custom: custom ?? this.custom,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Notifier
class ModuleNotifier extends StateNotifier<ModuleState> {
  final DataService _dataService;

  ModuleNotifier(this._dataService) : super(ModuleState()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    state = state.copyWith(isLoading: true);

    try {
      // 1. Load Official Modules (Hardcoded for now, could be fetched)
      final officials = KnowledgeModule.officials;

      // 2. Load User Custom Modules
      final user = FirebaseAuth.instance.currentUser;
      List<KnowledgeModule> custom = [];

      if (user != null) {
        custom = await _dataService.fetchUserModules(user.uid);
      }

      state = state.copyWith(
        officials: officials,
        custom: custom,
      );
    } catch (e) {
      print('❌ Failed to load modules: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    await _loadInitialData();
  }

  Future<void> createModule(String title, String description) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('用户未登录，请先登录');
    }

    try {
      final newModule =
          await _dataService.createModule(user.uid, title, description);
      state = state.copyWith(
        custom: [newModule, ...state.custom], // Add to top
      );
    } catch (e) {
      print('Failed to create module: $e');
      rethrow;
    }
  }
}

// Provider
final moduleProvider =
    StateNotifierProvider<ModuleNotifier, ModuleState>((ref) {
  final dataService = ref.watch(dataServiceProvider);
  return ModuleNotifier(dataService);
});
