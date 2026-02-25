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
      expect(AppRoute.securityWarning.requiresAuth, false);
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
      expect(AppRoute.publicPaths, contains(AppRoute.securityWarning.path));
    });

    test('publicPaths에 보호된 라우트가 포함되지 않는다', () {
      expect(AppRoute.publicPaths, isNot(contains(AppRoute.calendar.path)));
      expect(AppRoute.publicPaths, isNot(contains(AppRoute.todo.path)));
      expect(AppRoute.publicPaths, isNot(contains(AppRoute.timer.path)));
      expect(AppRoute.publicPaths, isNot(contains(AppRoute.tags.path)));
      expect(AppRoute.publicPaths, isNot(contains(AppRoute.mypage.path)));
    });

    group('isKnownProtectedPath', () {
      test('등록된 보호 경로를 인식한다', () {
        expect(AppRoute.isKnownProtectedPath('/'), true);
        expect(AppRoute.isKnownProtectedPath('/todo'), true);
        expect(AppRoute.isKnownProtectedPath('/timer'), true);
        expect(AppRoute.isKnownProtectedPath('/tags'), true);
        expect(AppRoute.isKnownProtectedPath('/mypage'), true);
        expect(AppRoute.isKnownProtectedPath('/schedule/detail'), true);
        expect(AppRoute.isKnownProtectedPath('/timer/detail'), true);
      });

      test('파라미터가 포함된 동적 경로를 인식한다', () {
        expect(AppRoute.isKnownProtectedPath('/todo/abc-123'), true);
        expect(AppRoute.isKnownProtectedPath('/todo/some-group-id'), true);
      });

      test('등록되지 않은 경로를 거부한다', () {
        expect(AppRoute.isKnownProtectedPath('/unknown'), false);
        expect(AppRoute.isKnownProtectedPath('/admin'), false);
        expect(AppRoute.isKnownProtectedPath('/api/users'), false);
        expect(AppRoute.isKnownProtectedPath('/settings'), false);
      });

      test('공개 경로를 거부한다', () {
        expect(AppRoute.isKnownProtectedPath('/login'), false);
        expect(AppRoute.isKnownProtectedPath('/signup'), false);
        expect(AppRoute.isKnownProtectedPath('/forgot-password'), false);
        expect(AppRoute.isKnownProtectedPath('/loading'), false);
      });

      test('빈 문자열을 거부한다', () {
        expect(AppRoute.isKnownProtectedPath(''), false);
      });
    });
  });

  // ============================================================
  // isValidRedirectPath 검증 함수 테스트
  // ============================================================
  group('isValidRedirectPath', () {
    test('유효한 내부 경로를 허용한다', () {
      expect(isValidRedirectPath('/mypage'), true);
      expect(isValidRedirectPath('/todo'), true);
      expect(isValidRedirectPath('/timer'), true);
      expect(isValidRedirectPath('/tags'), true);
    });

    test('빈 문자열을 거부한다', () {
      expect(isValidRedirectPath(''), false);
    });

    test('/로 시작하지 않는 경로를 거부한다', () {
      expect(isValidRedirectPath('mypage'), false);
      expect(isValidRedirectPath('todo'), false);
    });

    test('외부 URL(https://)을 거부한다', () {
      expect(isValidRedirectPath('https://evil.com'), false);
    });

    test('외부 URL(http://)을 거부한다', () {
      expect(isValidRedirectPath('http://evil.com'), false);
    });

    test('프로토콜 상대 URL(//)을 거부한다', () {
      expect(isValidRedirectPath('//evil.com'), false);
      expect(isValidRedirectPath('//evil.com/path'), false);
    });

    test('javascript: URI를 거부한다', () {
      expect(isValidRedirectPath('javascript:alert(1)'), false);
    });

    test('data: URI를 거부한다', () {
      expect(isValidRedirectPath('data:text/html,<h1>x</h1>'), false);
    });

    test('경로 내에 ://가 포함된 값을 거부한다', () {
      expect(isValidRedirectPath('/page?url=https://evil.com'), false);
    });

    test('공개 경로를 거부한다', () {
      expect(isValidRedirectPath('/login'), false);
      expect(isValidRedirectPath('/signup'), false);
      expect(isValidRedirectPath('/forgot-password'), false);
      expect(isValidRedirectPath('/loading'), false);
    });

    test('등록되지 않은 내부 경로를 거부한다 (화이트리스트)', () {
      expect(isValidRedirectPath('/unknown'), false);
      expect(isValidRedirectPath('/admin'), false);
      expect(isValidRedirectPath('/api/users'), false);
      expect(isValidRedirectPath('/settings'), false);
      expect(isValidRedirectPath('/.env'), false);
    });

    test('파라미터가 포함된 등록 경로를 허용한다', () {
      expect(isValidRedirectPath('/todo/group-abc'), true);
      expect(isValidRedirectPath('/todo/123'), true);
    });

    test('등록된 보호 경로를 허용한다', () {
      expect(isValidRedirectPath('/schedule/detail'), true);
      expect(isValidRedirectPath('/timer/detail'), true);
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

      test('로딩 중이고 이미 /loading에 있으면 리다이렉트하지 않는다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: true,
          matchedLocation: AppRoute.loading.path,
        );
        expect(result, isNull);
      });
    });

    // ----------------------------------------------------------
    // /loading 탈출 로직
    // ----------------------------------------------------------
    group('로딩 페이지 탈출', () {
      test('로딩 끝나고 미인증이면 /loading에서 /login으로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.loading.path,
        );
        expect(result, AppRoute.login.path);
      });

      test('로딩 끝나고 인증이면 /loading에서 /로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.loading.path,
        );
        expect(result, AppRoute.calendar.path);
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
        expect(result,
            '${AppRoute.login.path}?redirect=${AppRoute.calendar.path}');
      });

      test('미인증 사용자가 /todo에 접근하면 redirect 파라미터와 함께 /login으로 보낸다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.todo.path,
        );
        expect(result, '${AppRoute.login.path}?redirect=${AppRoute.todo.path}');
      });

      test('미인증 사용자가 /mypage에 접근하면 redirect 파라미터와 함께 /login으로 보낸다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.mypage.path,
        );
        expect(
            result, '${AppRoute.login.path}?redirect=${AppRoute.mypage.path}');
      });

      test('미인증 사용자가 /tags에 접근하면 redirect 파라미터와 함께 /login으로 보낸다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.tags.path,
        );
        expect(result, '${AppRoute.login.path}?redirect=${AppRoute.tags.path}');
      });

      test('미인증 사용자가 /timer에 접근하면 redirect 파라미터와 함께 /login으로 보낸다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.timer.path,
        );
        expect(
            result, '${AppRoute.login.path}?redirect=${AppRoute.timer.path}');
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

      test('인증된 사용자가 /mypage에 있으면 리다이렉트하지 않는다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.mypage.path,
        );
        expect(result, isNull);
      });
    });

    // ----------------------------------------------------------
    // redirectAfterLogin 파라미터
    // ----------------------------------------------------------
    group('redirectAfterLogin 파라미터', () {
      test('로그인 후 redirect 파라미터가 있으면 해당 경로로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: AppRoute.mypage.path,
        );
        expect(result, AppRoute.mypage.path);
      });

      test('로그인 후 redirect 파라미터가 /todo이면 /todo로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: AppRoute.todo.path,
        );
        expect(result, AppRoute.todo.path);
      });

      test('로그인 후 redirect 파라미터가 /timer이면 /timer로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: AppRoute.timer.path,
        );
        expect(result, AppRoute.timer.path);
      });

      test('로그인 후 redirect 파라미터가 null이면 /로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: null,
        );
        expect(result, AppRoute.calendar.path);
      });

      test('로그인 후 redirect 파라미터가 빈 문자열이면 /로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: '',
        );
        expect(result, AppRoute.calendar.path);
      });

      test('미인증 상태에서는 redirect 파라미터가 무시된다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: AppRoute.mypage.path,
        );
        expect(result, isNull);
      });

      test('로그아웃 → 로그인 전체 흐름에서 redirect가 동작한다', () {
        // 1. 인증된 사용자가 /mypage에 있음
        final step1 = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.mypage.path,
        );
        expect(step1, isNull);

        // 2. 로그아웃 → /login?redirect=/mypage로 리다이렉트
        final step2 = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.mypage.path,
        );
        expect(
            step2, '${AppRoute.login.path}?redirect=${AppRoute.mypage.path}');

        // 3. 로그인 성공 → redirect 파라미터로 /mypage 복원
        final step3 = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: AppRoute.mypage.path,
        );
        expect(step3, AppRoute.mypage.path);
      });
    });

    // ----------------------------------------------------------
    // Open Redirect 보안 검증
    // ----------------------------------------------------------
    group('Open Redirect 방어', () {
      String securityWarningWith(String blocked) =>
          '${AppRoute.securityWarning.path}?blocked=${Uri.encodeComponent(blocked)}';

      test('외부 URL(https://evil.com)이면 보안 경고 페이지로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: 'https://evil.com',
        );
        expect(result, securityWarningWith('https://evil.com'));
      });

      test('외부 URL(http://evil.com)이면 보안 경고 페이지로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: 'http://evil.com',
        );
        expect(result, securityWarningWith('http://evil.com'));
      });

      test('프로토콜 상대 URL(//evil.com)이면 보안 경고 페이지로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: '//evil.com',
        );
        expect(result, securityWarningWith('//evil.com'));
      });

      test('javascript: URI이면 보안 경고 페이지로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: 'javascript:alert(1)',
        );
        expect(result, securityWarningWith('javascript:alert(1)'));
      });

      test('data: URI이면 보안 경고 페이지로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: 'data:text/html,<h1>evil</h1>',
        );
        expect(result, securityWarningWith('data:text/html,<h1>evil</h1>'));
      });

      test('ftp:// URL이면 보안 경고 페이지로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: 'ftp://evil.com/file',
        );
        expect(result, securityWarningWith('ftp://evil.com/file'));
      });

      test('경로 내에 ://가 포함되면 보안 경고 페이지로 리다이렉트한다', () {
        const malicious = '/page?url=https://evil.com';
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: malicious,
        );
        expect(result, securityWarningWith(malicious));
      });

      test('등록되지 않은 내부 경로이면 보안 경고 페이지로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: '/admin/dashboard',
        );
        expect(result, securityWarningWith('/admin/dashboard'));
      });

      test('/.env 같은 민감한 경로이면 보안 경고 페이지로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: '/.env',
        );
        expect(result, securityWarningWith('/.env'));
      });

      test('공개 경로(/login)는 악의적이지 않으므로 /로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: AppRoute.login.path,
        );
        expect(result, AppRoute.calendar.path);
      });

      test('공개 경로(/signup)는 악의적이지 않으므로 /로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: AppRoute.signup.path,
        );
        expect(result, AppRoute.calendar.path);
      });

      test('유효한 내부 경로(/mypage)는 정상적으로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: AppRoute.mypage.path,
        );
        expect(result, AppRoute.mypage.path);
      });

      test('파라미터 포함 경로(/todo/abc)는 정상적으로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: '/todo/group-123',
        );
        expect(result, '/todo/group-123');
      });
    });

    // ----------------------------------------------------------
    // 로그아웃 시나리오 (인증 → 미인증 전환)
    // ----------------------------------------------------------
    group('로그아웃 시나리오', () {
      test('인증된 사용자가 로그아웃하면 /mypage에서 /login으로 리다이렉트된다', () {
        final beforeLogout = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.mypage.path,
        );
        expect(beforeLogout, isNull);

        final afterLogout = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.mypage.path,
        );
        expect(afterLogout,
            '${AppRoute.login.path}?redirect=${AppRoute.mypage.path}');
      });

      test('인증된 사용자가 로그아웃하면 모든 보호된 경로에서 /login으로 리다이렉트된다', () {
        final protectedRoutes = AppRoute.values.where((r) => r.requiresAuth);

        for (final route in protectedRoutes) {
          final result = authRedirect(
            isAuthenticated: false,
            isAuthLoading: false,
            matchedLocation: route.path,
          );
          expect(result, '${AppRoute.login.path}?redirect=${route.path}',
              reason: '${route.name} 경로에서 리다이렉트 실패');
        }
      });
    });
  });
}
