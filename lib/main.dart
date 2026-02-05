import 'dart:ui';
import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter/material.dart' as flutter show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// actually the lint said unused so I can remove google_fonts.

// Import features
import 'features/onboarding/presentation/onboarding_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/feed/presentation/feed_page.dart';
import 'features/lab/presentation/lab_page.dart';
import 'features/war_room/presentation/war_room_page.dart';
import 'features/profile/presentation/profile_page.dart';
import 'features/explore/presentation/explore_page.dart';
import 'features/home/presentation/module_detail_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/theme_provider.dart' as core show ThemeMode;

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: QuickPMApp()));
}

// Router Configuration
final _router = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        final tabParam = state.uri.queryParameters['tab'];
        final initialTab = tabParam != null ? int.tryParse(tabParam) : null;
        return HomePage(initialTab: initialTab);
      },
    ),
    GoRoute(
      path: '/explore',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ExplorePage(),
      ),
    ),
    GoRoute(
      path: '/feed/:moduleId',
      pageBuilder: (context, state) {
        final moduleId = state.pathParameters['moduleId']!;
        return NoTransitionPage(
          child: FeedPage(moduleId: moduleId),
        );
      },
    ),
    GoRoute(
      path: '/lab',
      builder: (context, state) => const LabPage(),
    ),
    GoRoute(
      path: '/war-room',
      builder: (context, state) => const WarRoomPage(),
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) {
        final query = state.uri.queryParameters['q'] ?? '';
        return NoTransitionPage(
          child: FeedPage(moduleId: 'SEARCH', searchQuery: query),
        );
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/module/:moduleId',
      pageBuilder: (context, state) {
        final moduleId = state.pathParameters['moduleId']!;
        return NoTransitionPage(
          child: ModuleDetailPage(moduleId: moduleId),
        );
      },
    ),
  ],
);

class QuickPMApp extends ConsumerWidget {
  const QuickPMApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == core.ThemeMode.dark;

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
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
