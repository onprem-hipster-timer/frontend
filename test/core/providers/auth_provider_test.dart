import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/shared/api/kratos/kratos_client.dart';
import 'package:momeet/shared/api/kratos/kratos_models.dart';
import 'package:momeet/core/exceptions/exceptions.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/core/providers/session_token_store.dart';
import 'package:momeet/features/auth/domain/auth_error_type.dart';

import '../../helpers/kratos_mocks.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

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
      expect(await harness.storedSessionToken(), isNull);
    });

    test('네트워크 오류면 error 상태가 되고 세션 토큰은 남긴다', () async {
      harness = await KratosTestHarness.create();
      when(() => harness.kratos.whoami(any())).thenThrow(networkError);

      final container = await boot();

      expect(container.read(authProvider), isA<AuthStatusError>());
      expect(
        await harness.storedSessionToken(),
        KratosTestHarness.sessionToken,
      );
    });
  });

  group('앱 다시 시작', () {
    test('로그인한 뒤 다시 시작해도 로그인 상태다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      harness.stubCreateFlow(KratosFlowType.login, 'f1');
      harness.stubSubmit(
        KratosFlowType.login,
        const KratosSubmitResult(sessionToken: 'ory_st_new'),
      );
      final first = await boot();
      await first
          .read(authProvider.notifier)
          .signInWithEmail(email: 'user@example.com', password: 'pw');
      first.dispose();

      await harness.restart();
      final restarted = await boot();

      expect(restarted.read(authProvider), isA<AuthAuthenticated>());
      verify(() => harness.kratos.whoami('ory_st_new')).called(2);
    });

    test('이전 버전이 SharedPreferences에 둔 토큰으로 로그인 상태가 되고 이전 키를 지운다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      await harness.prefs.setString(sessionTokenKey, 'ory_st_old');

      await harness.restart();
      final container = await boot();

      expect(container.read(authProvider), isA<AuthAuthenticated>());
      verify(() => harness.kratos.whoami('ory_st_old')).called(1);
      expect(await harness.storedSessionToken(), 'ory_st_old');
      expect(harness.prefs.getString(sessionTokenKey), isNull);
    });

    test('옮긴 뒤 한 번 더 시작해도 같은 세션으로 로그인 상태다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      await harness.prefs.setString(sessionTokenKey, 'ory_st_old');
      await harness.restart();
      (await boot()).dispose();

      await harness.restart();
      final container = await boot();

      expect(container.read(authProvider), isA<AuthAuthenticated>());
      verify(() => harness.kratos.whoami('ory_st_old')).called(2);
      expect(await harness.storedSessionToken(), 'ory_st_old');
    });

    test('보안 저장소를 읽지 못하면 미인증으로 시작한다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      final storage = _MockSecureStorage();
      when(
        () => storage.read(key: sessionTokenKey),
      ).thenThrow(PlatformException(code: 'read_failed'));
      harness.tokenStore = SessionTokenStore(storage, harness.prefs);
      await harness.tokenStore.load();

      final container = ProviderContainer(overrides: harness.overrides);
      addTearDown(container.dispose);

      expect(container.read(authProvider), isA<AuthUnauthenticated>());
      verifyNever(() => harness.kratos.whoami(any()));
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

    test('읽을 수 없는 JWT는 만료된 것으로 보고 새로 받는다', () async {
      harness = await KratosTestHarness.create();
      harness.accessToken = 'not-a-jwt';
      final container = await boot();
      final renewed = testJwt();
      harness.accessToken = renewed;

      final token = await container
          .read(authProvider.notifier)
          .freshAccessToken();

      expect(token, renewed);
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

    test('갱신 중에 로그아웃하면 끝난 세션을 되살리지 않는다', () async {
      harness = await KratosTestHarness.create();
      final container = await boot();
      final pending = Completer<KratosSession?>();
      when(
        () => harness.kratos.whoami(any()),
      ).thenAnswer((_) => pending.future);
      when(() => harness.kratos.logout(any())).thenAnswer((_) async {});
      final notifier = container.read(authProvider.notifier);

      final refreshing = notifier.refreshAccessToken();
      await notifier.signOut();
      pending.complete(KratosSession(user: testUser, accessToken: testJwt()));

      expect(await refreshing, isNull);
      expect(container.read(authProvider), isA<AuthUnauthenticated>());
      expect(await harness.storedSessionToken(), isNull);
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
      expect(await harness.storedSessionToken(), 'ory_st_new');
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

    test('가입은 세션을 저장하지 않고 인증 플로우 ID만 돌려준다', () async {
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
      expect(await harness.storedSessionToken(), isNull);
      expect(container.read(authProvider), isA<AuthUnauthenticated>());
      verifyNever(() => harness.kratos.whoami(any()));
    });

    test('인증 전 로그인은 새 인증 플로우를 담은 EmailNotVerifiedException이다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      harness.stubCreateFlow(KratosFlowType.login, 'f1');
      harness.stubSubmitError(
        KratosFlowType.login,
        const KratosException(
          statusCode: 403,
          errorId: 'session_verified_address_required',
          verificationFlowId: 'v9',
        ),
      );
      final container = await boot();

      await expectLater(
        container
            .read(authProvider.notifier)
            .signInWithEmail(email: 'new@example.com', password: 'pw'),
        throwsA(
          isA<EmailNotVerifiedException>()
              .having((e) => e.verificationFlowId, 'flow', 'v9')
              .having(
                (e) => e.message,
                'message',
                AuthErrorType.emailNotVerified.localized,
              ),
        ),
      );
      expect(container.read(authProvider), isA<AuthUnauthenticated>());
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
      expect(await harness.storedSessionToken(), isNull);
      expect(harness.prefs.getBool(hasSessionKey), isNull);
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
        await harness.storedSessionToken(),
        KratosTestHarness.sessionToken,
      );
    });
  });

  group('비밀번호 복구', () {
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
      expect(await harness.storedSessionToken(), isNull);
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
      expect(await harness.storedSessionToken(), 'ory_st_rec');
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
  });

  group('Google 로그인', () {
    final returnTo = Uri.parse(
      'https://app.example.com/login?redirect=%2Ftodo',
    );
    final googleUrl = Uri.parse('https://accounts.google.com/o/oauth2/v2/auth');

    void stubGoogleFlow(KratosFlowType type) {
      when(
        () => harness.kratos.createFlow(type, returnTo: any(named: 'returnTo')),
      ).thenAnswer(
        (_) async =>
            const KratosFlow(id: 'g1', sessionTokenExchangeCode: 'init-code'),
      );
      when(
        () => harness.kratos.submitOidc(type, 'g1', 'google'),
      ).thenAnswer((_) async => googleUrl);
    }

    test('시작하면 교환 코드를 저장하고 Google 주소를 돌려준다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      stubGoogleFlow(KratosFlowType.login);
      final container = await boot();
      final auth = container.read(authProvider.notifier);

      final url = await auth.startGoogleSignIn(returnTo: returnTo);

      expect(url, googleUrl);
      verify(
        () => harness.kratos.createFlow(
          KratosFlowType.login,
          returnTo: returnTo.toString(),
        ),
      ).called(1);
      expect(harness.prefs.getString(googleSignInCodeKey), 'init-code');
      expect(auth.hasPendingGoogleSignIn, isTrue);
      expect(container.read(authProvider), isA<AuthUnauthenticated>());
    });

    test('가입 화면에서 시작하면 가입 플로우를 쓴다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      stubGoogleFlow(KratosFlowType.registration);
      final container = await boot();

      await container
          .read(authProvider.notifier)
          .startGoogleSignIn(returnTo: returnTo, signUp: true);

      verify(
        () => harness.kratos.submitOidc(
          KratosFlowType.registration,
          'g1',
          'google',
        ),
      ).called(1);
    });

    test('Google 주소를 받지 못하면 AuthException이다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      stubGoogleFlow(KratosFlowType.login);
      when(
        () => harness.kratos.submitOidc(KratosFlowType.login, 'g1', 'google'),
      ).thenThrow(const KratosException(statusCode: 500));
      final container = await boot();

      expect(
        () => container
            .read(authProvider.notifier)
            .startGoogleSignIn(returnTo: returnTo),
        throwsA(isA<AuthException>()),
      );
    });

    test('돌아온 코드로 세션 토큰을 받아 로그인하고 교환 코드는 지운다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      await harness.prefs.setString(googleSignInCodeKey, 'init-code');
      when(
        () => harness.kratos.exchangeSessionToken(
          initCode: 'init-code',
          returnToCode: 'return-code',
        ),
      ).thenAnswer((_) async => 'ory_st_google');
      final container = await boot();

      await container
          .read(authProvider.notifier)
          .completeGoogleSignIn('return-code');

      expect(container.read(authProvider), isA<AuthAuthenticated>());
      expect(await harness.storedSessionToken(), 'ory_st_google');
      expect(harness.prefs.getString(googleSignInCodeKey), isNull);
    });

    test('코드가 맞지 않으면 AuthException이고 교환 코드는 지운다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      await harness.prefs.setString(googleSignInCodeKey, 'init-code');
      when(
        () => harness.kratos.exchangeSessionToken(
          initCode: any(named: 'initCode'),
          returnToCode: any(named: 'returnToCode'),
        ),
      ).thenThrow(const KratosException(statusCode: 404));
      final container = await boot();
      final auth = container.read(authProvider.notifier);

      await expectLater(
        auth.completeGoogleSignIn('wrong'),
        throwsA(isA<AuthException>()),
      );
      expect(container.read(authProvider), isA<AuthUnauthenticated>());
      expect(await harness.storedSessionToken(), isNull);
      expect(auth.hasPendingGoogleSignIn, isFalse);
    });

    test('이 브라우저가 시작하지 않은 로그인은 교환하지 않는다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      final container = await boot();
      final auth = container.read(authProvider.notifier);

      expect(auth.hasPendingGoogleSignIn, isFalse);
      await expectLater(
        auth.completeGoogleSignIn('return-code'),
        throwsA(isA<AuthException>()),
      );
      verifyNever(
        () => harness.kratos.exchangeSessionToken(
          initCode: any(named: 'initCode'),
          returnToCode: any(named: 'returnToCode'),
        ),
      );
    });

    group('Google 로그인 사용 가능 여부', () {
      ProviderContainer container({required bool isWeb}) {
        final c = ProviderContainer(
          overrides: [
            ...harness.overrides,
            isWebProvider.overrideWithValue(isWeb),
          ],
        );
        addTearDown(c.dispose);
        return c;
      }

      test('웹이 아니면 서버에 묻지 않고 false다', () async {
        harness = await KratosTestHarness.create(authenticated: false);

        expect(
          await container(
            isWeb: false,
          ).read(googleSignInAvailableProvider.future),
          isFalse,
        );
        verifyNever(() => harness.kratos.createFlow(any()));
      });

      test('웹에서는 로그인 플로우에 google 버튼이 있을 때만 true다', () async {
        harness = await KratosTestHarness.create(authenticated: false);
        when(() => harness.kratos.createFlow(KratosFlowType.login)).thenAnswer(
          (_) async => const KratosFlow(id: 'f1', oidcProviders: ['google']),
        );
        expect(
          await container(
            isWeb: true,
          ).read(googleSignInAvailableProvider.future),
          isTrue,
        );

        when(
          () => harness.kratos.createFlow(KratosFlowType.login),
        ).thenAnswer((_) async => const KratosFlow(id: 'f2'));
        expect(
          await container(
            isWeb: true,
          ).read(googleSignInAvailableProvider.future),
          isFalse,
        );
      });

      test('서버에 묻지 못하면 false다', () async {
        harness = await KratosTestHarness.create(authenticated: false);
        when(
          () => harness.kratos.createFlow(KratosFlowType.login),
        ).thenThrow(networkError);

        expect(
          await container(
            isWeb: true,
          ).read(googleSignInAvailableProvider.future),
          isFalse,
        );
      });
    });
  });

  group('기존 계정에 Google 연결', () {
    const linkFlow = KratosFlow(
      id: 'l1',
      messages: [KratosMessage(id: 1010016, type: 'info', text: '')],
      identifier: 'owner@example.com',
    );

    test('Kratos가 연결을 요청한 플로우면 연결할 계정 이메일을 돌려준다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      harness.stubGetFlow(KratosFlowType.login, linkFlow);
      final container = await boot();

      expect(
        await container
            .read(authProvider.notifier)
            .googleAccountLinkEmail('l1'),
        'owner@example.com',
      );
    });

    test('연결 요청이 아닌 플로우면 null이다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      harness.stubGetFlow(
        KratosFlowType.login,
        const KratosFlow(id: 'l1', identifier: 'owner@example.com'),
      );
      final container = await boot();

      expect(
        await container
            .read(authProvider.notifier)
            .googleAccountLinkEmail('l1'),
        isNull,
      );
    });

    test('그 플로우에 비밀번호를 내 로그인하고 Google 로그인 대기를 지운다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      await harness.prefs.setString(googleSignInCodeKey, 'init-code');
      harness.stubSubmit(
        KratosFlowType.login,
        const KratosSubmitResult(sessionToken: 'ory_st_linked'),
      );
      final container = await boot();

      await container
          .read(authProvider.notifier)
          .completeGoogleAccountLink(
            flowId: 'l1',
            email: 'owner@example.com',
            password: 'Owner-Pass-123',
          );

      verify(
        () => harness.kratos.submit(KratosFlowType.login, 'l1', {
          'method': 'password',
          'identifier': 'owner@example.com',
          'password': 'Owner-Pass-123',
        }),
      ).called(1);
      verifyNever(() => harness.kratos.createFlow(KratosFlowType.login));
      expect(container.read(authProvider), isA<AuthAuthenticated>());
      expect(await harness.storedSessionToken(), 'ory_st_linked');
      expect(harness.prefs.getString(googleSignInCodeKey), isNull);
    });

    test('비밀번호가 틀리면 AuthException이고 대기는 남긴다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      await harness.prefs.setString(googleSignInCodeKey, 'init-code');
      harness.stubSubmitError(KratosFlowType.login, kratosError(4000006));
      final container = await boot();

      await expectLater(
        container
            .read(authProvider.notifier)
            .completeGoogleAccountLink(
              flowId: 'l1',
              email: 'owner@example.com',
              password: 'wrong',
            ),
        throwsA(isA<AuthException>()),
      );
      expect(harness.prefs.getString(googleSignInCodeKey), 'init-code');
    });

    test('인증 전 계정이면 새 인증 플로우를 담은 EmailNotVerifiedException이다', () async {
      harness = await KratosTestHarness.create(authenticated: false);
      await harness.prefs.setString(googleSignInCodeKey, 'init-code');
      harness.stubSubmitError(
        KratosFlowType.login,
        const KratosException(
          statusCode: 403,
          errorId: 'session_verified_address_required',
          verificationFlowId: 'v9',
        ),
      );
      final container = await boot();

      await expectLater(
        container
            .read(authProvider.notifier)
            .completeGoogleAccountLink(
              flowId: 'l1',
              email: 'owner@example.com',
              password: 'Owner-Pass-123',
            ),
        throwsA(
          isA<EmailNotVerifiedException>()
              .having((e) => e.verificationFlowId, 'flow', 'v9')
              .having(
                (e) => e.message,
                'message',
                AuthErrorType.emailNotVerified.localized,
              ),
        ),
      );
      expect(container.read(authProvider), isA<AuthUnauthenticated>());
    });
  });
}
