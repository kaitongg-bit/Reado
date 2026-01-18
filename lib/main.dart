import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// Import features (Placeholders for now, will create files next)
import 'features/onboarding/presentation/onboarding_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/feed/presentation/feed_page.dart';
// Note: Actual imports would be added as files are created.

void main() {
  runApp(const ProviderScope(child: QuickPMApp()));
}

/// Router Configuration
final _router = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/feed/:moduleId',
      builder: (context, state) {
        final moduleId = state.pathParameters['moduleId']!;
        return FeedPage(moduleId: moduleId);
      },
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) {
        final query = state.uri.queryParameters['q'] ?? '';
        return FeedPage(moduleId: 'SEARCH', searchQuery: query);
      },
    ),
    // Define other routes here
  ],
);

class QuickPMApp extends StatelessWidget {
  const QuickPMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'QuickPM',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Professional Blue
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
      ),
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
