import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/editable_todo_tree_tile.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/timer_fixtures.dart';

void main() {
  final tree = buildTodoTree([
    makeTodo(id: 'parent'),
    makeTodo(id: 'child').copyWith(parentId: 'parent'),
  ]);
  var now = DateTime.utc(2026, 11, 6, 10, 0, 30);

  setUp(() => now = DateTime.utc(2026, 11, 6, 10, 0, 30));

  Future<void> pumpTile(
    WidgetTester tester, {
    int finishedSeconds = 0,
    List<TimerRead> active = const [],
  }) async {
    await tester.pumpWidget(
      pumpApp(
        Scaffold(
          body: EditableTodoTreeTile(node: tree.nodeMap['parent']!, tree: tree),
        ),
        overrides: [
          todoTimerAggregationsProvider.overrideWith(
            (ref) async => {
              'parent': TodoTimerAggregation(
                todoId: 'parent',
                totalElapsedSeconds: finishedSeconds,
                ownElapsedSeconds: finishedSeconds,
                timers: const [],
                hasActiveTimer: false,
              ),
            },
          ),
          activeTimersProvider.overrideWith((ref) async => active),
          serverClockProvider.overrideWithValue(
            ServerClock(deviceNow: () => now),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  TimerRead running(String todoId) => makeTimer(
    id: 't1',
    status: TimerStatus.running,
    startedAt: DateTime.utc(2026, 11, 6, 10),
    elapsedTime: 100,
  ).copyWith(todoId: todoId);

  testWidgets('끝난 타이머의 누적 시간을 보여 준다', (tester) async {
    await pumpTile(tester, finishedSeconds: 1500);

    expect(find.text('00:25:00'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('타이머 시간이 없으면 시간을 보여 주지 않는다', (tester) async {
    await pumpTile(tester);

    expect(find.text('00:00:00'), findsNothing);
    await unmount(tester);
  });

  testWidgets('진행 중인 타이머의 경과 시간을 서버 시각 기준으로 더해 1초마다 갱신한다', (tester) async {
    await pumpTile(tester, finishedSeconds: 1500, active: [running('parent')]);

    expect(find.text('00:27:10'), findsOneWidget);

    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('00:27:11'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('하위 Todo의 진행 중인 타이머도 부모 시간에 더한다', (tester) async {
    await pumpTile(tester, finishedSeconds: 1500, active: [running('child')]);

    expect(find.text('00:27:10'), findsOneWidget);
    await unmount(tester);
  });
}
