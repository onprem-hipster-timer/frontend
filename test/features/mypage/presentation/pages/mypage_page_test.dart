import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/features/mypage/mypage.dart';
import 'package:momeet/shared/widgets/error_banner.dart';

import '../../../../helpers/kratos_mocks.dart';

// ============================================================
// 테스트 헬퍼
// ============================================================

Widget buildMyPage(KratosTestHarness harness) {
  return ProviderScope(
    overrides: harness.overrides,
    child: const MaterialApp(home: MyPage()),
  );
}

final _networkError = DioException(
  requestOptions: RequestOptions(path: '/self-service/logout/api'),
  type: DioExceptionType.connectionError,
);

Future<void> scrollToLogoutButton(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('로그아웃'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  late KratosTestHarness harness;

  setUpAll(() async {
    registerKratosFallbacks();
    await initializeDateFormatting('ko');
  });

  setUp(() async {
    harness = await KratosTestHarness.create();
  });

  // ============================================================
  // 프로필 섹션 UI
  // ============================================================
  group('프로필 섹션', () {
    testWidgets('앱바에 마이페이지 타이틀이 표시된다', (tester) async {
      await tester.pumpWidget(buildMyPage(harness));
      await tester.pumpAndSettle();

      expect(find.text('마이페이지'), findsOneWidget);
    });

    testWidgets('사용자 이메일이 표시된다', (tester) async {
      await tester.pumpWidget(buildMyPage(harness));
      await tester.pumpAndSettle();

      expect(find.text('user@example.com'), findsOneWidget);
    });

    testWidgets('프로필 아이콘이 표시된다', (tester) async {
      await tester.pumpWidget(buildMyPage(harness));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('가입일이 표시된다', (tester) async {
      await tester.pumpWidget(buildMyPage(harness));
      await tester.pumpAndSettle();

      expect(find.textContaining('가입일:'), findsOneWidget);
    });

    testWidgets('세션이 없으면 사용자 정보 없음이 표시된다', (tester) async {
      harness = await KratosTestHarness.create(authenticated: false);

      await tester.pumpWidget(buildMyPage(harness));
      await tester.pumpAndSettle();

      expect(find.text('user@example.com'), findsNothing);
    });
  });

  // ============================================================
  // 설정 섹션 UI
  // ============================================================
  group('설정 섹션', () {
    testWidgets('설정 섹션 타이틀이 표시된다', (tester) async {
      await tester.pumpWidget(buildMyPage(harness));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('설정'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('설정'), findsOneWidget);
    });

    testWidgets('다크 모드 토글이 표시된다', (tester) async {
      await tester.pumpWidget(buildMyPage(harness));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('다크 모드'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('다크 모드'), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    });

    testWidgets('타임존 설정 항목이 표시된다', (tester) async {
      await tester.pumpWidget(buildMyPage(harness));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('타임존 설정'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('타임존 설정'), findsOneWidget);
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('비밀번호 변경 항목이 표시된다', (tester) async {
      await tester.pumpWidget(buildMyPage(harness));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('비밀번호 변경'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('비밀번호 변경'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('로그아웃 항목이 표시된다', (tester) async {
      await tester.pumpWidget(buildMyPage(harness));
      await tester.pumpAndSettle();
      await scrollToLogoutButton(tester);

      expect(find.text('로그아웃'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });
  });

  // ============================================================
  // 로그아웃 플로우
  // ============================================================
  group('로그아웃 플로우', () {
    testWidgets('로그아웃 버튼을 누르면 확인 다이얼로그가 표시된다', (tester) async {
      await tester.pumpWidget(buildMyPage(harness));
      await tester.pumpAndSettle();
      await scrollToLogoutButton(tester);

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      expect(find.text('정말 로그아웃하시겠습니까?'), findsOneWidget);
    });

    testWidgets('확인 다이얼로그에서 취소하면 로그아웃되지 않는다', (tester) async {
      await tester.pumpWidget(buildMyPage(harness));
      await tester.pumpAndSettle();
      await scrollToLogoutButton(tester);

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      verifyNever(() => harness.kratos.logout(any()));
    });

    testWidgets('확인 다이얼로그 바깥을 탭하면 로그아웃되지 않는다', (tester) async {
      await tester.pumpWidget(buildMyPage(harness));
      await tester.pumpAndSettle();
      await scrollToLogoutButton(tester);

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      expect(find.text('정말 로그아웃하시겠습니까?'), findsOneWidget);

      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      expect(find.text('정말 로그아웃하시겠습니까?'), findsNothing);
      verifyNever(() => harness.kratos.logout(any()));
    });

    testWidgets('확인 다이얼로그에서 확인하면 signOut이 호출된다', (tester) async {
      when(() => harness.kratos.logout(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildMyPage(harness));
      await tester.pumpAndSettle();
      await scrollToLogoutButton(tester);

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '로그아웃').last);
      await tester.pumpAndSettle();

      verify(
        () => harness.kratos.logout(KratosTestHarness.sessionToken),
      ).called(1);
    });

    testWidgets('signOut 성공 시 미인증 상태로 전환된다', (tester) async {
      when(() => harness.kratos.logout(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildMyPage(harness));
      await tester.pumpAndSettle();

      expect(find.text('user@example.com'), findsOneWidget);
      await scrollToLogoutButton(tester);

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '로그아웃').last);
      await tester.pumpAndSettle();

      expect(find.text('user@example.com'), findsNothing);
    });

    testWidgets('signOut 실패 시 에러 배너가 표시된다', (tester) async {
      when(() => harness.kratos.logout(any())).thenThrow(_networkError);

      await tester.pumpWidget(buildMyPage(harness));
      await tester.pumpAndSettle();
      await scrollToLogoutButton(tester);

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '로그아웃').last);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, 1200));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('에러 배너의 X 버튼을 누르면 에러가 사라진다', (tester) async {
      when(() => harness.kratos.logout(any())).thenThrow(_networkError);

      await tester.pumpWidget(buildMyPage(harness));
      await tester.pumpAndSettle();
      await scrollToLogoutButton(tester);

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '로그아웃').last);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, 1200));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      final closeButton = find.descendant(
        of: find.byType(ErrorBanner),
        matching: find.byIcon(Icons.close_rounded),
      );
      expect(closeButton, findsOneWidget);

      final banner = tester.widget<ErrorBanner>(find.byType(ErrorBanner));
      banner.onDismiss?.call();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });

    testWidgets('signOut 실패 후 재시도하면 signOut이 다시 호출된다', (tester) async {
      var callCount = 0;
      when(() => harness.kratos.logout(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw _networkError;
      });

      await tester.pumpWidget(buildMyPage(harness));
      await tester.pumpAndSettle();
      await scrollToLogoutButton(tester);

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '로그아웃').last);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, 1200));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      await scrollToLogoutButton(tester);
      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '로그아웃').last);
      await tester.pumpAndSettle();

      verify(() => harness.kratos.logout(any())).called(2);
    });
  });
}
