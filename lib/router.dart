// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// 라우팅 설정 with 인증 리다이렉트 로직
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/my_profile_provider.dart';
import 'package:momeet/features/auth/auth.dart';
import 'package:momeet/features/calendar/presentation/pages/calendar_page.dart'
    deferred as calendar;
import 'package:momeet/features/calendar/presentation/pages/schedule_detail_page.dart'
    deferred as schedule_detail;
import 'package:momeet/features/timer/presentation/pages/timer_page.dart'
    deferred as timer;
import 'package:momeet/features/todo/todo.dart' deferred as todo;
import 'package:momeet/features/tag/tag.dart' deferred as tag;
import 'package:momeet/features/mypage/presentation/pages/mypage_page.dart'
    deferred as mypage;
import 'package:momeet/shared/widgets/deferred_widget.dart';
import 'package:momeet/shared/pages/security_warning_page.dart';
import 'package:momeet/shared/widgets/scaffold_with_nav.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/auth_redirect.dart';

export 'package:momeet/app_route.dart';

// ============================================================
// 리다이렉트 로직
// ============================================================

/// 인증 상태 변화를 GoRouter에 전달하는 Listenable
///
/// authProvider나 약관 동의 필요 여부가 바뀌면 notifyListeners()를 호출하여
/// GoRouter가 redirect를 재평가하도록 합니다.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AuthStatus>(authProvider, (previous, next) {
      notifyListeners();
    });
    ref.listen<bool?>(consentRequiredProvider, (previous, next) {
      notifyListeners();
    });
  }
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
        queryParameters: state.uri.queryParameters,
        consentRequired: ref.read(consentRequiredProvider),
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
        // extra: 로그인↔회원가입 폼 전환 시 이어받는 이메일(인메모리)
        // code: Google 로그인에서 돌아올 때 Kratos가 붙이는 값
        // flow: Google 이메일로 이미 가입된 계정이 있어 Kratos가 연결을 요청한 로그인 플로우
        builder: (context, state) => LoginPage(
          initialEmail: state.extra is String ? state.extra as String : null,
          googleCode: state.uri.queryParameters['code'],
          accountLinkFlowId: state.uri.queryParameters['flow'],
        ),
      ),

      GoRoute(
        path: AppRoute.signup.path,
        name: AppRoute.signup.name,
        // extra: 로그인↔회원가입 폼 전환 시 이어받는 이메일(인메모리)
        builder: (context, state) => SignupPage(
          initialEmail: state.extra is String ? state.extra as String : null,
        ),
      ),

      GoRoute(
        path: AppRoute.forgotPassword.path,
        name: AppRoute.forgotPassword.name,
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      GoRoute(
        path: AppRoute.verification.path,
        name: AppRoute.verification.name,
        // flow: 가입 화면이나 인증 메일 링크가 넘기는 인증 플로우 ID
        // extra: 가입 화면이 넘기는 이메일(인메모리)
        builder: (context, state) => VerificationPage(
          flowId: state.uri.queryParameters['flow'],
          email: state.extra is String ? state.extra as String : null,
        ),
      ),

      GoRoute(
        path: AppRoute.consent.path,
        name: AppRoute.consent.name,
        builder: (context, state) => const ConsentPage(),
      ),

      GoRoute(
        path: AppRoute.authError.path,
        name: AppRoute.authError.name,
        builder: (context, state) => const AuthErrorPage(),
      ),

      // ============================================================
      // 랜딩 페이지 (정적 HTML이 표시되므로 Flutter는 빈 화면)
      // ============================================================
      GoRoute(
        path: AppRoute.landing.path,
        name: AppRoute.landing.name,
        builder: (context, state) => const SizedBox.shrink(),
      ),

      // ============================================================
      // 로딩 페이지
      // ============================================================
      GoRoute(
        path: AppRoute.loading.path,
        name: AppRoute.loading.name,
        builder: (context, state) => const Scaffold(body: AppLoading()),
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
                builder: (context, state) => DeferredWidget(
                  loader: calendar.loadLibrary,
                  builder: (_) => calendar.CalendarPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'schedule/detail',
                    name: AppRoute.scheduleDetail.name,
                    builder: (context, state) {
                      final scheduleId = state.uri.queryParameters['id'];
                      if (scheduleId == null) {
                        return const Scaffold(
                          body: Center(child: Text('잘못된 접근입니다')),
                        );
                      }
                      return DeferredWidget(
                        loader: schedule_detail.loadLibrary,
                        builder: (_) => schedule_detail.ScheduleDetailPage(
                          scheduleId: scheduleId,
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
                builder: (context, state) => DeferredWidget(
                  loader: todo.loadLibrary,
                  builder: (_) => todo.TodoDashboardPage(),
                ),
                routes: [
                  GoRoute(
                    path: ':groupId',
                    name: AppRoute.todoGroupDetail.name,
                    builder: (context, state) {
                      final groupId = state.pathParameters['groupId']!;
                      return DeferredWidget(
                        loader: todo.loadLibrary,
                        builder: (_) =>
                            todo.TodoGroupDetailPage(groupId: groupId),
                      );
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
                builder: (context, state) => DeferredWidget(
                  loader: timer.loadLibrary,
                  builder: (_) => timer.TimerPage(),
                ),
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
                builder: (context, state) => DeferredWidget(
                  loader: tag.loadLibrary,
                  builder: (_) => tag.TagManagementPage(),
                ),
              ),
            ],
          ),

          // 5. 마이페이지 브랜치
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.mypage.path,
                name: AppRoute.mypage.name,
                builder: (context, state) => DeferredWidget(
                  loader: mypage.loadLibrary,
                  builder: (_) => mypage.MyPage(),
                ),
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
