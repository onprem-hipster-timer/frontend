// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// 라우팅 설정 with 인증 리다이렉트 로직
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/auth/auth.dart';
import 'package:momeet/features/calendar/presentation/pages/calendar_page.dart';
import 'package:momeet/features/timer/presentation/pages/timer_page.dart';
import 'package:momeet/features/todo/todo.dart';
import 'package:momeet/features/tag/tag.dart';
import 'package:momeet/shared/widgets/scaffold_with_nav.dart';

/// GoRouter 인스턴스 (Riverpod 통합)
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    // 인증 상태 리다이렉트
    redirect: (context, state) {
      // 현재 인증 상태와 라우트 경로 확인
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      final isAuthLoading = ref.read(isAuthLoadingProvider);

      final isLoginRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password';

      // 1. 인증 초기화 중이면 로딩 페이지로
      if (isAuthLoading) {
        return '/loading';
      }

      // 2. 미인증 사용자가 보호된 페이지에 접근하려 하면 로그인 페이지로
      if (!isAuthenticated && !isLoginRoute) {
        return '/login?redirect=${state.matchedLocation}';
      }

      // 3. 인증된 사용자가 로그인 페이지에 있으면 메인 앱으로
      if (isAuthenticated && isLoginRoute) {
        return '/';
      }

      // 리다이렉트 없음
      return null;
    },

    initialLocation: '/',

    routes: [
      // ============================================================
      // 인증 페이지 (Floating Navigation 없음)
      // ============================================================
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          return const LoginPage();
        },
      ),

      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) {
          return const SignupPage();
        },
      ),

      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) {
          return const ForgotPasswordPage();
        },
      ),

      // ============================================================
      // 로딩 페이지
      // ============================================================
      GoRoute(
        path: '/loading',
        name: 'loading',
        builder: (context, state) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),

      // ============================================================
      // 메인 앱 (Floating Navigation 포함)
      // ============================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // Floating Navigation Bar와 함께 렌더링
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // 1. 캘린더 브랜치
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'calendar',
                builder: (context, state) => const CalendarPage(),
                routes: [
                  // 캘린더 하위 라우트
                  GoRoute(
                    path: 'schedule/detail',
                    name: 'schedule-detail',
                    builder: (context, state) {
                      final scheduleId = state.uri.queryParameters['id'];
                      return Scaffold(
                        appBar: AppBar(title: const Text('일정 상세')),
                        body: Center(child: Text('일정 상세 페이지 (ID: $scheduleId)')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // 2. 할 일 브랜치
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/todo',
                name: 'todo',
                builder: (context, state) => const TodoDashboardPage(),
                routes: [
                  // 특정 그룹의 상세 페이지
                  GoRoute(
                    path: '/:groupId',
                    name: 'todo-group-detail',
                    builder: (context, state) {
                      final groupId = state.pathParameters['groupId']!;
                      return TodoGroupDetailPage(groupId: groupId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // 3. 타이머 브랜치
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/timer',
                name: 'timer',
                builder: (context, state) => const TimerPage(),
                routes: [
                  // 타이머 하위 라우트
                  GoRoute(
                    path: 'detail',
                    name: 'timer-detail',
                    builder: (context, state) {
                      final timerId = state.uri.queryParameters['id'];
                      return Scaffold(
                        appBar: AppBar(title: const Text('타이머 상세')),
                        body: Center(child: Text('타이머 상세 페이지 (ID: $timerId)')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // 4. 태그 브랜치
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tags',
                name: 'tags',
                builder: (context, state) => const TagManagementPage(),
              ),
            ],
          ),

          // 5. 마이페이지 브랜치
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mypage',
                name: 'mypage',
                builder: (context, state) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('마이페이지')),
                    body: const Center(child: Text('마이페이지')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('오류')),
      body: Center(
        child: Text('페이지를 찾을 수 없습니다: ${state.error}'),
      ),
    ),
  );
});


/// 라우터 리스너 프로바이더 (네비게이션 이벤트 감지용)
final routeObserverProvider = Provider<NavigatorObserver>((ref) {
  return GoRouterObserver();
});

/// GoRouter 이벤트 감지
class GoRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (kDebugMode) {
      debugPrint('🔀 [ROUTE] Pushed: ${route.settings.name}');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (kDebugMode) {
      debugPrint('🔀 [ROUTE] Popped: ${route.settings.name}');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (kDebugMode) {
      debugPrint('🔀 [ROUTE] Replaced: ${oldRoute?.settings.name} → ${newRoute?.settings.name}');
    }
  }
}

