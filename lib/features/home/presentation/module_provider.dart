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
      final user = FirebaseAuth.instance.currentUser;

      List<KnowledgeModule> officials = KnowledgeModule.officials;
      List<KnowledgeModule> custom = [];

      if (user != null) {
        // 1. Fetch Custom Modules
        custom = await _dataService.fetchUserModules(user.uid);

        // 2. Fetch Hidden Official IDs and filter
        final hiddenIds = await _dataService.fetchHiddenModuleIds(user.uid);
        if (hiddenIds.isNotEmpty) {
          officials =
              officials.where((m) => !hiddenIds.contains(m.id)).toList();
        }
      }

      state = state.copyWith(
        officials: officials,
        custom: custom,
      );

      // 3. Auto-create "Default Knowledge Base" if missing (and user is logged in)
      if (user != null && !custom.any((m) => m.title == '默认知识库')) {
        try {
          // We initiate creation but don't await to block UI,
          // but we DO want to update state when done.
          // However, since we are inside _loadInitialData which is async, we can await.
          final defaultModule = await _dataService.createModule(
            user.uid,
            '默认知识库',
            '系统预设的默认知识库',
          );
          // Update state again with the new module
          state = state.copyWith(
            custom: [defaultModule, ...custom],
          );
        } catch (e) {
          print('Failed to auto-create default module: $e');
        }
      }
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

  Future<void> deleteModule(String moduleId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isOfficial = state.officials.any((m) => m.id == moduleId);

    try {
      if (isOfficial) {
        // Hiding official module: Store in user's hidden modules list
        await _dataService.hideOfficialModule(user.uid, moduleId);
        state = state.copyWith(
          officials: state.officials.where((m) => m.id != moduleId).toList(),
        );
      } else {
        // Deleting custom module
        await _dataService.deleteModule(user.uid, moduleId);
        state = state.copyWith(
          custom: state.custom.where((m) => m.id != moduleId).toList(),
        );
      }
    } catch (e) {
      print('Failed to delete/hide module: $e');
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
