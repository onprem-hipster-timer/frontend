import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/router.dart';
import 'package:momeet/auth_redirect.dart';

void main() {
  // ============================================================
  // AppRoute enum 테스트
  // ============================================================
  group('AppRoute', () {
    test('공개 라우트는 requiresAuth가 false이다', () {
      expect(AppRoute.login.requiresAuth, false);
      expect(AppRoute.signup.requiresAuth, false);
      expect(AppRoute.forgotPassword.requiresAuth, false);
      expect(AppRoute.landing.requiresAuth, false);
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
      expect(AppRoute.publicPaths, contains(AppRoute.landing.path));
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
        expect(AppRoute.isKnownProtectedPath('/landing'), false);
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
      test('로딩 끝나고 미인증이면 /loading에서 /landing으로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.loading.path,
        );
        expect(result, AppRoute.landing.path);
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
      test('미인증 사용자가 루트(/)에 접근하면 /landing으로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.calendar.path,
        );
        expect(result, AppRoute.landing.path);
      });

      test('미인증 사용자가 보호된 경로에 접근하면 /login으로 리다이렉트한다', () {
        final protectedRoutes = AppRoute.values.where(
          (r) => r.requiresAuth && r != AppRoute.calendar,
        );

        for (final route in protectedRoutes) {
          final result = authRedirect(
            isAuthenticated: false,
            isAuthLoading: false,
            matchedLocation: route.path,
          );
          expect(
            result,
            '${AppRoute.login.path}?redirect=${Uri.encodeComponent(route.path)}',
            reason: '${route.name} 경로에서 /login 리다이렉트 실패',
          );
        }
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
    // 로그인 여부와 상관없이 머무는 페이지
    // ----------------------------------------------------------
    group('인증 화면 (authNeutral)', () {
      test('인증 화면과 인증 오류 화면은 공개이면서 neutral이다', () {
        for (final route in [AppRoute.verification, AppRoute.authError]) {
          expect(route.requiresAuth, isFalse);
          expect(route.authNeutral, isTrue);
          expect(AppRoute.neutralPaths, contains(route.path));
        }
        expect(AppRoute.neutralPaths, isNot(contains(AppRoute.login.path)));
      });

      for (final isAuthenticated in [false, true]) {
        for (final route in [AppRoute.verification, AppRoute.authError]) {
          test('${isAuthenticated ? '인증' : '미인증'} 사용자가 ${route.path}에 있으면 '
              '리다이렉트하지 않는다', () {
            final result = authRedirect(
              isAuthenticated: isAuthenticated,
              isAuthLoading: false,
              matchedLocation: route.path,
            );
            expect(result, isNull);
          });
        }
      }
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

      test('인증된 사용자도 /forgot-password에 머문다 (메일 코드로 비밀번호 변경)', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.forgotPassword.path,
        );
        expect(result, isNull);
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
    // 랜딩 페이지 리다이렉트
    // ----------------------------------------------------------
    group('랜딩 페이지', () {
      test('미인증 사용자가 /landing에 있으면 리다이렉트하지 않는다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.landing.path,
        );
        expect(result, isNull);
      });

      test('인증된 사용자가 /landing에 있으면 /로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.landing.path,
        );
        expect(result, AppRoute.calendar.path);
      });

      test('미인증 사용자가 루트(/)에 접근하면 /login이 아닌 /landing으로 간다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.calendar.path,
        );
        expect(result, isNot(contains(AppRoute.login.path)));
        expect(result, AppRoute.landing.path);
      });

      test('미인증 사용자가 /todo에 접근하면 /landing이 아닌 /login으로 간다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.todo.path,
        );
        expect(result, isNot(AppRoute.landing.path));
        expect(
          result,
          '${AppRoute.login.path}?redirect=${Uri.encodeComponent(AppRoute.todo.path)}',
        );
      });

      test('로딩 완료 후 미인증이면 /landing으로 리다이렉트한다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.loading.path,
        );
        expect(result, AppRoute.landing.path);
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
          step2,
          '${AppRoute.login.path}?redirect=${Uri.encodeComponent(AppRoute.mypage.path)}',
        );

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
        expect(
          afterLogout,
          '${AppRoute.login.path}?redirect=${Uri.encodeComponent(AppRoute.mypage.path)}',
        );
      });

      test('인증된 사용자가 로그아웃하면 모든 보호된 경로에서 리다이렉트된다', () {
        final protectedRoutes = AppRoute.values.where((r) => r.requiresAuth);

        for (final route in protectedRoutes) {
          final result = authRedirect(
            isAuthenticated: false,
            isAuthLoading: false,
            matchedLocation: route.path,
          );

          if (route == AppRoute.calendar) {
            // 루트 경로는 /landing으로
            expect(
              result,
              AppRoute.landing.path,
              reason: '${route.name} 경로에서 /landing 리다이렉트 실패',
            );
          } else {
            // 그 외 보호 경로는 /login?redirect=...으로
            expect(
              result,
              '${AppRoute.login.path}?redirect=${Uri.encodeComponent(route.path)}',
              reason: '${route.name} 경로에서 /login 리다이렉트 실패',
            );
          }
        }
      });
    });

    // ----------------------------------------------------------
    // Kratos가 보내는 링크 (메일 인증) 위조 검사
    // ----------------------------------------------------------
    group('인증 링크 검사', () {
      const flowId = '3f1e2d4c-5b6a-4789-9abc-def012345678';

      String blocked(String path, Map<String, String> params) =>
          '${AppRoute.securityWarning.path}?blocked='
          '${Uri.encodeComponent(Uri(path: path, queryParameters: params).toString())}';

      test('Kratos 플로우 ID(UUID)가 담긴 인증 링크는 그대로 연다', () {
        for (final isAuthenticated in [false, true]) {
          final result = authRedirect(
            isAuthenticated: isAuthenticated,
            isAuthLoading: false,
            matchedLocation: AppRoute.verification.path,
            queryParameters: {'flow': flowId},
          );
          expect(result, isNull);
        }
      });

      test('flow 없이 연 인증 화면은 그대로 연다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.verification.path,
        );
        expect(result, isNull);
      });

      test('flow가 플로우 ID 모양이 아니면 보안 경고로 보낸다', () {
        for (final flow in [
          'abc',
          '../../self-service/settings',
          '<script>alert(1)</script>',
          '$flowId/extra',
          'https://evil.example',
        ]) {
          final params = {'flow': flow};
          final result = authRedirect(
            isAuthenticated: false,
            isAuthLoading: false,
            matchedLocation: AppRoute.verification.path,
            queryParameters: params,
          );
          expect(
            result,
            blocked(AppRoute.verification.path, params),
            reason: flow,
          );
        }
      });

      test('인증 메일 링크(flow와 6자리 code)는 그대로 연다', () {
        for (final isAuthenticated in [false, true]) {
          final result = authRedirect(
            isAuthenticated: isAuthenticated,
            isAuthLoading: false,
            matchedLocation: AppRoute.verification.path,
            queryParameters: {'flow': flowId, 'code': '012345'},
          );
          expect(result, isNull);
        }
      });

      test('인증 화면의 code가 6자리 숫자가 아니면 보안 경고로 보낸다', () {
        for (final code in [
          '',
          '12345',
          '1234567',
          '12345a',
          ' 123456',
          '１２３４５６',
          '<script>x</script>',
        ]) {
          final params = {'flow': flowId, 'code': code};
          final result = authRedirect(
            isAuthenticated: false,
            isAuthLoading: false,
            matchedLocation: AppRoute.verification.path,
            queryParameters: params,
          );
          expect(
            result,
            blocked(AppRoute.verification.path, params),
            reason: code,
          );
        }
      });

      test('인증 화면에 flow 없이 code만 오면 보안 경고로 보낸다', () {
        final params = {'code': '123456'};
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.verification.path,
          queryParameters: params,
        );
        expect(result, blocked(AppRoute.verification.path, params));
      });

      test('로그인한 사용자도 위조된 인증 링크면 보안 경고로 보낸다', () {
        final params = {'flow': 'not-a-flow'};
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.verification.path,
          queryParameters: params,
        );
        expect(result, blocked(AppRoute.verification.path, params));
      });

      const googleCode = 'Zx81QwErTyUiOp0987654321AsDfGhJkLmNbVcXz';

      test('Google 로그인에서 돌아온 code는 그대로 로그인 화면을 연다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          queryParameters: {'code': googleCode},
        );
        expect(result, isNull);
      });

      test('code가 Kratos 코드 모양이 아니면 보안 경고로 보낸다', () {
        for (final code in [
          'short',
          'has space in it 12345',
          '<script>x</script>',
        ]) {
          final params = {'code': code};
          final result = authRedirect(
            isAuthenticated: false,
            isAuthLoading: false,
            matchedLocation: AppRoute.login.path,
            queryParameters: params,
          );
          expect(result, blocked(AppRoute.login.path, params), reason: code);
        }
      });

      test('Google 로그인을 마치면 redirect 검사를 거쳐 원래 화면으로 간다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: '/todo',
          queryParameters: {'redirect': '/todo', 'code': googleCode},
        );
        expect(result, '/todo');
      });

      test('Google 로그인 뒤 redirect가 외부 주소면 보안 경고로 보낸다', () {
        final result = authRedirect(
          isAuthenticated: true,
          isAuthLoading: false,
          matchedLocation: AppRoute.login.path,
          redirectAfterLogin: '//evil.example',
          queryParameters: {'redirect': '//evil.example', 'code': googleCode},
        );
        expect(
          result,
          '${AppRoute.securityWarning.path}?blocked=${Uri.encodeComponent('//evil.example')}',
        );
      });

      test('기존 계정 연결 링크(/login?flow=)는 플로우 ID 모양일 때만 연다', () {
        expect(
          authRedirect(
            isAuthenticated: false,
            isAuthLoading: false,
            matchedLocation: AppRoute.login.path,
            queryParameters: {'flow': flowId, 'no_org_ui': 'true'},
          ),
          isNull,
        );
        final params = {'flow': '../settings'};
        expect(
          authRedirect(
            isAuthenticated: false,
            isAuthLoading: false,
            matchedLocation: AppRoute.login.path,
            queryParameters: params,
          ),
          blocked(AppRoute.login.path, params),
        );
      });

      test('다른 화면의 flow 값은 검사하지 않는다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.signup.path,
          queryParameters: {'flow': 'anything'},
        );
        expect(result, isNull);
      });
    });

    // ----------------------------------------------------------
    // 약관 동의 (로그인한 사용자)
    // ----------------------------------------------------------
    group('약관 동의', () {
      String? signedIn(
        String location, {
        required bool? consentRequired,
        String? redirect,
      }) => authRedirect(
        isAuthenticated: true,
        isAuthLoading: false,
        matchedLocation: location,
        redirectAfterLogin: redirect,
        queryParameters: {'redirect': ?redirect},
        consentRequired: consentRequired,
      );

      String consentFor(String path) =>
          '${AppRoute.consent.path}?redirect=${Uri.encodeComponent(path)}';

      test('동의가 필요하면 보호된 페이지 대신 동의 화면으로 가고, 원래 경로를 기억한다', () {
        for (final path in [
          AppRoute.todo.path,
          AppRoute.mypage.path,
          AppRoute.timer.path,
          AppRoute.tags.path,
          '/todo/group-1',
          AppRoute.scheduleDetail.path,
        ]) {
          expect(
            signedIn(path, consentRequired: true),
            consentFor(path),
            reason: path,
          );
        }
      });

      test('동의가 필요하면 루트(/)는 돌아갈 곳 없이 동의 화면으로 간다', () {
        expect(
          signedIn(AppRoute.calendar.path, consentRequired: true),
          AppRoute.consent.path,
        );
      });

      test('동의가 필요하면 동의 화면에 머문다', () {
        expect(signedIn(AppRoute.consent.path, consentRequired: true), isNull);
        expect(
          signedIn(
            AppRoute.consent.path,
            consentRequired: true,
            redirect: AppRoute.todo.path,
          ),
          isNull,
        );
      });

      test('동의가 필요한지 아직 모르면(프로필 불러오는 중·실패) 보호된 페이지를 열지 않는다', () {
        expect(
          signedIn(AppRoute.todo.path, consentRequired: null),
          consentFor(AppRoute.todo.path),
        );
        expect(
          signedIn(AppRoute.calendar.path, consentRequired: null),
          AppRoute.consent.path,
        );
        expect(signedIn(AppRoute.consent.path, consentRequired: null), isNull);
      });

      test('동의가 필요 없으면 보호된 페이지를 그대로 연다', () {
        expect(signedIn(AppRoute.todo.path, consentRequired: false), isNull);
        expect(
          signedIn(AppRoute.calendar.path, consentRequired: false),
          isNull,
        );
      });

      test('동의가 필요 없으면 동의 화면에서 기억한 경로로 돌아간다', () {
        expect(
          signedIn(
            AppRoute.consent.path,
            consentRequired: false,
            redirect: '/todo/group-1',
          ),
          '/todo/group-1',
        );
      });

      test('동의가 필요 없고 돌아갈 곳이 없으면 동의 화면에서 메인으로 간다', () {
        expect(
          signedIn(AppRoute.consent.path, consentRequired: false),
          AppRoute.calendar.path,
        );
        expect(
          signedIn(
            AppRoute.consent.path,
            consentRequired: false,
            redirect: AppRoute.login.path,
          ),
          AppRoute.calendar.path,
        );
      });

      test('동의 화면의 돌아갈 곳이 외부 주소면 보안 경고로 보낸다', () {
        const evil = 'https://evil.com';
        expect(
          signedIn(
            AppRoute.consent.path,
            consentRequired: false,
            redirect: evil,
          ),
          '${AppRoute.securityWarning.path}?blocked=${Uri.encodeComponent(evil)}',
        );
      });

      test('공개 페이지와 인증 화면은 동의가 필요해도 지금처럼 동작한다', () {
        for (final route in AppRoute.values.where((r) => r.authNeutral)) {
          expect(
            signedIn(route.path, consentRequired: true),
            isNull,
            reason: route.path,
          );
        }
        expect(
          signedIn(AppRoute.landing.path, consentRequired: true),
          AppRoute.calendar.path,
        );
      });

      test('인증 로딩 중이면 동의 여부와 상관없이 /loading으로 간다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: true,
          matchedLocation: AppRoute.consent.path,
          consentRequired: null,
        );
        expect(result, AppRoute.loading.path);
      });

      test('로그인하지 않았으면 동의 화면도 로그인으로 보낸다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: AppRoute.consent.path,
          consentRequired: null,
        );
        expect(
          result,
          '${AppRoute.login.path}?redirect=${Uri.encodeComponent(AppRoute.consent.path)}',
        );
      });

      test('로그인하면 원래 경로를 거쳐 동의 화면으로 가고, 동의하면 그 경로로 돌아온다', () {
        // 로그인 화면 → 원래 경로
        final afterLogin = signedIn(
          AppRoute.login.path,
          consentRequired: null,
          redirect: AppRoute.mypage.path,
        );
        expect(afterLogin, AppRoute.mypage.path);

        // 원래 경로 → 동의 화면
        final gated = signedIn(afterLogin!, consentRequired: true);
        expect(gated, consentFor(AppRoute.mypage.path));

        // 동의 → 원래 경로
        final uri = Uri.parse(gated!);
        expect(
          signedIn(
            uri.path,
            consentRequired: false,
            redirect: uri.queryParameters['redirect'],
          ),
          AppRoute.mypage.path,
        );
      });
    });
    // ----------------------------------------------------------
    // 탈퇴 대기 (로그인한 사용자)
    // ----------------------------------------------------------
    group('탈퇴 대기', () {
      String? signedIn(
        String location, {
        required bool? deletionPending,
        bool? consentRequired = false,
        String? redirect,
      }) => authRedirect(
        isAuthenticated: true,
        isAuthLoading: false,
        matchedLocation: location,
        redirectAfterLogin: redirect,
        queryParameters: {'redirect': ?redirect},
        consentRequired: consentRequired,
        deletionPending: deletionPending,
      );

      final grace = AppRoute.accountDeletion.path;
      String graceFor(String path) =>
          '$grace?redirect=${Uri.encodeComponent(path)}';

      test('탈퇴를 신청했으면 보호된 페이지 대신 탈퇴 대기 화면으로 가고, 원래 경로를 기억한다', () {
        for (final path in [
          AppRoute.todo.path,
          AppRoute.mypage.path,
          '/todo/group-1',
          AppRoute.scheduleDetail.path,
        ]) {
          expect(
            signedIn(path, deletionPending: true),
            graceFor(path),
            reason: path,
          );
        }
        expect(signedIn(AppRoute.calendar.path, deletionPending: true), grace);
      });

      test('약관 동의가 필요하거나 아직 몰라도 탈퇴 대기 화면이 먼저다', () {
        for (final consent in [true, null]) {
          expect(
            signedIn(
              AppRoute.todo.path,
              deletionPending: true,
              consentRequired: consent,
            ),
            graceFor(AppRoute.todo.path),
            reason: '$consent',
          );
          expect(
            signedIn(grace, deletionPending: true, consentRequired: consent),
            isNull,
            reason: '$consent',
          );
        }
      });

      test('동의 화면에 있다가 탈퇴 신청이 확인되면 동의 화면이 기억한 경로를 넘겨받는다', () {
        expect(
          signedIn(
            AppRoute.consent.path,
            deletionPending: true,
            consentRequired: true,
            redirect: AppRoute.todo.path,
          ),
          graceFor(AppRoute.todo.path),
        );
        expect(
          signedIn(
            AppRoute.consent.path,
            deletionPending: true,
            consentRequired: true,
          ),
          grace,
        );
      });

      test('탈퇴 신청 여부를 아직 모르면(프로필 불러오는 중·실패) 탈퇴 대기 화면에 머문다', () {
        expect(
          signedIn(grace, deletionPending: null, consentRequired: null),
          isNull,
        );
        expect(
          signedIn(
            grace,
            deletionPending: null,
            consentRequired: null,
            redirect: AppRoute.todo.path,
          ),
          isNull,
        );
      });

      test('탈퇴 신청 여부를 모르면 다른 보호된 페이지는 열지 않는다', () {
        expect(
          signedIn(
            AppRoute.todo.path,
            deletionPending: null,
            consentRequired: null,
          ),
          '${AppRoute.consent.path}?redirect=${Uri.encodeComponent(AppRoute.todo.path)}',
        );
      });

      test('탈퇴를 취소했고 동의가 필요 없으면 기억한 경로로, 없으면 메인으로 간다', () {
        expect(
          signedIn(grace, deletionPending: false, redirect: '/todo/group-1'),
          '/todo/group-1',
        );
        expect(signedIn(grace, deletionPending: false), AppRoute.calendar.path);
      });

      test('탈퇴를 취소했는데 동의가 필요하면 기억한 경로를 넘겨 동의 화면으로 간다', () {
        expect(
          signedIn(
            grace,
            deletionPending: false,
            consentRequired: true,
            redirect: AppRoute.todo.path,
          ),
          '${AppRoute.consent.path}?redirect=${Uri.encodeComponent(AppRoute.todo.path)}',
        );
        expect(
          signedIn(grace, deletionPending: false, consentRequired: null),
          AppRoute.consent.path,
        );
      });

      test('탈퇴 대기 화면의 돌아갈 곳이 외부 주소면 취소한 뒤 보안 경고로 보낸다', () {
        const evil = 'https://evil.com';
        expect(signedIn(grace, deletionPending: true, redirect: evil), isNull);
        expect(
          signedIn(grace, deletionPending: false, redirect: evil),
          '${AppRoute.securityWarning.path}?blocked=${Uri.encodeComponent(evil)}',
        );
      });

      test('탈퇴를 신청하지 않았으면 보호된 페이지를 그대로 연다', () {
        expect(signedIn(AppRoute.todo.path, deletionPending: false), isNull);
        expect(
          signedIn(AppRoute.calendar.path, deletionPending: false),
          isNull,
        );
      });

      test('공개 페이지와 인증 화면은 탈퇴를 신청했어도 지금처럼 동작한다', () {
        for (final route in AppRoute.values.where((r) => r.authNeutral)) {
          expect(
            signedIn(route.path, deletionPending: true),
            isNull,
            reason: route.path,
          );
        }
        expect(
          signedIn(AppRoute.landing.path, deletionPending: true),
          AppRoute.calendar.path,
        );
        expect(
          signedIn(
            AppRoute.login.path,
            deletionPending: true,
            redirect: AppRoute.mypage.path,
          ),
          AppRoute.mypage.path,
        );
      });

      test('로그인하지 않았으면 탈퇴 대기 화면도 로그인으로 보낸다', () {
        final result = authRedirect(
          isAuthenticated: false,
          isAuthLoading: false,
          matchedLocation: grace,
          deletionPending: null,
        );
        expect(
          result,
          '${AppRoute.login.path}?redirect=${Uri.encodeComponent(grace)}',
        );
      });
    });
  });
}
