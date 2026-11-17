import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/analytics/analytics_account_sync.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/auth/auth_user.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../helpers/fake_rest_clients.dart';
import '../../helpers/kratos_mocks.dart';

/// 인증 상태를 테스트에서 직접 바꾸는 [AuthNotifier]
class _Auth extends AuthNotifier {
  _Auth(this._initial);

  final AuthStatus _initial;

  @override
  AuthStatus build() => _initial;

  void set(AuthStatus next) => state = next;
}

final _member = AuthUser(
  id: 'test-uid',
  email: 'user@example.com',
  emailVerified: true,
  createdAt: DateTime.utc(2024),
);

void main() {
  late FakeUsersClient users;
  late InMemoryAnalyticsConsentBridge bridge;
  late _Auth auth;

  AuthStatus member() =>
      AuthStatus.authenticated(user: _member, accessToken: 'jwt');

  ProviderContainer open(
    AuthStatus status, {
    AnalyticsConsent? browser,
    bool? account,
    bool consentRequired = false,
  }) {
    users = FakeUsersClient(consentRequired: consentRequired);
    users.profile = users.profile.copyWith(analyticsConsent: account);
    bridge = InMemoryAnalyticsConsentBridge(browser);
    auth = _Auth(status);
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => auth),
        usersApiProvider.overrideWithValue(users),
        analyticsConsentBridgeProvider.overrideWithValue(bridge),
      ],
    );
    addTearDown(container.dispose);
    container.read(analyticsAccountSyncProvider);
    return container;
  }

  group('회원', () {
    test('계정 값이 있으면 브라우저 값보다 먼저다: 브라우저에 맞추고 배너를 숨긴다', () {
      fakeAsync((async) {
        open(member(), browser: AnalyticsConsent.denied, account: true);
        async.flushMicrotasks();

        expect(bridge.current, AnalyticsConsent.granted);
        expect(bridge.bannerVisible, isFalse);
        expect(users.agreed, isEmpty, reason: '계정에 다시 보내지 않는다');
      });
    });

    test('계정이 거부면 브라우저의 허용을 거둔다', () {
      fakeAsync((async) {
        open(member(), browser: AnalyticsConsent.granted, account: false);
        async.flushMicrotasks();

        expect(bridge.current, AnalyticsConsent.denied);
      });
    });

    test('계정에 값이 없고 브라우저에 고른 값이 있으면 지금 약관 버전의 동의로 한 번 보낸다', () {
      fakeAsync((async) {
        final container = open(member(), browser: AnalyticsConsent.granted);
        async.flushMicrotasks();

        expect(users.agreed, hasLength(1));
        final body = users.agreed.single;
        expect(body.version, testConsentVersion);
        expect(
          (body.ageOver14, body.terms, body.privacy, body.analytics),
          (true, true, true, true),
        );
        expect(users.profile.analyticsConsent, isTrue);

        container.invalidate(analyticsAccountSyncProvider);
        container.read(analyticsAccountSyncProvider);
        async.flushMicrotasks();
        expect(users.agreed, hasLength(1), reason: '계정에 값이 생겼다');
      });
    });

    test('보내지 못해도 같은 로그인 동안 다시 보내지 않는다', () {
      fakeAsync((async) {
        final container = open(member(), browser: AnalyticsConsent.denied);
        users.consentError = Exception('끊김');
        async.flushMicrotasks();
        final sent = users.agreed.length;

        auth.set(member());
        async.flushMicrotasks();
        expect(users.agreed.length, sent);
        expect(
          container.read(analyticsConsentProvider),
          AnalyticsConsent.denied,
        );
      });
    });

    test('둘 다 값이 없으면 모으지 않고 로그인한 동안 배너를 보이지 않는다', () {
      fakeAsync((async) {
        open(member());
        async.flushMicrotasks();

        expect(bridge.current, isNull);
        expect(bridge.bannerVisible, isFalse);
        expect(users.agreed, isEmpty);
      });
    });

    test('바뀐 약관에 아직 동의하지 않았으면 계정에 보내지도 브라우저를 바꾸지도 않는다', () {
      fakeAsync((async) {
        open(
          member(),
          browser: AnalyticsConsent.granted,
          consentRequired: true,
        );
        async.flushMicrotasks();

        expect(users.agreed, isEmpty);
        expect(bridge.current, AnalyticsConsent.granted);
        expect(bridge.bannerVisible, isFalse);
      });
    });

    test('로그아웃하면 마지막으로 맞춘 값을 브라우저에 두고, 값이 없을 때만 배너를 보인다', () {
      fakeAsync((async) {
        open(member(), account: true);
        async.flushMicrotasks();
        expect(bridge.current, AnalyticsConsent.granted);

        auth.set(const AuthStatus.unauthenticated());
        async.flushMicrotasks();
        expect(bridge.current, AnalyticsConsent.granted);
        expect(bridge.bannerVisible, isFalse);
      });
      fakeAsync((async) {
        open(member());
        async.flushMicrotasks();

        auth.set(const AuthStatus.unauthenticated());
        async.flushMicrotasks();
        expect(bridge.current, isNull);
        expect(bridge.bannerVisible, isTrue);
      });
    });
  });

  group('게스트와 방문자', () {
    test('브라우저 값만 쓴다: 고르지 않았으면 배너를 보이고 계정에는 아무것도 보내지 않는다', () {
      fakeAsync((async) {
        open(const AuthStatus.guest(guest: testGuest, accessToken: 'jwt'));
        async.flushMicrotasks();

        expect(bridge.bannerVisible, isTrue);
        expect(users.agreed, isEmpty);
        expect(users.reads, 0, reason: '회원 프로필을 읽지 않는다');
      });
    });

    test('브라우저에 고른 값이 있으면 배너를 보이지 않는다', () {
      fakeAsync((async) {
        open(
          const AuthStatus.unauthenticated(),
          browser: AnalyticsConsent.denied,
        );
        async.flushMicrotasks();

        expect(bridge.bannerVisible, isFalse);
        expect(bridge.current, AnalyticsConsent.denied);
      });
    });
  });

  test('세션을 확인하는 동안은 배너를 정하지 않는다', () {
    fakeAsync((async) {
      open(const AuthStatus.loading());
      async.flushMicrotasks();

      expect(bridge.bannerVisible, isNull);
    });
  });
}
