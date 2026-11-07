import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/timer_fixtures.dart';

TimerRead _timer(String id, TimerStatus status, String todoId, int elapsed) =>
    makeTimer(
      id: id,
      status: status,
      elapsedTime: elapsed,
    ).copyWith(todoId: todoId);

void main() {
  late int fetches;
  late List<TimerRead> history;
  late List<TimerRead> active;

  setUp(() {
    fetches = 0;
    history = [];
    active = [];
  });

  ProviderContainer boot() {
    final container = ProviderContainer(
      overrides: [
        timersProvider().overrideWith((ref) async {
          fetches++;
          return history;
        }),
        activeTimersProvider.overrideWith((ref) async => active),
        allTodoTreeProvider.overrideWith(
          (ref) async => buildTodoTree([
            makeTodo(id: 'parent'),
            makeTodo(id: 'child').copyWith(parentId: 'parent'),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(todoTimerAggregationsProvider, (_, _) {});
    return container;
  }

  Future<void> changeActive(
    ProviderContainer container,
    List<TimerRead> next,
  ) async {
    active = next;
    container.invalidate(activeTimersProvider);
    await container.read(activeTimersProvider.future);
    await container.pump();
    await container.read(todoTimerAggregationsProvider.future);
  }

  test('끝난 타이머의 경과 시간만 더하고 하위 Todo 시간을 부모에 더한다', () async {
    history = [
      _timer('t1', TimerStatus.completed, 'parent', 600),
      _timer('t2', TimerStatus.cancelled, 'parent', 300),
      _timer('t3', TimerStatus.running, 'parent', 100),
      _timer('t4', TimerStatus.paused, 'child', 50),
      _timer('t5', TimerStatus.completed, 'child', 120),
    ];
    final container = boot();

    final aggregations = await container.read(
      todoTimerAggregationsProvider.future,
    );

    expect(aggregations['parent']?.ownElapsedSeconds, 600);
    expect(aggregations['parent']?.totalElapsedSeconds, 720);
    expect(aggregations['child']?.totalElapsedSeconds, 120);
  });

  test('활성 타이머가 끝나 목록에서 빠질 때만 타이머 목록을 다시 읽는다', () async {
    active = [_timer('t1', TimerStatus.running, 'parent', 0)];
    final container = boot();
    await container.read(todoTimerAggregationsProvider.future);
    expect(fetches, 1);

    await changeActive(container, [
      _timer('t1', TimerStatus.paused, 'parent', 30),
    ]);
    expect(fetches, 1);

    await changeActive(container, []);
    expect(fetches, 2);
  });
}
