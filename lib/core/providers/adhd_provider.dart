import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ADHD 阅读辅助模式
enum AdhdReadingMode {
  none, // 关闭
  bold, // 仅加粗
  color, // 仅标色
  hybrid, // 混合模式 (加粗 + 标色)
}

/// ADHD 引导强度
enum AdhdIntensity {
  low('低'),
  medium('中'),
  high('高');

  final String label;
  const AdhdIntensity(this.label);
}

/// ADHD 辅助色
enum AdhdFocusColor {
  orange(Colors.orangeAccent, '活力橙'),
  green(Colors.greenAccent, '清新绿'),
  blue(Colors.blueAccent, '沉静蓝');

  final Color color;
  final String label;
  const AdhdFocusColor(this.color, this.label);
}

/// ADHD 设置状态
class AdhdSettings {
  final bool isEnabled;
  final AdhdReadingMode mode;
  final AdhdIntensity intensity;

  AdhdSettings({
    this.isEnabled = false,
    this.mode = AdhdReadingMode.color,
    this.intensity = AdhdIntensity.low,
  });

  AdhdSettings copyWith({
    bool? isEnabled,
    AdhdReadingMode? mode,
    AdhdIntensity? intensity,
  }) {
    return AdhdSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      intensity: intensity ?? this.intensity,
    );
  }
}

class AdhdSettingsNotifier extends StateNotifier<AdhdSettings> {
  AdhdSettingsNotifier() : super(AdhdSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Default to true if key doesn't exist (First time user)
    final bool isEnabled;
    if (prefs.containsKey('adhd_enabled')) {
      isEnabled = prefs.getBool('adhd_enabled')!;
    } else {
      isEnabled = true; // Default ON
      // Save it immediately so we know it's not first time next launch?
      // Or keep dynamic. Let's save it to be explicit.
      await prefs.setBool('adhd_enabled', true);
    }

    final modeIndex = prefs.getInt('adhd_mode_index') ??
        AdhdReadingMode.hybrid.index; // Default Hybrid
    final intensityIndex =
        prefs.getInt('adhd_intensity_index') ?? AdhdIntensity.low.index;

    state = AdhdSettings(
      isEnabled: isEnabled,
      mode: AdhdReadingMode.values[modeIndex],
      intensity: AdhdIntensity.values[intensityIndex],
    );
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(isEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adhd_enabled', value);
  }

  Future<void> setMode(AdhdReadingMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('adhd_mode_index', mode.index);
  }

  Future<void> setIntensity(AdhdIntensity intensity) async {
    state = state.copyWith(intensity: intensity);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('adhd_intensity_index', intensity.index);
  }
}

final adhdSettingsProvider =
    StateNotifierProvider<AdhdSettingsNotifier, AdhdSettings>((ref) {
  return AdhdSettingsNotifier();
});
