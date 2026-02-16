import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/router.dart';

void main() {
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
          matchedLocation: '/',
        );
        expect(result, '/loading');
      });

      test('로딩 중이면 어떤 경로든 /loading으로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: true,
          matchedLocation: '/todo',
        );
        expect(result, '/loading');
      });

      test('로딩 중이면 로그인 페이지에서도 /loading으로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: true,
          matchedLocation: '/login',
        );
        expect(result, '/loading');
      });
    });

    // ----------------------------------------------------------
    // 미인증 상태
    // ----------------------------------------------------------
    group('미인증 상태', () {
      test('미인증 사용자가 /에 접근하면 /login으로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: '/',
        );
        expect(result, contains('/login'));
        expect(result, '/login?redirect=/');
      });

      test('미인증 사용자가 /todo에 접근하면 redirect 파라미터와 함께 /login으로 보낸다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: '/todo',
        );
        expect(result, '/login?redirect=/todo');
      });

      test('미인증 사용자가 /login에 있으면 리다이렉트하지 않는다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: '/login',
        );
        expect(result, isNull);
      });

      test('미인증 사용자가 /signup에 있으면 리다이렉트하지 않는다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: '/signup',
        );
        expect(result, isNull);
      });

      test('미인증 사용자가 /forgot-password에 있으면 리다이렉트하지 않는다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: '/forgot-password',
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
          matchedLocation: '/login',
        );
        expect(result, '/');
      });

      test('인증된 사용자가 /signup에 있으면 /로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: '/signup',
        );
        expect(result, '/');
      });

      test('인증된 사용자가 /forgot-password에 있으면 /로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: '/forgot-password',
        );
        expect(result, '/');
      });

      test('인증된 사용자가 /에 있으면 리다이렉트하지 않는다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: '/',
        );
        expect(result, isNull);
      });

      test('인증된 사용자가 /todo에 있으면 리다이렉트하지 않는다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: '/todo',
        );
        expect(result, isNull);
      });

      test('인증된 사용자가 /timer에 있으면 리다이렉트하지 않는다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: '/timer',
        );
        expect(result, isNull);
      });
    });
  });
}
