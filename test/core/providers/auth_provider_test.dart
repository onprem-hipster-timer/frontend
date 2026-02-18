import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/exceptions/exceptions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

// ============================================================
// Mock 클래스
// ============================================================

class MockSupabaseClient extends Mock implements supa.SupabaseClient {}

class MockGoTrueClient extends Mock implements supa.GoTrueClient {}

class MockUser extends Mock implements supa.User {}

// ============================================================
// 테스트 헬퍼
// ============================================================

/// authProvider를 특정 상태로 오버라이드한 ProviderContainer 생성
ProviderContainer createContainer({required AuthStatus authState}) {
  return ProviderContainer(
    overrides: [
      authProvider.overrideWithValue(authState),
    ],
  );
}

void main() {
  late MockUser mockUser;

  setUp(() {
    mockUser = MockUser();
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockUser.id).thenReturn('user-123');
  });

  // ============================================================
  // isAuthenticatedProvider 테스트
  // ============================================================
  group('isAuthenticatedProvider', () {
    test('authenticated 상태에서 true를 반환한다', () {
      final container = createContainer(
        authState: AuthStatus.authenticated(
          user: mockUser,
          accessToken: 'test-token',
          refreshToken: 'refresh-token',
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(isAuthenticatedProvider), true);
    });

    test('unauthenticated 상태에서 false를 반환한다', () {
      final container = createContainer(
        authState: const AuthStatus.unauthenticated(),
      );
      addTearDown(container.dispose);

      expect(container.read(isAuthenticatedProvider), false);
    });

    test('loading 상태에서 false를 반환한다', () {
      final container = createContainer(
        authState: const AuthStatus.loading(),
      );
      addTearDown(container.dispose);

      expect(container.read(isAuthenticatedProvider), false);
    });

    test('error 상태에서 false를 반환한다', () {
      final container = createContainer(
        authState: const AuthStatus.error(message: '오류 발생'),
      );
      addTearDown(container.dispose);

      expect(container.read(isAuthenticatedProvider), false);
    });
  });

  // ============================================================
  // isAuthLoadingProvider 테스트
  // ============================================================
  group('isAuthLoadingProvider', () {
    test('loading 상태에서 true를 반환한다', () {
      final container = createContainer(
        authState: const AuthStatus.loading(),
      );
      addTearDown(container.dispose);

      expect(container.read(isAuthLoadingProvider), true);
    });

    test('authenticated 상태에서 false를 반환한다', () {
      final container = createContainer(
        authState: AuthStatus.authenticated(
          user: mockUser,
          accessToken: 'test-token',
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(isAuthLoadingProvider), false);
    });

    test('unauthenticated 상태에서 false를 반환한다', () {
      final container = createContainer(
        authState: const AuthStatus.unauthenticated(),
      );
      addTearDown(container.dispose);

      expect(container.read(isAuthLoadingProvider), false);
    });
  });

  // ============================================================
  // accessTokenProvider 테스트
  // ============================================================
  group('accessTokenProvider', () {
    test('authenticated 상태에서 토큰을 반환한다', () {
      final container = createContainer(
        authState: AuthStatus.authenticated(
          user: mockUser,
          accessToken: 'my-jwt-token',
          refreshToken: 'refresh-token',
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(accessTokenProvider), 'my-jwt-token');
    });

    test('unauthenticated 상태에서 null을 반환한다', () {
      final container = createContainer(
        authState: const AuthStatus.unauthenticated(),
      );
      addTearDown(container.dispose);

      expect(container.read(accessTokenProvider), isNull);
    });

    test('loading 상태에서 null을 반환한다', () {
      final container = createContainer(
        authState: const AuthStatus.loading(),
      );
      addTearDown(container.dispose);

      expect(container.read(accessTokenProvider), isNull);
    });
  });

  // ============================================================
  // currentUserProvider 테스트
  // ============================================================
  group('currentUserProvider', () {
    test('authenticated 상태에서 User를 반환한다', () {
      final container = createContainer(
        authState: AuthStatus.authenticated(
          user: mockUser,
          accessToken: 'token',
        ),
      );
      addTearDown(container.dispose);

      final user = container.read(currentUserProvider);
      expect(user, isNotNull);
      expect(user!.email, 'test@example.com');
    });

    test('unauthenticated 상태에서 null을 반환한다', () {
      final container = createContainer(
        authState: const AuthStatus.unauthenticated(),
      );
      addTearDown(container.dispose);

      expect(container.read(currentUserProvider), isNull);
    });
  });

  // ============================================================
  // authErrorProvider 테스트
  // ============================================================
  group('authErrorProvider', () {
    test('error 상태에서 에러 메시지를 반환한다', () {
      final container = createContainer(
        authState: const AuthStatus.error(message: '로그인 실패'),
      );
      addTearDown(container.dispose);

      expect(container.read(authErrorProvider), '로그인 실패');
    });

    test('authenticated 상태에서 null을 반환한다', () {
      final container = createContainer(
        authState: AuthStatus.authenticated(
          user: mockUser,
          accessToken: 'token',
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(authErrorProvider), isNull);
    });

    test('unauthenticated 상태에서 null을 반환한다', () {
      final container = createContainer(
        authState: const AuthStatus.unauthenticated(),
      );
      addTearDown(container.dispose);

      expect(container.read(authErrorProvider), isNull);
    });
  });

  // ============================================================
  // signInWithEmail 통합 테스트 (Mock Supabase)
  // ============================================================
  group('signInWithEmail 에러 처리', () {
    late MockSupabaseClient mockSupabase;
    late MockGoTrueClient mockGoTrue;
    late StreamController<supa.AuthState> authStreamController;
    late ProviderContainer container;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockGoTrue = MockGoTrueClient();
      authStreamController = StreamController<supa.AuthState>.broadcast();

      when(() => mockSupabase.auth).thenReturn(mockGoTrue);
      when(() => mockGoTrue.onAuthStateChange)
          .thenAnswer((_) => authStreamController.stream);
      when(() => mockGoTrue.currentSession).thenReturn(null);

      container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockSupabase),
        ],
      );
    });

    tearDown(() {
      authStreamController.close();
      container.dispose();
    });

    test('잘못된 자격 증명 시 한국어 메시지를 포함한 AuthException을 던진다', () async {
      when(() => mockGoTrue.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(supa.AuthException('Invalid login credentials'));

      await expectLater(
        () => container.read(authProvider.notifier).signInWithEmail(
              email: 'test@test.com',
              password: 'wrong',
            ),
        throwsA(isA<AuthException>()),
      );
    });

    test('이메일 미인증 시 AuthException을 던진다', () async {
      when(() => mockGoTrue.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(supa.AuthException('Email not confirmed'));

      await expectLater(
        () => container.read(authProvider.notifier).signInWithEmail(
              email: 'test@test.com',
              password: 'password',
            ),
        throwsA(isA<AuthException>()),
      );
    });

    test('네트워크 에러 시 AuthException을 던진다', () async {
      when(() => mockGoTrue.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(Exception('SocketException: Connection refused'));

      await expectLater(
        () => container.read(authProvider.notifier).signInWithEmail(
              email: 'test@test.com',
              password: 'password',
            ),
        throwsA(isA<AuthException>()),
      );
    });

    test('로그인 실패 후 auth 상태가 unauthenticated로 유지된다', () async {
      when(() => mockGoTrue.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(supa.AuthException('Invalid login credentials'));

      try {
        await container.read(authProvider.notifier).signInWithEmail(
              email: 'test@test.com',
              password: 'wrong',
            );
      } catch (_) {}

      final state = container.read(authProvider);
      expect(state, isA<AuthUnauthenticated>());
    });
  });
}
