import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AiDeconstructionMode {
  standard,
  grandma, // 极简大白话
  phd, // 智力障碍博士生
  podcast, // 播客/对话式输出
}

class AiSettings {
  final AiDeconstructionMode mode;

  AiSettings({
    this.mode = AiDeconstructionMode.standard,
  });

  bool get isGrandmaModeEnabled => mode == AiDeconstructionMode.grandma;

  AiSettings copyWith({
    AiDeconstructionMode? mode,
  }) {
    return AiSettings(
      mode: mode ?? this.mode,
    );
  }
}

class AiSettingsNotifier extends StateNotifier<AiSettings> {
  AiSettingsNotifier() : super(AiSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Handle migration from old boolean if exists
    final oldIsGrandma = prefs.getBool('ai_grandma_mode');
    final savedMode = prefs.getString('ai_deconstruction_mode');

    if (savedMode != null) {
      final mode = AiDeconstructionMode.values.firstWhere(
        (e) => e.name == savedMode,
        orElse: () => AiDeconstructionMode.standard,
      );
      state = AiSettings(mode: mode);
    } else if (oldIsGrandma == true) {
      state = AiSettings(mode: AiDeconstructionMode.grandma);
    }
  }

  Future<void> setMode(AiDeconstructionMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_deconstruction_mode', mode.name);
  }

  // Keep for compatibility during transition
  Future<void> setGrandmaMode(bool enabled) async {
    await setMode(
        enabled ? AiDeconstructionMode.grandma : AiDeconstructionMode.standard);
  }
}

final aiSettingsProvider =
    StateNotifierProvider<AiSettingsNotifier, AiSettings>((ref) {
  return AiSettingsNotifier();
});
