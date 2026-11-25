import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_timer_chip_view.dart';

void main() {
  /// 남은 시간 칩 하나를 둔 화면. 타이머 경로는 그 이름만 보인다
  Widget chipApp({VoidCallback? onPressed}) => MaterialApp.router(
    routerConfig: GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TodoTimerChipView(
              remainingSeconds: 754,
              onPressed: onPressed,
            ),
          ),
        ),
        GoRoute(
          path: AppRoute.timer.path,
          builder: (context, state) => const Text('타이머 화면'),
        ),
      ],
    ),
  );

  testWidgets('남은 시간을 누르면 타이머 화면으로 간다', (tester) async {
    await tester.pumpWidget(chipApp());

    await tester.tap(find.byType(TodoTimerChipView));
    await tester.pumpAndSettle();

    expect(find.text('타이머 화면'), findsOneWidget);
  });

  testWidgets('누르면 부를 콜백을 주면 남은 시간을 눌러도 타이머 화면으로 가지 않고 그 콜백을 부른다', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(chipApp(onPressed: () => pressed++));

    await tester.tap(find.byType(TodoTimerChipView));
    await tester.pumpAndSettle();

    expect(pressed, 1);
    expect(find.text('타이머 화면'), findsNothing);
  });
}
