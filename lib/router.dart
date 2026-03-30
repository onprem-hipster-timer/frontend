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
import 'package:momeet/features/calendar/calendar.dart';
import 'package:momeet/features/timer/timer.dart';
import 'package:momeet/features/todo/todo.dart';
import 'package:momeet/features/tag/tag.dart';
import 'package:momeet/features/mypage/mypage.dart';
import 'package:momeet/shared/pages/security_warning_page.dart';
import 'package:momeet/shared/widgets/scaffold_with_nav.dart';

// ============================================================
// 라우트 정의
// ============================================================

/// 앱의 모든 라우트를 정의하는 enum
///
/// 각 라우트는 경로(path)와 인증 필요 여부(requiresAuth)를 포함합니다.
/// 새로운 페이지를 추가할 때 이 enum에만 등록하면 리다이렉트 로직이 자동 적용됩니다.
///
/// 사용 예:
/// ```dart
/// context.go(AppRoute.todo.path);
/// ```
enum AppRoute {
  // 인증 불필요 (공개 페이지)
  login(path: '/login', requiresAuth: false),
  signup(path: '/signup', requiresAuth: false),
  forgotPassword(path: '/forgot-password', requiresAuth: false),
  loading(path: '/loading', requiresAuth: false),
  securityWarning(path: '/security-warning', requiresAuth: false),

  // 인증 필요 (보호된 페이지)
  calendar(path: '/'),
  scheduleDetail(path: '/schedule/detail'),
  todo(path: '/todo'),
  todoGroupDetail(path: '/todo/:groupId'),
  timer(path: '/timer'),
  timerDetail(path: '/timer/detail'),
  tags(path: '/tags'),
  mypage(path: '/mypage');

  const AppRoute({required this.path, this.requiresAuth = true});

  /// 라우트 경로
  final String path;

  /// 인증 필요 여부 (기본값: true)
  final bool requiresAuth;

  /// 공개 라우트(인증 불필요) 경로 집합
  static final publicPaths = {
    for (final route in values)
      if (!route.requiresAuth) route.path,
  };

  /// 보호된 라우트의 경로 패턴 (RegExp) 목록
  ///
  /// `:param` 세그먼트를 `[^/]+` 정규식으로 변환하여
  /// `/todo/abc-123` 같은 동적 경로도 매칭합니다.
  static final _protectedPatterns = [
    for (final route in values)
      if (route.requiresAuth)
        RegExp(
          '^${route.path.replaceAllMapped(RegExp(r':(\w+)'), (_) => r'[^/]+')}\$',
        ),
  ];

  /// 주어진 경로가 등록된 보호 라우트와 매칭되는지 확인
  static bool isKnownProtectedPath(String path) {
    return _protectedPatterns.any((pattern) => pattern.hasMatch(path));
  }
}

// ============================================================
// 리다이렉트 로직
// ============================================================

/// 인증 상태 변화를 GoRouter에 전달하는 Listenable
///
/// authProvider의 상태가 변경되면 notifyListeners()를 호출하여
/// GoRouter가 redirect를 재평가하도록 합니다.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AuthStatus>(authProvider, (previous, next) {
      notifyListeners();
    });
  }
}

/// redirect 경로가 안전한 내부 경로인지 검증 (Open Redirect 방지)
///
/// 허용 조건:
/// - `/`로 시작하는 상대 경로
/// - `//`로 시작하지 않음 (프로토콜 상대 URL 차단)
/// - `://` 포함하지 않음 (절대 URL 차단)
/// - AppRoute enum에 등록된 보호 경로와 매칭 (화이트리스트)
@visibleForTesting
bool isValidRedirectPath(String path) {
  if (path.isEmpty) return false;
  if (!path.startsWith('/')) return false;
  if (path.startsWith('//')) return false;
  if (path.contains('://')) return false;
  if (!AppRoute.isKnownProtectedPath(path)) return false;
  return true;
}

/// 인증 상태에 따른 리다이렉트 로직 (순수 함수 — 테스트 가능)
///
/// 반환값이 null이면 리다이렉트 없음.
String? authRedirect({
  required bool isAuthenticated,
  required bool isAuthLoading,
  required String matchedLocation,
  String? redirectAfterLogin,
}) {
  final isPublicRoute = AppRoute.publicPaths.contains(matchedLocation);

  // 1. 인증 초기화 중이면 로딩 페이지로
  if (isAuthLoading) {
    return matchedLocation == AppRoute.loading.path
        ? null
        : AppRoute.loading.path;
  }

  // 1-1. 로딩이 끝났는데 로딩 페이지에 남아 있으면 탈출
  if (matchedLocation == AppRoute.loading.path) {
    return isAuthenticated ? AppRoute.calendar.path : AppRoute.login.path;
  }

  // 2. 미인증 사용자가 보호된 페이지에 접근하려 하면 로그인 페이지로
  if (!isAuthenticated && !isPublicRoute) {
    return '${AppRoute.login.path}?redirect=$matchedLocation';
  }

  // 3. 인증된 사용자가 공개 페이지에 있으면 원래 목적지 또는 메인 앱으로
  if (isAuthenticated && isPublicRoute) {
    if (redirectAfterLogin != null && redirectAfterLogin.isNotEmpty) {
      if (isValidRedirectPath(redirectAfterLogin)) {
        return redirectAfterLogin;
      }
      if (!AppRoute.publicPaths.contains(redirectAfterLogin)) {
        return '${AppRoute.securityWarning.path}?blocked=${Uri.encodeComponent(redirectAfterLogin)}';
      }
    }
    return AppRoute.calendar.path;
  }

  // 리다이렉트 없음
  return null;
}

/// GoRouter 인스턴스 (Riverpod 통합)
final routerProvider = Provider<GoRouter>((ref) {
  final authChangeNotifier = _AuthChangeNotifier(ref);

  return GoRouter(
    // 인증 상태 변화 시 redirect 재평가
    refreshListenable: authChangeNotifier,

    // 인증 상태 리다이렉트
    redirect: (context, state) {
      return authRedirect(
        isAuthenticated: ref.read(isAuthenticatedProvider),
        isAuthLoading: ref.read(isAuthLoadingProvider),
        matchedLocation: state.matchedLocation,
        redirectAfterLogin: state.uri.queryParameters['redirect'],
      );
    },

    initialLocation: AppRoute.calendar.path,

    routes: [
      // ============================================================
      // 인증 페이지 (Floating Navigation 없음)
      // ============================================================
      GoRoute(
        path: AppRoute.login.path,
        name: AppRoute.login.name,
        builder: (context, state) => const LoginPage(),
      ),

      GoRoute(
        path: AppRoute.signup.path,
        name: AppRoute.signup.name,
        builder: (context, state) => const SignupPage(),
      ),

      GoRoute(
        path: AppRoute.forgotPassword.path,
        name: AppRoute.forgotPassword.name,
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      // ============================================================
      // 로딩 페이지
      // ============================================================
      GoRoute(
        path: AppRoute.loading.path,
        name: AppRoute.loading.name,
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),

      // ============================================================
      // 보안 경고 페이지
      // ============================================================
      GoRoute(
        path: AppRoute.securityWarning.path,
        name: AppRoute.securityWarning.name,
        builder: (context, state) => SecurityWarningPage(
          attemptedUrl: state.uri.queryParameters['blocked'],
        ),
      ),

      // ============================================================
      // 메인 앱 (Floating Navigation 포함)
      // ============================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // 1. 캘린더 브랜치
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.calendar.path,
                name: AppRoute.calendar.name,
                builder: (context, state) => const CalendarPage(),
                routes: [
                  GoRoute(
                    path: 'schedule/detail',
                    name: AppRoute.scheduleDetail.name,
                    builder: (context, state) {
                      final scheduleId = state.uri.queryParameters['id'];
                      return Scaffold(
                        appBar: AppBar(title: const Text('일정 상세')),
                        body: Center(
                          child: Text('일정 상세 페이지 (ID: $scheduleId)'),
                        ),
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
                path: AppRoute.todo.path,
                name: AppRoute.todo.name,
                builder: (context, state) => const TodoDashboardPage(),
                routes: [
                  GoRoute(
                    path: '/:groupId',
                    name: AppRoute.todoGroupDetail.name,
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
                path: AppRoute.timer.path,
                name: AppRoute.timer.name,
                builder: (context, state) => const TimerPage(),
                routes: [
                  GoRoute(
                    path: 'detail',
                    name: AppRoute.timerDetail.name,
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
                path: AppRoute.tags.path,
                name: AppRoute.tags.name,
                builder: (context, state) => const TagManagementPage(),
              ),
            ],
          ),

          // 5. 마이페이지 브랜치
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.mypage.path,
                name: AppRoute.mypage.name,
                builder: (context, state) => const MyPage(),
              ),
            ],
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('오류')),
      body: Center(child: Text('페이지를 찾을 수 없습니다: ${state.error}')),
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
      debugPrint(
        '🔀 [ROUTE] Replaced: ${oldRoute?.settings.name} → ${newRoute?.settings.name}',
      );
    }
  }
}
