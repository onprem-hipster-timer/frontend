import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../helpers/supabase_mocks.dart';

void main() {
  late SupabaseTestHarness harness;
  late ProviderContainer container;

  setUp(() {
    harness = SupabaseTestHarness()..init();

    container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(harness.mockSupabase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    harness.dispose();
  });

  // ============================================================
  // 인증 상태에서 토큰/사용자 정보 확인
  // ============================================================
  group('인증 상태 토큰 확인', () {
    test('인증된 상태에서 accessToken이 올바르게 제공된다', () {
      final token = container.read(accessTokenProvider);
      expect(token, 'test-access-token');
    });

    test('인증된 상태에서 currentUser가 올바르게 제공된다', () {
      final user = container.read(currentUserProvider);
      expect(user, isNotNull);
      expect(user!.email, 'user@example.com');
    });

    test('인증된 상태에서 isAuthenticated가 true이다', () {
      expect(container.read(isAuthenticatedProvider), isTrue);
    });
  });

  // ============================================================
  // 로그아웃 시 토큰 정리 검증
  // ============================================================
  group('로그아웃 시 토큰 정리', () {
    test('signedOut 이벤트 후 accessToken이 null이 된다', () async {
      expect(container.read(accessTokenProvider), 'test-access-token');

      harness.authStreamController.add(
        supa.AuthState(supa.AuthChangeEvent.signedOut, null),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(accessTokenProvider), isNull);
    });

    test('signedOut 이벤트 후 currentUser가 null이 된다', () async {
      expect(container.read(currentUserProvider), isNotNull);

      harness.authStreamController.add(
        supa.AuthState(supa.AuthChangeEvent.signedOut, null),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(currentUserProvider), isNull);
    });

    test('signedOut 이벤트 후 isAuthenticated가 false가 된다', () async {
      expect(container.read(isAuthenticatedProvider), isTrue);

      harness.authStreamController.add(
        supa.AuthState(supa.AuthChangeEvent.signedOut, null),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(isAuthenticatedProvider), isFalse);
    });

    test('signedOut 이벤트 후 authStatus가 unauthenticated이다', () async {
      expect(container.read(authProvider), isA<AuthAuthenticated>());

      harness.authStreamController.add(
        supa.AuthState(supa.AuthChangeEvent.signedOut, null),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(authProvider), isA<AuthUnauthenticated>());
    });

    test('signOut 호출 후 스트림이 signedOut을 발행하면 모든 토큰이 정리된다', () async {
      when(() => harness.mockGoTrue.signOut()).thenAnswer((_) async {});

      await container.read(authProvider.notifier).signOut();

      harness.authStreamController.add(
        supa.AuthState(supa.AuthChangeEvent.signedOut, null),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(accessTokenProvider), isNull);
      expect(container.read(currentUserProvider), isNull);
      expect(container.read(isAuthenticatedProvider), isFalse);
      expect(container.read(authProvider), isA<AuthUnauthenticated>());

      verify(() => harness.mockGoTrue.signOut()).called(1);
    });
  });

  // ============================================================
  // 재로그인 시 토큰 복원 확인
  // ============================================================
  group('재로그인 시 토큰 복원', () {
    test('signedOut 후 signedIn 이벤트가 오면 토큰이 복원된다', () async {
      expect(container.read(accessTokenProvider), 'test-access-token');

      harness.authStreamController.add(
        supa.AuthState(supa.AuthChangeEvent.signedOut, null),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(accessTokenProvider), isNull);

      final newSession = MockSession();
      final newUser = MockUser();
      when(() => newUser.email).thenReturn('new@example.com');
      when(() => newUser.id).thenReturn('new-uid');
      when(() => newSession.user).thenReturn(newUser);
      when(() => newSession.accessToken).thenReturn('new-access-token');
      when(() => newSession.refreshToken).thenReturn('new-refresh-token');

      harness.authStreamController.add(
        supa.AuthState(supa.AuthChangeEvent.signedIn, newSession),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(accessTokenProvider), 'new-access-token');
      expect(container.read(currentUserProvider)?.email, 'new@example.com');
      expect(container.read(isAuthenticatedProvider), isTrue);
    });
  });
}
