import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'firebase_options.dart';
import 'core/theme/theme_provider.dart' as core;
import 'core/theme/theme_provider.dart' show AppTheme;
import 'core/locale/locale_provider.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:quick_pm/l10n/app_localizations.dart';
import 'core/router/router_provider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configurations
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ .env file not found, using environment variables only.');
    }
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 官网/设置里选过的语言：首帧即用，避免先英文再跳变；并与 AI outputLocale 一致
  final initialLocaleCode = await LocaleNotifier.readPersistedCode();

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith(
          (ref) => LocaleNotifier.fromInitialCode(initialLocaleCode),
        ),
      ],
      child: const QuickPMApp(),
    ),
  );
}

class QuickPMApp extends ConsumerWidget {
  const QuickPMApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(core.themeProvider);
    final isDark = themeMode == core.ThemeMode.dark;
    final router = ref.watch(routerProvider);
    final localeState = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Reado',
      locale: localeState.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? flutter.ThemeMode.dark : flutter.ThemeMode.light,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
      routerConfig: router,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
    );
  }
}
