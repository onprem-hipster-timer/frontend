import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/mypage/presentation/pages/mypage_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

// ============================================================
// Mock 클래스
// ============================================================

class MockSupabaseClient extends Mock implements supa.SupabaseClient {}

class MockGoTrueClient extends Mock implements supa.GoTrueClient {}

class MockUser extends Mock implements supa.User {}

class MockSession extends Mock implements supa.Session {}

// ============================================================
// 테스트 헬퍼
// ============================================================

Widget buildMyPage({
  required MockSupabaseClient mockSupabase,
}) {
  return ProviderScope(
    overrides: [
      supabaseClientProvider.overrideWithValue(mockSupabase),
    ],
    child: const MaterialApp(
      home: MyPage(),
    ),
  );
}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockGoTrue;
  late MockUser mockUser;
  late MockSession mockSession;
  late StreamController<supa.AuthState> authStreamController;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockGoTrue = MockGoTrueClient();
    mockUser = MockUser();
    mockSession = MockSession();
    authStreamController = StreamController<supa.AuthState>.broadcast();

    when(() => mockSupabase.auth).thenReturn(mockGoTrue);
    when(() => mockGoTrue.onAuthStateChange)
        .thenAnswer((_) => authStreamController.stream);

    when(() => mockUser.email).thenReturn('user@example.com');
    when(() => mockUser.id).thenReturn('test-uid');
    when(() => mockSession.user).thenReturn(mockUser);
    when(() => mockSession.accessToken).thenReturn('test-token');
    when(() => mockSession.refreshToken).thenReturn('test-refresh');
    when(() => mockGoTrue.currentSession).thenReturn(mockSession);
  });

  tearDown(() {
    authStreamController.close();
  });

  // ============================================================
  // UI 렌더링
  // ============================================================
  group('UI 렌더링', () {
    testWidgets('앱바에 마이페이지 타이틀이 표시된다', (tester) async {
      await tester.pumpWidget(buildMyPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      expect(find.text('마이페이지'), findsOneWidget);
    });

    testWidgets('사용자 이메일이 표시된다', (tester) async {
      await tester.pumpWidget(buildMyPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      expect(find.text('user@example.com'), findsOneWidget);
    });

    testWidgets('프로필 아이콘이 표시된다', (tester) async {
      await tester.pumpWidget(buildMyPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('로그아웃 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(buildMyPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      expect(find.text('로그아웃'), findsOneWidget);
    });
  });

  // ============================================================
  // 로그아웃 플로우
  // ============================================================
  group('로그아웃 플로우', () {
    testWidgets('로그아웃 버튼을 누르면 확인 다이얼로그가 표시된다', (tester) async {
      await tester.pumpWidget(buildMyPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      expect(find.text('정말 로그아웃하시겠습니까?'), findsOneWidget);
    });

    testWidgets('확인 다이얼로그에서 취소하면 로그아웃되지 않는다', (tester) async {
      await tester.pumpWidget(buildMyPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      verifyNever(() => mockGoTrue.signOut());
    });

    testWidgets('확인 다이얼로그 바깥을 탭하면 로그아웃되지 않는다', (tester) async {
      await tester.pumpWidget(buildMyPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      expect(find.text('정말 로그아웃하시겠습니까?'), findsOneWidget);

      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      expect(find.text('정말 로그아웃하시겠습니까?'), findsNothing);
      verifyNever(() => mockGoTrue.signOut());
    });

    testWidgets('확인 다이얼로그에서 확인하면 signOut이 호출된다', (tester) async {
      when(() => mockGoTrue.signOut()).thenAnswer((_) async {});

      await tester.pumpWidget(buildMyPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '로그아웃').last);
      await tester.pumpAndSettle();

      verify(() => mockGoTrue.signOut()).called(1);
    });

    testWidgets('signOut 성공 시 스트림이 signedOut을 발행하면 미인증 상태로 전환된다',
        (tester) async {
      when(() => mockGoTrue.signOut()).thenAnswer((_) async {});

      await tester.pumpWidget(buildMyPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      expect(find.text('user@example.com'), findsOneWidget);

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '로그아웃').last);
      await tester.pumpAndSettle();

      authStreamController.add(supa.AuthState(
        supa.AuthChangeEvent.signedOut,
        null,
      ));
      await tester.pumpAndSettle();

      expect(find.text('user@example.com'), findsNothing);
    });

    testWidgets('signOut 실패 시 에러 배너가 표시된다', (tester) async {
      when(() => mockGoTrue.signOut())
          .thenThrow(supa.AuthException('Network error'));

      await tester.pumpWidget(buildMyPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '로그아웃').last);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('에러 배너의 X 버튼을 누르면 에러가 사라진다', (tester) async {
      when(() => mockGoTrue.signOut())
          .thenThrow(supa.AuthException('Network error'));

      await tester.pumpWidget(buildMyPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '로그아웃').last);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });

    testWidgets('signOut 실패 후 재시도하면 signOut이 다시 호출된다', (tester) async {
      var callCount = 0;
      when(() => mockGoTrue.signOut()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw supa.AuthException('Network error');
        }
      });

      await tester.pumpWidget(buildMyPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '로그아웃').last);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '로그아웃').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '로그아웃').last);
      await tester.pumpAndSettle();

      verify(() => mockGoTrue.signOut()).called(2);
    });
  });

  // ============================================================
  // 미인증 상태
  // ============================================================
  group('미인증 상태', () {
    testWidgets('세션이 없으면 이메일이 빈 문자열로 표시된다', (tester) async {
      when(() => mockGoTrue.currentSession).thenReturn(null);

      await tester.pumpWidget(buildMyPage(mockSupabase: mockSupabase));
      await tester.pumpAndSettle();

      expect(find.text('user@example.com'), findsNothing);
    });
  });
}
