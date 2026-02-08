// 라우팅 설정 with 인증 리다이렉트 로직
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/auth/auth.dart';
import 'package:momeet/features/calendar/presentation/pages/calendar_page.dart';
import 'package:momeet/features/home/presentation/pages/home_page.dart';
import 'package:momeet/features/todo/todo.dart';

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

      // 3. 인증된 사용자가 로그인 페이지에 있으면 캘린더로
      if (isAuthenticated && isLoginRoute) {
        return '/calendar';
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
          return const CalendarPage();
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
          final groupId = state.uri.queryParameters['group_id'];
          return TodoListPage(groupId: groupId);
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
