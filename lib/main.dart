import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'firebase_options.dart';
import 'core/theme/theme_provider.dart' as core;
import 'core/theme/theme_provider.dart' show AppTheme;
import 'package:flutter/material.dart' as flutter;
import 'core/router/router_provider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configurations
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    if (kDebugMode)
      print('⚠️ .env file not found, using environment variables only.');
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: QuickPMApp()));
}

class QuickPMApp extends ConsumerWidget {
  const QuickPMApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(core.themeProvider);
    final isDark = themeMode == core.ThemeMode.dark;
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '抖书',
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
