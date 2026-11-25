import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_timer_start_button.dart';

void main() {
  testWidgets("타이머를 시작한 알림은 '타이머 보기'를 두고, 누르면 받은 콜백을 부른다", (tester) async {
    var shown = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTimerStartedNotice(
                ScaffoldMessenger.of(context),
                onShowTimer: () => shown++,
              ),
              child: const Text('띄우기'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('띄우기'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(SnackBar, '타이머를 시작했습니다'), findsOneWidget);

    await tester.tap(find.widgetWithText(SnackBarAction, '타이머 보기'));
    expect(shown, 1);
  });
}
