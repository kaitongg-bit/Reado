import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题模式
enum ThemeMode { light, dark, system }

/// 主题状态管理
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('theme_mode') ?? 'dark';

    state = switch (themeName) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  bool get isDarkMode {
    // 简化处理：system 当作 dark
    return state == ThemeMode.dark || state == ThemeMode.system;
  }
}

/// Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

/// 主题数据
class AppTheme {
  // 深色主题
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF8A65),
          secondary: Color(0xFFFF8A65),
          surface: Color(0xFF1E1E1E),
          onSurface: Colors.white,
        ),
        cardColor: const Color(0xFF252525),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      );

  // 浅色主题
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF8A65),
          secondary: Color(0xFFFF8A65),
          surface: Colors.white,
          onSurface: Colors.black87,
        ),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
