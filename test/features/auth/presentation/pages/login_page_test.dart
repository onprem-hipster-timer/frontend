import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/auth/presentation/pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

// ============================================================
// Mock 클래스
// ============================================================

class MockSupabaseClient extends Mock implements supa.SupabaseClient {}

class MockGoTrueClient extends Mock implements supa.GoTrueClient {}

// ============================================================
// 테스트 헬퍼
// ============================================================

/// LoginPage 테스트용 위젯 트리 생성
///
/// GoRouter 없이 MaterialApp으로 감싸서 테스트합니다.
/// (비밀번호 찾기 / 회원가입 네비게이션은 테스트 범위 밖)
Widget buildLoginPage({
  required MockSupabaseClient mockSupabase,
}) {
  return ProviderScope(
    overrides: [
      supabaseClientProvider.overrideWithValue(mockSupabase),
    ],
    child: const MaterialApp(
      home: LoginPage(),
    ),
  );
}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockGoTrue;
  late StreamController<supa.AuthState> authStreamController;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockGoTrue = MockGoTrueClient();
    authStreamController = StreamController<supa.AuthState>.broadcast();

    when(() => mockSupabase.auth).thenReturn(mockGoTrue);
    when(() => mockGoTrue.onAuthStateChange)
        .thenAnswer((_) => authStreamController.stream);
    when(() => mockGoTrue.currentSession).thenReturn(null);
  });

  tearDown(() {
    authStreamController.close();
  });

  /// 이메일 + 비밀번호를 입력하고 로그인 버튼을 누르는 헬퍼
  Future<void> enterCredentialsAndLogin(
    WidgetTester tester, {
    String email = 'test@test.com',
    String password = 'wrong-password',
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();
  }

  // ============================================================
  // 로그인 실패 시 에러 배너
  // ============================================================
  group('로그인 실패 시 에러 배너', () {
    testWidgets('잘못된 비밀번호 입력 시 에러 배너가 표시된다', (tester) async {
      when(() => mockGoTrue.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(supa.AuthException('Invalid login credentials'));

      await tester.pumpWidget(buildLoginPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      await enterCredentialsAndLogin(tester);

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('이메일 미인증 에러 시 에러 배너가 표시된다', (tester) async {
      when(() => mockGoTrue.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(supa.AuthException('Email not confirmed'));

      await tester.pumpWidget(buildLoginPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      await enterCredentialsAndLogin(tester);

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });

  // ============================================================
  // 에러 해제 동작
  // ============================================================
  group('에러 해제', () {
    setUp(() {
      when(() => mockGoTrue.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(supa.AuthException('Invalid login credentials'));
    });

    testWidgets('이메일 필드 수정 시 에러가 사라진다', (tester) async {
      await tester.pumpWidget(buildLoginPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      await enterCredentialsAndLogin(tester);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'new@email.com');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });

    testWidgets('비밀번호 필드 수정 시 에러가 사라진다', (tester) async {
      await tester.pumpWidget(buildLoginPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      await enterCredentialsAndLogin(tester);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(1), 'new-password');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });

    testWidgets('X 버튼을 누르면 에러가 사라진다', (tester) async {
      await tester.pumpWidget(buildLoginPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      await enterCredentialsAndLogin(tester);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });
  });

  // ============================================================
  // 폼 유효성 검증
  // ============================================================
  group('폼 유효성 검증', () {
    testWidgets('빈 이메일로 로그인 시 유효성 에러가 표시된다', (tester) async {
      await tester.pumpWidget(buildLoginPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.tap(find.text('로그인'));
      await tester.pumpAndSettle();

      expect(find.text('이메일을 입력해주세요'), findsOneWidget);
      verifyNever(() => mockGoTrue.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });

    testWidgets('@ 없는 이메일로 로그인 시 형식 에러가 표시된다', (tester) async {
      await tester.pumpWidget(buildLoginPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'invalid');
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.tap(find.text('로그인'));
      await tester.pumpAndSettle();

      expect(find.text('올바른 이메일 형식이 아닙니다'), findsOneWidget);
    });

    testWidgets('빈 비밀번호로 로그인 시 유효성 에러가 표시된다', (tester) async {
      await tester.pumpWidget(buildLoginPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
      await tester.tap(find.text('로그인'));
      await tester.pumpAndSettle();

      expect(find.text('비밀번호를 입력해주세요'), findsOneWidget);
    });
  });
}
