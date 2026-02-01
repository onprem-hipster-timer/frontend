/// 라우팅 설정 with 인증 리다이렉트 로직
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/home/presentation/pages/home_page.dart';

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

      // 3. 인증된 사용자가 로그인 페이지에 있으면 홈으로
      if (isAuthenticated && isLoginRoute) {
        return '/';
      }

      // 리다이렉트 없음
      return null;
    },

    initialLocation: '/',

    routes: [
      // ============================================================
      // 인증 페이지
      // ============================================================
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          // TODO: LoginPage 구현
          return Scaffold(
            appBar: AppBar(title: const Text('로그인')),
            body: Center(child: Text('로그인 페이지 (redirect to: $redirect)')),
          );
        },
      ),

      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) {
          // TODO: SignUpPage 구현
          return Scaffold(
            appBar: AppBar(title: const Text('회원가입')),
            body: const Center(child: Text('회원가입 페이지')),
          );
        },
      ),

      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) {
          // TODO: ForgotPasswordPage 구현
          return Scaffold(
            appBar: AppBar(title: const Text('비밀번호 재설정')),
            body: const Center(child: Text('비밀번호 재설정 페이지')),
          );
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
      // 메인 페이지
      // ============================================================
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      // ============================================================
      // 캘린더 페이지
      // ============================================================
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        builder: (context, state) {
          // TODO: CalendarPage 구현
          return Scaffold(
            appBar: AppBar(title: const Text('캘린더')),
            body: const Center(child: Text('캘린더 페이지')),
          );
        },
      ),

      GoRoute(
        path: '/schedule/detail',
        name: 'schedule-detail',
        builder: (context, state) {
          final scheduleId = state.uri.queryParameters['id'];
          // TODO: ScheduleDetailPage 구현
          return Scaffold(
            appBar: AppBar(title: const Text('일정 상세')),
            body: Center(child: Text('일정 상세 페이지 (ID: $scheduleId)')),
          );
        },
      ),

      // ============================================================
      // 할 일 페이지
      // ============================================================
      GoRoute(
        path: '/todo',
        name: 'todo',
        builder: (context, state) {
          // TODO: TodoListPage 구현
          return Scaffold(
            appBar: AppBar(title: const Text('할 일')),
            body: const Center(child: Text('할 일 페이지')),
          );
        },
      ),

      // ============================================================
      // 타이머 페이지
      // ============================================================
      GoRoute(
        path: '/timer',
        name: 'timer',
        builder: (context, state) {
          // TODO: TimerPage 구현
          return Scaffold(
            appBar: AppBar(title: const Text('타이머')),
            body: const Center(child: Text('타이머 페이지')),
          );
        },
      ),

      GoRoute(
        path: '/timer/detail',
        name: 'timer-detail',
        builder: (context, state) {
          final timerId = state.uri.queryParameters['id'];
          // TODO: TimerDetailPage 구현
          return Scaffold(
            appBar: AppBar(title: const Text('타이머 상세')),
            body: Center(child: Text('타이머 상세 페이지 (ID: $timerId)')),
          );
        },
      ),

      // ============================================================
      // 태그 관리 페이지
      // ============================================================
      GoRoute(
        path: '/tag',
        name: 'tag',
        builder: (context, state) {
          // TODO: TagManagementPage 구현
          return Scaffold(
            appBar: AppBar(title: const Text('태그 관리')),
            body: const Center(child: Text('태그 관리 페이지')),
          );
        },
      ),

      // ============================================================
      // 마이페이지
      // ============================================================
      GoRoute(
        path: '/mypage',
        name: 'mypage',
        builder: (context, state) {
          // TODO: MyPage 구현
          return Scaffold(
            appBar: AppBar(title: const Text('마이페이지')),
            body: const Center(child: Text('마이페이지')),
          );
        },
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
    print('🔀 [ROUTE] Pushed: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('🔀 [ROUTE] Popped: ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    print('🔀 [ROUTE] Replaced: ${oldRoute?.settings.name} → ${newRoute?.settings.name}');
  }
}
