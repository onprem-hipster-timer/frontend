import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/domain/timer_ledger.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../helpers/timer_fixtures.dart';

TimerRead _timer(
  String id,
  TimerStatus status, {
  required int updatedMinute,
  int startedMinute = 0,
}) => makeTimer(
  id: id,
  status: status,
  startedAt: DateTime.utc(2026, 11, 6, 10, startedMinute),
).copyWith(updatedAt: DateTime.utc(2026, 11, 6, 10, updatedMinute));

/// Todo를 포함해 읽은 REST 응답
TimerRead _read(String id, TimerStatus status, {required int updatedMinute}) =>
    _timer(
      id,
      status,
      updatedMinute: updatedMinute,
    ).copyWith(todoId: 'todo-1', todo: makeTodo());

void main() {
  late TimerLedger ledger;

  setUp(() => ledger = TimerLedger());

  test('처음 보는 타이머가 끝난 상태로 오면 활성에 넣지 않는다', () {
    ledger.apply(_timer('t1', TimerStatus.completed, updatedMinute: 1));

    expect(ledger.active, isEmpty);
  });

  test('끝난 타이머 뒤에 더 나중 시각의 RUNNING이 오면 다시 활성이 된다', () {
    ledger.apply(_timer('t1', TimerStatus.completed, updatedMinute: 1));
    ledger.apply(_timer('t1', TimerStatus.running, updatedMinute: 2));

    expect(ledger.active.single.id, 't1');
  });

  test('빈 목록으로 다시 맞추면 활성 타이머가 모두 빠진다', () {
    ledger
      ..apply(_timer('t1', TimerStatus.running, updatedMinute: 1))
      ..apply(_timer('t2', TimerStatus.paused, updatedMinute: 1));
    ledger.resync([]);

    expect(ledger.active, isEmpty);
  });

  test('다시 맞춘 뒤 목록에서 빠진 타이머의 늦은 이벤트는 다시 넣는다', () {
    // 목록에 없는 것은 "지금은 활성이 아님"이지 삭제가 아니다
    ledger.apply(_timer('t1', TimerStatus.running, updatedMinute: 1));
    ledger.resync([]);
    ledger.apply(_timer('t1', TimerStatus.running, updatedMinute: 5));

    expect(ledger.active.single.id, 't1');
  });

  test('같은 타이머를 두 번 지워도 문제없다', () {
    ledger.apply(_timer('t1', TimerStatus.running, updatedMinute: 1));
    ledger
      ..delete('t1')
      ..delete('t1');

    expect(ledger.active, isEmpty);
  });

  test('다시 맞추기 목록 안의 중복 ID는 updated_at이 나중인 쪽이 남는다', () {
    ledger.resync([
      _timer('t1', TimerStatus.running, updatedMinute: 1),
      _timer('t1', TimerStatus.paused, updatedMinute: 2),
    ]);

    expect(ledger.active.single.status, TimerStatus.paused);
  });

  test('연결된 Todo가 지워져 todo_id가 빠진 이벤트면 todo를 버리고 다시 읽기를 요청한다', () {
    // Todo를 지우면 서버가 이벤트 없이 todo_id를 null로 바꾸므로 그 타이머의 다음 이벤트에서 알게 된다
    ledger.apply(_read('t1', TimerStatus.running, updatedMinute: 1));

    final needsRead = ledger.applyPartial(
      _timer('t1', TimerStatus.paused, updatedMinute: 2),
    );

    expect(needsRead, isTrue);
    expect(ledger.active.single.todo, isNull);
  });

  test('다시 읽은 결과가 그 사이 이벤트보다 이전이라 버려지면 다음 이벤트도 다시 읽기를 요청한다', () {
    ledger.applyPartial(_timer('t1', TimerStatus.running, updatedMinute: 1));
    ledger.applyPartial(_timer('t1', TimerStatus.paused, updatedMinute: 3));
    ledger.apply(_read('t1', TimerStatus.running, updatedMinute: 2));

    final needsRead = ledger.applyPartial(
      _timer('t1', TimerStatus.running, updatedMinute: 4),
    );

    expect(needsRead, isTrue);
    expect(ledger.active.single.todo, isNull);
  });

  test('다시 맞추기로 목록에서 빠졌던 타이머의 이벤트는 다시 읽기를 요청한다', () {
    ledger.apply(_read('t1', TimerStatus.running, updatedMinute: 1));
    ledger.resync([]);

    final needsRead = ledger.applyPartial(
      _timer('t1', TimerStatus.running, updatedMinute: 5),
    );

    expect(needsRead, isTrue);
    expect(ledger.active.single.todo, isNull);
  });

  test('다시 맞추기 목록에 든 타이머는 그 뒤 이벤트에서 다시 읽지 않는다', () {
    ledger.applyPartial(
      _timer(
        't1',
        TimerStatus.running,
        updatedMinute: 1,
      ).copyWith(todoId: 'todo-1'),
    );
    ledger.resync([_read('t1', TimerStatus.running, updatedMinute: 1)]);

    final needsRead = ledger.applyPartial(
      _timer(
        't1',
        TimerStatus.paused,
        updatedMinute: 2,
      ).copyWith(todoId: 'todo-1'),
    );

    expect(needsRead, isFalse);
    expect(ledger.active.single.todo, makeTodo());
  });

  test('다시 읽는 사이 지워진 타이머는 읽은 결과로 되살아나지 않는다', () {
    ledger.applyPartial(_timer('t1', TimerStatus.running, updatedMinute: 1));
    ledger.delete('t1');
    ledger.apply(_read('t1', TimerStatus.running, updatedMinute: 1));

    expect(ledger.active, isEmpty);
  });

  test('Todo 없는 타이머는 이벤트마다 다시 읽지 않는다', () {
    ledger.apply(_timer('t1', TimerStatus.running, updatedMinute: 1));

    expect(
      ledger.applyPartial(_timer('t1', TimerStatus.paused, updatedMinute: 2)),
      isFalse,
    );
    expect(
      ledger.applyPartial(_timer('t1', TimerStatus.running, updatedMinute: 3)),
      isFalse,
    );
  });

  test('updateTodo는 그 Todo에 연결된 타이머가 없으면 아무것도 바꾸지 않는다', () {
    ledger.apply(_read('t1', TimerStatus.running, updatedMinute: 1));

    ledger.updateTodo(makeTodo(id: 'todo-9'));

    expect(ledger.active.single.todo, makeTodo());
  });

  test('started_at이 없는 활성 타이머도 목록에 남는다', () {
    ledger.apply(
      makeTimer(
        id: 't1',
        status: TimerStatus.paused,
      ).copyWith(updatedAt: DateTime.utc(2026, 11, 6, 10, 1)),
    );

    expect(ledger.active.single.id, 't1');
  });
}
