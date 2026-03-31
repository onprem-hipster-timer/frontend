import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/shared/widgets/error_banner.dart';

void main() {
  Widget buildTestWidget({
    required String? message,
    VoidCallback? onDismiss,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ErrorBanner(message: message, onDismiss: onDismiss),
      ),
    );
  }

  // ============================================================
  // 표시 / 숨김
  // ============================================================
  group('표시 / 숨김', () {
    testWidgets('message가 null이면 배너가 표시되지 않는다', (tester) async {
      await tester.pumpWidget(buildTestWidget(message: null));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });

    testWidgets('message가 있으면 에러 아이콘과 메시지가 표시된다', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(message: '이메일 또는 비밀번호가 올바르지 않습니다'),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('이메일 또는 비밀번호가 올바르지 않습니다'), findsOneWidget);
    });

    testWidgets('message가 변경되면 새 메시지가 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(message: '첫 번째 에러'));
      await tester.pumpAndSettle();
      expect(find.text('첫 번째 에러'), findsOneWidget);

      await tester.pumpWidget(buildTestWidget(message: '두 번째 에러'));
      await tester.pumpAndSettle();
      expect(find.text('두 번째 에러'), findsOneWidget);
      expect(find.text('첫 번째 에러'), findsNothing);
    });
  });

  // ============================================================
  // 닫기 버튼
  // ============================================================
  group('닫기 버튼', () {
    testWidgets('onDismiss가 있으면 X 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(message: '에러', onDismiss: () {}),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('onDismiss가 null이면 X 버튼이 표시되지 않는다', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(message: '에러', onDismiss: null),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('X 버튼을 누르면 onDismiss가 호출된다', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(
        buildTestWidget(
          message: '에러',
          onDismiss: () => dismissed = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(dismissed, isTrue);
    });
  });

  // ============================================================
  // 멀티라인 메시지
  // ============================================================
  testWidgets('줄바꿈이 포함된 메시지가 올바르게 렌더링된다', (tester) async {
    const msg = '이메일 인증이 완료되지 않았습니다.\n메일함을 확인해주세요';
    await tester.pumpWidget(buildTestWidget(message: msg));
    await tester.pumpAndSettle();

    expect(find.text(msg), findsOneWidget);
  });
}
