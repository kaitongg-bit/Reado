import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/feed/presentation/feed_page.dart';
import '../../features/explore/presentation/explore_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/lab/presentation/lab_page.dart';
import '../../features/lab/presentation/task_center_page.dart';
import '../../features/war_room/presentation/war_room_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/home/presentation/module_detail_page.dart';
import '../../features/feed/presentation/feed_provider.dart';
import '../../features/feed/presentation/shared_feed_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/notes/presentation/ai_notes_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/credit_provider.dart';
import '../../features/profile/presentation/hidden_content_page.dart';
import '../../features/profile/presentation/about_page.dart';
import '../../features/search/presentation/search_results_page.dart';
import '../../features/admin/presentation/admin_page.dart';

// 全局 Key，确保在任何地方都能准确触发提示和跳转
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Web 下用浏览器 hash 作为首屏路由，否则直接打开分享链接会先被 initialLocation 带到 onboarding
String _initialLocation() {
  final fragment = Uri.base.fragment;
  if (fragment.isNotEmpty && fragment.startsWith('/')) {
    return fragment;
  }
  return '/onboarding';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: _initialLocation(),
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggingIn = state.matchedLocation == '/onboarding';
      final ref = state.uri.queryParameters['ref'];

      if (user == null) {
        // 游客通过分享链接可访问模块详情和只读 Feed
        final isSharedModule =
            state.matchedLocation.startsWith('/module/') && ref != null;
        final isSharedFeed =
            state.matchedLocation.startsWith('/shared-feed/');
        if (isSharedFeed) {
          if (ref == null) return '/onboarding';
          return null;
        }
        if (isSharedModule) return null;
        // 未登录用户只能看 Onboarding
        return isLoggingIn ? null : '/onboarding';
      }

      // 已登录用户离开 Onboarding：若有 returnUrl 则跳回分享页
      // 兼容：地址栏常被解析成解码形式，returnUrl 会被第一个 ? 截断，ref/afterLogin 变成独立参数，这里拼回完整路径
      if (isLoggingIn) {
        final returnUrl = state.uri.queryParameters['returnUrl'];
        final refParam = state.uri.queryParameters['ref'];
        final afterLoginParam = state.uri.queryParameters['afterLogin'];
        if (returnUrl != null && returnUrl.isNotEmpty) {
          String path = returnUrl.contains('%') ? Uri.decodeComponent(returnUrl) : returnUrl;
          if (refParam != null && !path.contains('ref=')) {
            path = '$path?ref=$refParam&afterLogin=${afterLoginParam ?? 'save'}';
          }
          return path;
        }
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) {
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
          return const OnboardingPage();
        },
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/ai-notes',
        builder: (context, state) => const AiNotesPage(),
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
          final indexStr = state.uri.queryParameters['index'];
          final initialIndex = indexStr != null ? int.tryParse(indexStr) : null;

          return NoTransitionPage(
            child: FeedPage(
              moduleId: moduleId,
              initialIndex: initialIndex,
            ),
          );
        },
      ),
      GoRoute(
        path: '/lab',
        builder: (context, state) => const LabPage(),
      ),
      GoRoute(
        path: '/task-center',
        builder: (context, state) => const TaskCenterPage(),
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
        path: '/shared-feed/:moduleId',
        pageBuilder: (context, state) {
          final moduleId = state.pathParameters['moduleId']!;
          final ownerId = state.uri.queryParameters['ref'];
          final indexStr = state.uri.queryParameters['index'];
          final initialIndex =
              indexStr != null ? int.tryParse(indexStr) : null;

          // --- 追踪分享点击（与 /onboarding、/module 一致，避免分享到本页时漏统计）---
          if (ownerId != null) {
            Future.microtask(() async {
              final dataService = ref.read(dataServiceProvider);
              await dataService.logShareClick(ownerId);
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              if (currentUserId == ownerId) {
                ref.read(creditProvider.notifier).refresh();
              }
            });
          }
          // -------------------------------------------------------------------------

          if (ownerId == null) {
            return NoTransitionPage(
                child: ModuleDetailPage(moduleId: moduleId));
          }
          return NoTransitionPage(
            child: SharedFeedPage(
              moduleId: moduleId,
              ownerId: ownerId,
              initialIndex: initialIndex,
            ),
          );
        },
      ),
      GoRoute(
        path: '/module/:moduleId',
        pageBuilder: (context, state) {
          final moduleId = state.pathParameters['moduleId']!;
          final ownerId = state.uri.queryParameters['ref'];

          // --- 追踪分享点击 ---
          if (ownerId != null) {
            Future.microtask(() async {
              final dataService = ref.read(dataServiceProvider);
              await dataService.logShareClick(ownerId);

              // 如果分享者就是当前用户，立即刷新本地状态
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              if (currentUserId == ownerId) {
                ref.read(creditProvider.notifier).refresh();
              }
            });
          }
          // ------------------

          final afterLoginSave =
              state.uri.queryParameters['afterLogin'] == 'save';
          return NoTransitionPage(
            child: ModuleDetailPage(
              moduleId: moduleId,
              ownerId: ownerId,
              afterLoginSave: afterLoginSave,
            ),
          );
        },
      ),
    ],
  );
});
