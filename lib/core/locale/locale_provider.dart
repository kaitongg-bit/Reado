import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用界面语言 + AI 输出语言（`outputLocale`: `en` | `zh`）。
///
/// - 持久化：**SharedPreferences** `app_locale_code`（官网/设置切换后立即写入）。
/// - 启动时由 [main] 调用 [readPersistedCode] 并 [LocaleNotifier.fromInitialCode]，避免首帧先显示英文再跳变。
/// - 登录用户额外同步到 Firestore **`reado`**：`share_settings` 的 `appLocale`（分享页访客语言）与 `users/{uid}.preferredLocale`（账号偏好，便于多端一致）。
class LocaleNotifier extends StateNotifier<({Locale locale, String outputLocale})> {
  static const String _key = 'app_locale_code';

  static FirebaseFirestore get _db => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'reado',
      );

  /// 在 `runApp` 之前调用，与 [fromInitialCode] 配合实现「官网选语言 → 下次打开仍是该语言」。
  static Future<String> readPersistedCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? 'en';
  }

  /// 默认：异步从磁盘加载（测试或未使用 [main] 覆盖时）。
  LocaleNotifier() : super(_tupleFromCode('en')) {
    _load();
  }

  /// 已由 [main] 预读 [initialCode]：首帧即为正确语言，不再异步闪烁。
  LocaleNotifier.fromInitialCode(String initialCode)
      : super(_tupleFromCode(initialCode)) {
    _syncToCloudIfNeeded();
  }

  static ({Locale locale, String outputLocale}) _tupleFromCode(String code) {
    switch (code) {
      case 'zh':
        return (locale: const Locale('zh'), outputLocale: 'zh');
      case 'en':
      default:
        return (locale: const Locale('en'), outputLocale: 'en');
    }
  }

  Future<void> _load() async {
    final code = await readPersistedCode();
    state = _tupleFromCode(code);
    await _syncToCloudIfNeeded();
  }

  Future<void> _syncToCloudIfNeeded() async {
    await _pushLocaleToShareSettings(state.outputLocale);
    await _pushPreferredLocaleToUser(state.outputLocale);
  }

  static Future<void> _pushLocaleToShareSettings(String code) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final normalized = code == 'zh' ? 'zh' : 'en';
    try {
      await _db
          .collection('users')
          .doc(u.uid)
          .collection('share_settings')
          .doc('settings')
          .set({'appLocale': normalized}, SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<void> _pushPreferredLocaleToUser(String code) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final normalized = code == 'zh' ? 'zh' : 'en';
    try {
      await _db.collection('users').doc(u.uid).set(
            {'preferredLocale': normalized},
            SetOptions(merge: true),
          );
    } catch (_) {}
  }

  /// BCP-style code for job payload / prompts: 'en' | 'zh'
  String get outputLocale => state.outputLocale;

  Locale get locale => state.locale;

  Future<void> setLocaleCode(String code) async {
    state = _tupleFromCode(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, state.outputLocale);
    await _pushLocaleToShareSettings(state.outputLocale);
    await _pushPreferredLocaleToUser(state.outputLocale);
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode == 'zh' ? 'zh' : 'en';
    await setLocaleCode(code);
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, ({Locale locale, String outputLocale})>(
        (ref) {
  return LocaleNotifier();
});
