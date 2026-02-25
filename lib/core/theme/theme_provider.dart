import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题模式
enum ThemeMode { light, dark, system }

/// 主题状态管理
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('theme_mode') ?? 'light';

    state = switch (themeName) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  bool get isDarkMode {
    // 简化处理：system 当作 light (默认浅色)
    return state == ThemeMode.dark;
  }
}

/// Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

/// 主题数据
class AppTheme {
  // 深色主题
  // 深色主题
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF212526), // Custom BG
        primaryColor: const Color(0xFFee8f4b), // Custom Accent

        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFee8f4b),
          secondary: Color(0xFFee8f4b),
          tertiary: Color(0xFF917439), // Custom Secondary
          surface: Color(0xFF212526), // Custom Surface
          onSurface: Color(0xFFe6e8d1), // Custom Text
          outline: Color(0xFF917439), // For borders
        ),

        cardColor: const Color(0xFF212526),
        dividerColor: const Color(0xFF917439).withOpacity(0.2),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF212526),
          foregroundColor: Color(0xFFe6e8d1),
          elevation: 0,
        ),

        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF212526),
          selectedItemColor: Color(0xFFee8f4b),
          unselectedItemColor: Color(0xFF917439), // Muted Gold
        ),

        // Adjust default TextTheme to use the custom text color
        textTheme:
            Typography.material2021(platform: TargetPlatform.iOS).white.apply(
                  bodyColor: const Color(0xFFe6e8d1),
                  displayColor: const Color(0xFFe6e8d1),
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
