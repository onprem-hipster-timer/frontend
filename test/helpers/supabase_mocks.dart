import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

// ============================================================
// Mock 클래스
// ============================================================

class MockSupabaseClient extends Mock implements supa.SupabaseClient {}

class MockGoTrueClient extends Mock implements supa.GoTrueClient {}

class MockUser extends Mock implements supa.User {}

class MockSession extends Mock implements supa.Session {}

// ============================================================
// Supabase 테스트 Harness
// ============================================================

/// Supabase 관련 mock 객체와 공통 스텁을 묶어 관리하는 헬퍼.
///
/// ```dart
/// late SupabaseTestHarness harness;
///
/// setUp(() => harness.init());
/// tearDown(() => harness.dispose());
/// ```
class SupabaseTestHarness {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockGoTrue;
  late MockUser mockUser;
  late MockSession mockSession;
  late StreamController<supa.AuthState> authStreamController;

  /// mock 객체를 생성하고 공통 스텁을 등록한다.
  ///
  /// [authenticated]가 true(기본값)이면 mockUser/mockSession까지 세팅하고
  /// `currentSession`이 mockSession을 반환하도록 한다.
  /// false이면 `currentSession`이 null을 반환한다.
  void init({bool authenticated = true}) {
    mockSupabase = MockSupabaseClient();
    mockGoTrue = MockGoTrueClient();
    mockUser = MockUser();
    mockSession = MockSession();
    authStreamController = StreamController<supa.AuthState>.broadcast();

    when(() => mockSupabase.auth).thenReturn(mockGoTrue);
    when(
      () => mockGoTrue.onAuthStateChange,
    ).thenAnswer((_) => authStreamController.stream);

    if (authenticated) {
      when(() => mockUser.email).thenReturn('user@example.com');
      when(() => mockUser.id).thenReturn('test-uid');
      when(() => mockUser.createdAt).thenReturn('2024-01-01T00:00:00.000Z');
      when(() => mockSession.user).thenReturn(mockUser);
      when(() => mockSession.accessToken).thenReturn('test-access-token');
      when(() => mockSession.refreshToken).thenReturn('test-refresh-token');
      when(() => mockGoTrue.currentSession).thenReturn(mockSession);
    } else {
      when(() => mockGoTrue.currentSession).thenReturn(null);
    }
  }

  /// StreamController를 정리한다. tearDown에서 호출할 것.
  void dispose() {
    authStreamController.close();
  }
}
