import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/auth/kratos_client.dart';
import 'package:momeet/core/auth/kratos_models.dart';
import 'package:momeet/core/exceptions/exceptions.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/auth/domain/auth_error_type.dart';

import '../../helpers/kratos_mocks.dart';

void main() {
  late KratosTestHarness harness;

  setUpAll(registerKratosFallbacks);

  /// 컨테이너를 만들고 앱 시작 시 세션 복원이 끝날 때까지 기다린다.
  Future<ProviderContainer> boot() async {
    final container = ProviderContainer(overrides: harness.overrides);
    addTearDown(container.dispose);
    container.read(authProvider);
    await pumpEventQueue();
    return container;
  }

  const recoveredResult = KratosSubmitResult(
    continueWith: [
      {'action': 'set_ory_session_token', 'ory_session_token': 'ory_st_rec'},
      {
        'action': 'show_settings_ui',
        'flow': {'id': 's1'},
      },
    ],
  );

  final networkError = DioException(
    requestOptions: RequestOptions(path: '/sessions/whoami'),
    type: DioExceptionType.connectionError,
  );

  group('앱 시작', () {
    test('저장된 세션이 없으면 바로 미인증이다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      final container = ProviderContainer(overrides: harness.overrides);
      addTearDown(container.dispose);

      expect(container.read(authProvider), isA<AuthUnauthenticated>());
      verifyNever(() => harness.kratos.whoami(any()));
    });

    test('저장된 세션으로 JWT를 받아 인증 상태가 된다', () async {
      harness = await KratosTestHarness.create();
      final container = ProviderContainer(overrides: harness.overrides);
      addTearDown(container.dispose);

      expect(container.read(authProvider), isA<AuthLoading>());
      await pumpEventQueue();

      expect(container.read(accessTokenProvider), harness.accessToken);
      expect(container.read(currentUserProvider)?.email, 'user@example.com');
      verify(
        () => harness.kratos.whoami(KratosTestHarness.sessionToken),
      ).called(1);
    });

    test('세션이 끝났으면 토큰을 지우고 미인증이 된다', () async {
      harness = await KratosTestHarness.create();
      when(() => harness.kratos.whoami(any())).thenAnswer((_) async => null);

      final container = await boot();

      expect(container.read(authProvider), isA<AuthUnauthenticated>());
      expect(harness.prefs.getString(sessionTokenKey), isNull);
    });

    test('네트워크 오류면 error 상태가 되고 세션 토큰은 남긴다', () async {
      harness = await KratosTestHarness.create();
      when(() => harness.kratos.whoami(any())).thenThrow(networkError);

      final container = await boot();

      expect(container.read(authProvider), isA<AuthStatusError>());
      expect(
        harness.prefs.getString(sessionTokenKey),
        KratosTestHarness.sessionToken,
      );
    });
  });

  group('JWT 갱신', () {
    test('만료가 멀면 지금 JWT를 그대로 준다', () async {
      harness = await KratosTestHarness.create();
      final container = await boot();

      final token = await container
          .read(authProvider.notifier)
          .freshAccessToken();

      expect(token, harness.accessToken);
      verify(() => harness.kratos.whoami(any())).called(1);
    });

    test('만료까지 1분이 안 남았으면 새로 받는다', () async {
      harness = await KratosTestHarness.create(
        accessTokenExpiresIn: const Duration(seconds: 30),
      );
      final container = await boot();
      final renewed = testJwt();
      harness.accessToken = renewed;

      final token = await container
          .read(authProvider.notifier)
          .freshAccessToken();

      expect(token, renewed);
      expect(container.read(accessTokenProvider), renewed);
    });

    test('미인증이면 null이다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      final container = await boot();

      expect(
        await container.read(authProvider.notifier).freshAccessToken(),
        isNull,
      );
    });

    test('동시에 여러 번 불려도 whoami는 한 번만 보낸다', () async {
      harness = await KratosTestHarness.create();
      final container = await boot();
      clearInteractions(harness.kratos); // 앱 시작 때 복원 호출은 세지 않는다
      final pending = Completer<KratosSession?>();
      when(
        () => harness.kratos.whoami(any()),
      ).thenAnswer((_) => pending.future);
      final notifier = container.read(authProvider.notifier);

      final first = notifier.refreshAccessToken();
      final second = notifier.refreshAccessToken();
      final renewed = testJwt();
      pending.complete(KratosSession(user: testUser, accessToken: renewed));

      expect(await first, renewed);
      expect(await second, renewed);
      verify(() => harness.kratos.whoami(any())).called(1);
    });

    test('세션이 끝났으면 null을 주고 미인증이 된다', () async {
      harness = await KratosTestHarness.create();
      final container = await boot();
      when(() => harness.kratos.whoami(any())).thenAnswer((_) async => null);

      final token = await container
          .read(authProvider.notifier)
          .refreshAccessToken();

      expect(token, isNull);
      expect(container.read(authProvider), isA<AuthUnauthenticated>());
    });

    test('네트워크 오류는 그대로 던지고 인증 상태는 유지한다', () async {
      harness = await KratosTestHarness.create();
      final container = await boot();
      when(() => harness.kratos.whoami(any())).thenThrow(networkError);

      await expectLater(
        container.read(authProvider.notifier).refreshAccessToken(),
        throwsA(isA<DioException>()),
      );
      expect(container.read(authProvider), isA<AuthAuthenticated>());
    });
  });

  group('로그인과 가입', () {
    test('로그인하면 세션 토큰을 저장하고 인증 상태가 된다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      harness.stubCreateFlow(KratosFlowType.login, 'f1');
      harness.stubSubmit(
        KratosFlowType.login,
        const KratosSubmitResult(sessionToken: 'ory_st_new'),
      );
      final container = await boot();

      await container
          .read(authProvider.notifier)
          .signInWithEmail(email: 'user@example.com', password: 'pw');

      verify(
        () => harness.kratos.submit(KratosFlowType.login, 'f1', {
          'method': 'password',
          'identifier': 'user@example.com',
          'password': 'pw',
        }),
      ).called(1);
      verify(() => harness.kratos.whoami('ory_st_new')).called(1);
      expect(harness.prefs.getString(sessionTokenKey), 'ory_st_new');
      expect(container.read(authProvider), isA<AuthAuthenticated>());
    });

    test('로그인 실패는 분류된 메시지의 AuthException이다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      harness.stubCreateFlow(KratosFlowType.login, 'f1');
      harness.stubSubmitError(KratosFlowType.login, kratosError(4000006));
      final container = await boot();

      await expectLater(
        container
            .read(authProvider.notifier)
            .signInWithEmail(email: 'user@example.com', password: 'wrong'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            AuthErrorType.invalidCredentials.localized,
          ),
        ),
      );
      expect(container.read(authProvider), isA<AuthUnauthenticated>());
    });

    test('가입은 세션 토큰만 저장하고 인증 플로우 ID를 돌려준다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      harness.stubCreateFlow(KratosFlowType.registration, 'r1');
      harness.stubSubmit(
        KratosFlowType.registration,
        const KratosSubmitResult(
          sessionToken: 'ory_st_new',
          continueWith: [
            {
              'action': 'show_verification_ui',
              'flow': {'id': 'v1'},
            },
          ],
        ),
      );
      final container = await boot();

      final flowId = await container
          .read(authProvider.notifier)
          .signUpWithEmail(email: 'new@example.com', password: 'pw-12345678');

      expect(flowId, 'v1');
      expect(harness.prefs.getString(sessionTokenKey), 'ory_st_new');
      expect(container.read(authProvider), isA<AuthUnauthenticated>());
      verifyNever(() => harness.kratos.whoami(any()));
    });

    test('completeSignUp은 저장된 세션으로 인증 상태가 된다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      final container = await boot();
      await harness.prefs.setString(sessionTokenKey, 'ory_st_new');

      await container.read(authProvider.notifier).completeSignUp();

      verify(() => harness.kratos.whoami('ory_st_new')).called(1);
      expect(container.read(authProvider), isA<AuthAuthenticated>());
    });
  });

  group('이메일 인증', () {
    test('인증 코드를 보내고 새 인증 플로우 ID를 돌려준다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      harness.stubCreateFlow(KratosFlowType.verification, 'v2');
      harness.stubSubmit(
        KratosFlowType.verification,
        const KratosSubmitResult(),
      );
      final container = await boot();

      final flowId = await container
          .read(authProvider.notifier)
          .sendVerificationCode('user@example.com');

      expect(flowId, 'v2');
      verify(
        () => harness.kratos.submit(KratosFlowType.verification, 'v2', {
          'method': 'code',
          'email': 'user@example.com',
        }),
      ).called(1);
    });

    test('코드를 확인하면 저장된 세션으로 JWT를 다시 받는다', () async {
      harness = await KratosTestHarness.create();
      harness.stubSubmit(
        KratosFlowType.verification,
        const KratosSubmitResult(),
      );
      final container = await boot();
      clearInteractions(harness.kratos);

      await container
          .read(authProvider.notifier)
          .verifyEmail(flowId: 'v1', code: '123456');

      verify(
        () => harness.kratos.submit(KratosFlowType.verification, 'v1', {
          'method': 'code',
          'code': '123456',
        }),
      ).called(1);
      verify(
        () => harness.kratos.whoami(KratosTestHarness.sessionToken),
      ).called(1);
    });

    test('코드가 틀리면 AuthException이고 JWT는 다시 받지 않는다', () async {
      harness = await KratosTestHarness.create();
      harness.stubSubmitError(
        KratosFlowType.verification,
        kratosError(4070006),
      );
      final container = await boot();
      clearInteractions(harness.kratos);

      await expectLater(
        container
            .read(authProvider.notifier)
            .verifyEmail(flowId: 'v1', code: '000000'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            AuthErrorType.invalidCode.localized,
          ),
        ),
      );
      verifyNever(() => harness.kratos.whoami(any()));
    });
  });

  group('로그아웃', () {
    test('세션을 끝내고 토큰을 지운 뒤 미인증이 된다', () async {
      harness = await KratosTestHarness.create();
      when(() => harness.kratos.logout(any())).thenAnswer((_) async {});
      final container = await boot();

      await container.read(authProvider.notifier).signOut();

      verify(
        () => harness.kratos.logout(KratosTestHarness.sessionToken),
      ).called(1);
      expect(harness.prefs.getString(sessionTokenKey), isNull);
      expect(container.read(accessTokenProvider), isNull);
      expect(container.read(currentUserProvider), isNull);
      expect(container.read(isAuthenticatedProvider), isFalse);
    });

    test('서버 세션을 끝내지 못하면 로그인 상태를 유지하고 예외를 던진다', () async {
      harness = await KratosTestHarness.create();
      when(() => harness.kratos.logout(any())).thenThrow(networkError);
      final container = await boot();

      await expectLater(
        container.read(authProvider.notifier).signOut(),
        throwsA(isA<AuthException>()),
      );
      expect(container.read(isAuthenticatedProvider), isTrue);
      expect(
        harness.prefs.getString(sessionTokenKey),
        KratosTestHarness.sessionToken,
      );
    });
  });

  group('복구와 비밀번호 변경', () {
    test('복구 코드를 보내고 복구 플로우 ID를 돌려준다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      harness.stubCreateFlow(KratosFlowType.recovery, 'rec1');
      harness.stubSubmit(KratosFlowType.recovery, const KratosSubmitResult());
      final container = await boot();

      final flowId = await container
          .read(authProvider.notifier)
          .sendRecoveryCode('user@example.com');

      expect(flowId, 'rec1');
      verify(
        () => harness.kratos.submit(KratosFlowType.recovery, 'rec1', {
          'method': 'code',
          'email': 'user@example.com',
        }),
      ).called(1);
    });

    test('복구 코드가 맞으면 설정 플로우 ID를 주고 세션은 아직 저장하지 않는다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      harness.stubSubmit(KratosFlowType.recovery, recoveredResult);
      final container = await boot();

      final settingsFlowId = await container
          .read(authProvider.notifier)
          .verifyRecoveryCode(flowId: 'rec1', code: '123456');

      expect(settingsFlowId, 's1');
      expect(harness.prefs.getString(sessionTokenKey), isNull);
      expect(container.read(authProvider), isA<AuthUnauthenticated>());
    });

    test('새 비밀번호를 복구 세션으로 저장한 뒤 그 세션으로 로그인한다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      harness.stubSubmit(KratosFlowType.recovery, recoveredResult);
      harness.stubSubmit(KratosFlowType.settings, const KratosSubmitResult());
      final container = await boot();
      final notifier = container.read(authProvider.notifier);
      await notifier.verifyRecoveryCode(flowId: 'rec1', code: '123456');

      await notifier.completeRecovery(
        settingsFlowId: 's1',
        newPassword: 'new-pw-123',
      );

      verify(
        () => harness.kratos.submit(KratosFlowType.settings, 's1', {
          'method': 'password',
          'password': 'new-pw-123',
        }, sessionToken: 'ory_st_rec'),
      ).called(1);
      expect(harness.prefs.getString(sessionTokenKey), 'ory_st_rec');
      expect(container.read(authProvider), isA<AuthAuthenticated>());
    });

    test('복구 코드가 틀리면 AuthException이다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      harness.stubSubmitError(KratosFlowType.recovery, kratosError(4060006));
      final container = await boot();

      await expectLater(
        container
            .read(authProvider.notifier)
            .verifyRecoveryCode(flowId: 'rec1', code: '000000'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            AuthErrorType.invalidCode.localized,
          ),
        ),
      );
    });

    test('비밀번호 변경은 현재 비밀번호로 재인증한 뒤 새 비밀번호를 저장한다', () async {
      harness = await KratosTestHarness.create();
      harness.stubCreateFlow(KratosFlowType.login, 'refresh1');
      harness.stubCreateFlow(KratosFlowType.settings, 'settings1');
      harness.stubSubmit(KratosFlowType.login, const KratosSubmitResult());
      harness.stubSubmit(KratosFlowType.settings, const KratosSubmitResult());
      final container = await boot();

      await container
          .read(authProvider.notifier)
          .changePassword(currentPassword: 'old-pw', newPassword: 'new-pw-123');

      const token = KratosTestHarness.sessionToken;
      verifyInOrder([
        () => harness.kratos.createFlow(
          KratosFlowType.login,
          sessionToken: token,
          refresh: true,
        ),
        () => harness.kratos.submit(KratosFlowType.login, 'refresh1', {
          'method': 'password',
          'identifier': 'user@example.com',
          'password': 'old-pw',
        }, sessionToken: token),
        () => harness.kratos.createFlow(
          KratosFlowType.settings,
          sessionToken: token,
        ),
        () => harness.kratos.submit(KratosFlowType.settings, 'settings1', {
          'method': 'password',
          'password': 'new-pw-123',
        }, sessionToken: token),
      ]);
    });

    test('현재 비밀번호가 틀리면 새 비밀번호를 저장하지 않는다', () async {
      harness = await KratosTestHarness.create();
      harness.stubCreateFlow(KratosFlowType.login, 'refresh1');
      harness.stubSubmitError(KratosFlowType.login, kratosError(4000006));
      final container = await boot();

      await expectLater(
        container
            .read(authProvider.notifier)
            .changePassword(
              currentPassword: 'wrong',
              newPassword: 'new-pw-123',
            ),
        throwsA(isA<AuthException>()),
      );
      verifyNever(
        () => harness.kratos.submit(
          KratosFlowType.settings,
          any(),
          any(),
          sessionToken: any(named: 'sessionToken'),
        ),
      );
    });
  });
}
