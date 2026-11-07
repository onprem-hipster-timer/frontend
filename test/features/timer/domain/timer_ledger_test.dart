import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/domain/timer_ledger.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../helpers/schedule_fixtures.dart';
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

/// 일정·Todo를 포함해 읽은 REST 응답
TimerRead _read(String id, TimerStatus status, {required int updatedMinute}) =>
    _timer(id, status, updatedMinute: updatedMinute).copyWith(
      scheduleId: 'schedule-1',
      schedule: makeSchedule(),
      todoId: 'todo-1',
      todo: makeTodo(),
      tags: [makeTag()],
      isShared: true,
      visibilityLevel: VisibilityLevel.friends,
    );

/// 관계 필드가 없는 이벤트의 타이머. 기본은 [_read]와 같은 일정·Todo에 연결돼 있다
TimerRead _event(
  String id,
  TimerStatus status, {
  required int updatedMinute,
  String? scheduleId = 'schedule-1',
  String? todoId = 'todo-1',
  int elapsedTime = 0,
}) => _timer(
  id,
  status,
  updatedMinute: updatedMinute,
).copyWith(scheduleId: scheduleId, todoId: todoId, elapsedTime: elapsedTime);

void main() {
  late TimerLedger ledger;

  setUp(() => ledger = TimerLedger());

  group('updated_at 규칙', () {
    test('가진 값보다 나중이면 반영한다', () {
      ledger.apply(_timer('t1', TimerStatus.running, updatedMinute: 1));
      ledger.apply(_timer('t1', TimerStatus.paused, updatedMinute: 2));

      expect(ledger.active.single.status, TimerStatus.paused);
    });

    test('가진 값보다 이전이면 버린다', () {
      ledger.apply(_timer('t1', TimerStatus.paused, updatedMinute: 2));
      ledger.apply(_timer('t1', TimerStatus.running, updatedMinute: 1));

      expect(ledger.active.single.status, TimerStatus.paused);
    });

    test('같으면 반영한다', () {
      ledger.apply(_timer('t1', TimerStatus.running, updatedMinute: 1));
      final same = _timer(
        't1',
        TimerStatus.running,
        updatedMinute: 1,
      ).copyWith(title: '같은 시각의 응답');
      ledger.apply(same);

      expect(ledger.active.single.title, '같은 시각의 응답');
    });

    test('끝난 타이머보다 이전 이벤트가 늦게 와도 되살리지 않는다', () {
      ledger.apply(_timer('t1', TimerStatus.completed, updatedMinute: 3));
      ledger.apply(_timer('t1', TimerStatus.running, updatedMinute: 1));

      expect(ledger.active, isEmpty);
    });
  });

  group('삭제', () {
    test('지운 타이머를 목록에서 뺀다', () {
      ledger.apply(_timer('t1', TimerStatus.running, updatedMinute: 1));
      ledger.delete('t1');

      expect(ledger.active, isEmpty);
    });

    test('지운 뒤에 온 같은 ID는 나중 시각이어도 버린다', () {
      ledger.delete('t1');
      ledger.apply(_timer('t1', TimerStatus.running, updatedMinute: 9));

      expect(ledger.active, isEmpty);
    });

    test('REST로 다시 맞춰도 지운 타이머는 되살리지 않는다', () {
      ledger.delete('t1');
      ledger.resync([_timer('t1', TimerStatus.running, updatedMinute: 1)]);

      expect(ledger.active, isEmpty);
    });
  });

  group('REST로 다시 맞추기', () {
    test('목록에 없는 활성 타이머는 버린다', () {
      ledger.apply(_timer('t1', TimerStatus.running, updatedMinute: 1));
      ledger.resync([_timer('t2', TimerStatus.paused, updatedMinute: 2)]);

      expect(ledger.active.map((t) => t.id), ['t2']);
    });

    test('목록에서 뺀 타이머라도 그보다 이전 이벤트는 버린다', () {
      ledger.apply(_timer('t1', TimerStatus.running, updatedMinute: 5));
      ledger.resync([]);
      ledger.apply(_timer('t1', TimerStatus.running, updatedMinute: 3));

      expect(ledger.active, isEmpty);
    });

    test('목록에서 뺀 타이머라도 더 나중 이벤트는 다시 넣는다', () {
      ledger.apply(_timer('t1', TimerStatus.running, updatedMinute: 5));
      ledger.resync([]);
      ledger.apply(_timer('t1', TimerStatus.running, updatedMinute: 7));

      expect(ledger.active.single.id, 't1');
    });

    test('목록의 타이머에도 updated_at 규칙을 쓴다', () {
      ledger.apply(_timer('t1', TimerStatus.paused, updatedMinute: 5));
      ledger.resync([_timer('t1', TimerStatus.running, updatedMinute: 4)]);

      expect(ledger.active.single.status, TimerStatus.paused);
    });
  });

  group('실시간 이벤트', () {
    test('가진 관계 필드는 두고 타이머 자체 필드만 바꾼다', () {
      ledger.apply(_read('t1', TimerStatus.running, updatedMinute: 1));

      final needsRead = ledger.applyPartial(
        _event('t1', TimerStatus.paused, updatedMinute: 2, elapsedTime: 90),
      );

      final timer = ledger.active.single;
      expect(needsRead, isFalse);
      expect(timer.status, TimerStatus.paused);
      expect(timer.elapsedTime, 90);
      expect(timer.todo, makeTodo());
      expect(timer.schedule, makeSchedule());
      expect(timer.tags, [makeTag()]);
      expect(timer.isShared, isTrue);
      expect(timer.visibilityLevel, VisibilityLevel.friends);
    });

    test('todo_id가 바뀌면 가진 todo를 버리고 다시 읽기를 요청한다', () {
      ledger.apply(_read('t1', TimerStatus.running, updatedMinute: 1));

      final needsRead = ledger.applyPartial(
        _event('t1', TimerStatus.running, updatedMinute: 2, todoId: 'todo-2'),
      );

      final timer = ledger.active.single;
      expect(needsRead, isTrue);
      expect(timer.todoId, 'todo-2');
      expect(timer.todo, isNull);
      expect(timer.schedule, makeSchedule());
    });

    test('schedule_id가 바뀌면 가진 schedule을 버리고 다시 읽기를 요청한다', () {
      ledger.apply(_read('t1', TimerStatus.running, updatedMinute: 1));

      final needsRead = ledger.applyPartial(
        _event(
          't1',
          TimerStatus.running,
          updatedMinute: 2,
          scheduleId: 'schedule-2',
        ),
      );

      final timer = ledger.active.single;
      expect(needsRead, isTrue);
      expect(timer.scheduleId, 'schedule-2');
      expect(timer.schedule, isNull);
      expect(timer.todo, makeTodo());
    });

    test('처음 보는 타이머는 그대로 넣고 다시 읽기를 요청한다', () {
      final needsRead = ledger.applyPartial(
        _event('t1', TimerStatus.running, updatedMinute: 1),
      );

      expect(needsRead, isTrue);
      expect(ledger.active.single.id, 't1');
    });

    test('다시 읽은 결과를 반영하면 관계 필드가 채워지고 그 뒤 이벤트는 다시 읽지 않는다', () {
      ledger.applyPartial(_event('t1', TimerStatus.running, updatedMinute: 1));
      ledger.apply(_read('t1', TimerStatus.running, updatedMinute: 1));

      final needsRead = ledger.applyPartial(
        _event('t1', TimerStatus.paused, updatedMinute: 2),
      );

      expect(needsRead, isFalse);
      expect(ledger.active.single.todo, makeTodo());
    });

    test('updated_at이 이전인 이벤트는 버리고 다시 읽기를 요청하지 않는다', () {
      ledger.apply(_read('t1', TimerStatus.paused, updatedMinute: 5));

      final needsRead = ledger.applyPartial(
        _event('t1', TimerStatus.running, updatedMinute: 3, todoId: 'todo-2'),
      );

      final timer = ledger.active.single;
      expect(needsRead, isFalse);
      expect(timer.status, TimerStatus.paused);
      expect(timer.todo, makeTodo());
    });

    test('지운 타이머의 이벤트는 버리고 다시 읽기를 요청하지 않는다', () {
      ledger.delete('t1');

      final needsRead = ledger.applyPartial(
        _event('t1', TimerStatus.running, updatedMinute: 9),
      );

      expect(needsRead, isFalse);
      expect(ledger.active, isEmpty);
    });
  });

  test('활성 타이머만 최근에 시작한 순으로 돌려준다', () {
    ledger
      ..apply(
        _timer('old', TimerStatus.paused, updatedMinute: 1, startedMinute: 1),
      )
      ..apply(
        _timer('new', TimerStatus.running, updatedMinute: 5, startedMinute: 5),
      )
      ..apply(_timer('done', TimerStatus.completed, updatedMinute: 9));

    expect(ledger.active.map((t) => t.id), ['new', 'old']);
  });
}
