import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/feed/presentation/feed_page.dart';
import '../../features/explore/presentation/explore_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/lab/presentation/lab_page.dart';
import '../../features/war_room/presentation/war_room_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/home/presentation/module_detail_page.dart';
import '../../features/feed/presentation/feed_provider.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/credit_provider.dart';
import '../../features/profile/presentation/hidden_content_page.dart';
import '../../features/profile/presentation/about_page.dart';
import '../../features/search/presentation/search_results_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggingIn = state.matchedLocation == '/onboarding';
      final isSharedLink = state.matchedLocation.startsWith('/module/');

      if (user == null) {
        // 未登录用户只能看 Onboarding 或 分享链接
        return (isLoggingIn || isSharedLink) ? null : '/onboarding';
      }

      // 已登录用户不能去 Onboarding
      if (isLoggingIn) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
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
            child: SearchResultsPage(query: query),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
        routes: [
          GoRoute(
            path: 'hidden',
            builder: (context, state) => const HiddenContentPage(),
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/module/:moduleId',
        pageBuilder: (context, state) {
          final moduleId = state.pathParameters['moduleId']!;

          // --- 追踪分享点击 ---
          final referrerId = state.uri.queryParameters['ref'];
          if (referrerId != null) {
            Future.microtask(() async {
              final dataService = ref.read(dataServiceProvider);
              await dataService.logShareClick(referrerId);

              // 如果分享者就是当前用户，立即刷新本地状态
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              if (currentUserId == referrerId) {
                ref.read(creditProvider.notifier).refresh();
              }
            });
          }
          // ------------------

          return NoTransitionPage(
            child: ModuleDetailPage(moduleId: moduleId),
          );
        },
      ),
    ],
  );
});
