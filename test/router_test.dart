import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/router.dart';

void main() {
  // ============================================================
  // AppRoute enum 테스트
  // ============================================================
  group('AppRoute', () {
    test('공개 라우트는 requiresAuth가 false이다', () {
      expect(AppRoute.login.requiresAuth, false);
      expect(AppRoute.signup.requiresAuth, false);
      expect(AppRoute.forgotPassword.requiresAuth, false);
      expect(AppRoute.loading.requiresAuth, false);
    });

    test('보호된 라우트는 requiresAuth가 true이다', () {
      expect(AppRoute.calendar.requiresAuth, true);
      expect(AppRoute.todo.requiresAuth, true);
      expect(AppRoute.timer.requiresAuth, true);
      expect(AppRoute.tags.requiresAuth, true);
      expect(AppRoute.mypage.requiresAuth, true);
    });

    test('publicPaths에 공개 라우트만 포함된다', () {
      expect(AppRoute.publicPaths, contains(AppRoute.login.path));
      expect(AppRoute.publicPaths, contains(AppRoute.signup.path));
      expect(AppRoute.publicPaths, contains(AppRoute.forgotPassword.path));
      expect(AppRoute.publicPaths, contains(AppRoute.loading.path));
    });

    test('publicPaths에 보호된 라우트가 포함되지 않는다', () {
      expect(AppRoute.publicPaths, isNot(contains(AppRoute.calendar.path)));
      expect(AppRoute.publicPaths, isNot(contains(AppRoute.todo.path)));
      expect(AppRoute.publicPaths, isNot(contains(AppRoute.timer.path)));
      expect(AppRoute.publicPaths, isNot(contains(AppRoute.tags.path)));
      expect(AppRoute.publicPaths, isNot(contains(AppRoute.mypage.path)));
    });
  });

  // ============================================================
  // authRedirect 순수 함수 테스트
  // ============================================================
  group('authRedirect', () {
    // ----------------------------------------------------------
    // 로딩 상태
    // ----------------------------------------------------------
    group('로딩 상태', () {
      test('로딩 중일 때 /loading으로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: true,
          matchedLocation: AppRoute.calendar.path,
        );
        expect(result, AppRoute.loading.path);
      });

      test('로딩 중이면 어떤 경로든 /loading으로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: true,
          matchedLocation: AppRoute.todo.path,
        );
        expect(result, AppRoute.loading.path);
      });

      test('로딩 중이면 로그인 페이지에서도 /loading으로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: true,
          matchedLocation: AppRoute.login.path,
        );
        expect(result, AppRoute.loading.path);
      });
    });

    // ----------------------------------------------------------
    // 미인증 상태
    // ----------------------------------------------------------
    group('미인증 상태', () {
      test('미인증 사용자가 보호된 경로에 접근하면 /login으로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.calendar.path,
        );
        expect(result, '${AppRoute.login.path}?redirect=${AppRoute.calendar.path}');
      });

      test('미인증 사용자가 /todo에 접근하면 redirect 파라미터와 함께 /login으로 보낸다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.todo.path,
        );
        expect(result, '${AppRoute.login.path}?redirect=${AppRoute.todo.path}');
      });

      test('미인증 사용자가 /login에 있으면 리다이렉트하지 않는다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
        );
        expect(result, isNull);
      });

      test('미인증 사용자가 /signup에 있으면 리다이렉트하지 않는다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.signup.path,
        );
        expect(result, isNull);
      });

      test('미인증 사용자가 /forgot-password에 있으면 리다이렉트하지 않는다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.forgotPassword.path,
        );
        expect(result, isNull);
      });
    });

    // ----------------------------------------------------------
    // 인증 상태
    // ----------------------------------------------------------
    group('인증 상태', () {
      test('인증된 사용자가 /login에 있으면 /로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
        );
        expect(result, AppRoute.calendar.path);
      });

      test('인증된 사용자가 /signup에 있으면 /로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.signup.path,
        );
        expect(result, AppRoute.calendar.path);
      });

      test('인증된 사용자가 /forgot-password에 있으면 /로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.forgotPassword.path,
        );
        expect(result, AppRoute.calendar.path);
      });

      test('인증된 사용자가 /에 있으면 리다이렉트하지 않는다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.calendar.path,
        );
        expect(result, isNull);
      });

      test('인증된 사용자가 /todo에 있으면 리다이렉트하지 않는다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.todo.path,
        );
        expect(result, isNull);
      });

      test('인증된 사용자가 /timer에 있으면 리다이렉트하지 않는다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.timer.path,
        );
        expect(result, isNull);
      });
    });
  });
}
