import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/trial/domain/trial_flow.dart';
import 'package:momeet/features/trial/presentation/utils/trial_samples.dart';
import 'package:momeet/shared/api/rest/export.dart';

void main() {
  final now = DateTime(2026, 11, 25, 14, 30);

  TrialFlow atCalendar() => trialStart(now);
  TrialFlow atSchedule() => atCalendar().openExam();
  TrialFlow converted() => atSchedule().convert();
  TrialFlow atTodo() => converted().openTodo();
  TrialFlow started() => atTodo().startTimer(const Duration(minutes: 25));
  TrialFlow atTimer() => started().openTimer();
  TrialFlow atEnd() => atTimer().finishTimer();

  group('견본 일정의 날', () {
    test('시험은 일주일 뒤, 약속은 같은 달의 사흘 전이다', () {
      final days = trialDays(DateTime(2026, 11, 10));
      expect(days.exam, DateTime(2026, 11, 17));
      expect(days.dinner, DateTime(2026, 11, 14));
    });

    test('사흘 전이 앞 달이면 약속은 사흘 뒤다', () {
      final days = trialDays(DateTime(2026, 11, 25));
      expect(days.exam, DateTime(2026, 12, 2));
      expect(days.dinner, DateTime(2026, 12, 5));
    });

    test('해가 바뀌어도 시험과 약속이 같은 달이다', () {
      final days = trialDays(DateTime(2026, 12, 26));
      expect(days.exam, DateTime(2027, 1, 2));
      expect(days.dinner, DateTime(2027, 1, 5));
    });

    test('달 끝의 시험이면 약속은 그 사흘 전이다', () {
      final days = trialDays(DateTime(2026, 12, 24));
      expect(days.exam, DateTime(2026, 12, 31));
      expect(days.dinner, DateTime(2026, 12, 28));
    });

    test('윤년 2월 끝에서도 같은 달이다', () {
      final days = trialDays(DateTime(2028, 2, 22));
      expect(days.exam, DateTime(2028, 2, 29));
      expect(days.dinner, DateTime(2028, 2, 26));
    });

    test('어느 날 시작해도 둘 다 시험의 달 안에 들고, 서로 다른 날이며, 오늘보다 뒤다', () {
      for (
        var day = DateTime(2026, 1, 1);
        day.year < 2029;
        day = DateTime(day.year, day.month, day.day + 1)
      ) {
        final days = trialDays(day);
        final reason = '$day';
        expect(
          days.exam,
          DateTime(day.year, day.month, day.day + 7),
          reason: reason,
        );
        expect(days.dinner.year, days.exam.year, reason: reason);
        expect(days.dinner.month, days.exam.month, reason: reason);
        expect(days.dinner, isNot(days.exam), reason: reason);
        expect(days.dinner.isAfter(day), isTrue, reason: reason);
      }
    });

    test('견본 일정은 시험이 확정, 약속이 계획됨이고 그날에 놓인다', () {
      final flow = trialStart(DateTime(2026, 12, 30, 23, 59));
      expect(flow.exam.startTime, DateTime(2027, 1, 6, 9));
      expect(flow.exam.endTime, DateTime(2027, 1, 6, 12));
      expect(flow.exam.state, ScheduleState.confirmed);
      expect(flow.dinner.startTime, DateTime(2027, 1, 3, 19));
      expect(flow.dinner.state, ScheduleState.planned);
      expect(flow.exam.sourceTodoId, isNull);
    });
  });

  group('차례대로', () {
    test('달력에서 시작하고 할 일과 타이머가 없다', () {
      final flow = atCalendar();
      expect(flow.step, TrialStep.calendar);
      expect(flow.todo, isNull);
      expect(flow.timer, isNull);
      expect(flow.recordedSeconds, 0);
    });

    test('시험을 열면 일정 상세다', () {
      expect(atSchedule().step, TrialStep.schedule);
    });

    test('변환하면 시험을 담은 할 일이 생기고 일정이 그 할 일을 가리키며, 상세에 머문다', () {
      final flow = converted();
      final todo = flow.todo!;
      expect(flow.step, TrialStep.schedule);
      expect(flow.exam.sourceTodoId, todo.id);
      expect(todo.title, flow.exam.title);
      expect(todo.description, flow.exam.description);
      expect(todo.tags, flow.exam.tags);
      expect(todo.deadline, flow.exam.startTime);
      expect(todo.status, TodoStatus.scheduled);
    });

    test('할 일을 열면 할 일 단계다', () {
      expect(atTodo().step, TrialStep.todo);
    });

    test('타이머를 시작하면 할 일에 이어진 진행 중 타이머가 생기고, 할 일에 머문다', () {
      final flow = started();
      final timer = flow.timer!;
      expect(flow.step, TrialStep.todo);
      expect(timer.status, TimerStatus.running);
      expect(timer.todoId, flow.todo!.id);
      expect(timer.todo, flow.todo);
      expect(timer.allocatedDuration, 1500);
      expect(timer.elapsedTime, 0);
      expect(timer.title, flow.todo!.title);
      expect(flow.recordedSeconds, 0);
    });

    test('작업 제목을 적어 시작하면 그 제목이고, 공백뿐이면 할 일 제목이다', () {
      final titled = atTodo().startTimer(
        const Duration(minutes: 25),
        title: ' 듣기 파트 ',
      );
      expect(titled.timer!.title, '듣기 파트');
      final blank = atTodo().startTimer(
        const Duration(minutes: 25),
        title: ' ',
      );
      expect(blank.timer!.title, blank.todo!.title);
    });

    test('시작한 시간이 그대로 정한 시간이다', () {
      final flow = atTodo().startTimer(const Duration(minutes: 45));
      expect(flow.timer!.allocatedDuration, 2700);
    });

    test('타이머를 열면 타이머 단계다', () {
      expect(atTimer().step, TrialStep.timer);
    });

    test('시간이 다 되면 끝이고, 타이머는 정한 시간을 다 쓴 완료, 할 일은 완료와 그 시간이 남는다', () {
      final flow = atEnd();
      final timer = flow.timer!;
      expect(flow.step, TrialStep.end);
      expect(timer.status, TimerStatus.completed);
      expect(timer.elapsedTime, timer.allocatedDuration);
      expect(timer.endedAt, timer.startedAt!.add(const Duration(minutes: 25)));
      expect(flow.todo!.status, TodoStatus.done);
      expect(timer.todo!.status, TodoStatus.done);
      expect(flow.recordedSeconds, 1500);
      expect(flow.exam.sourceTodoId, flow.todo!.id);
    });
  });

  group('차례가 아닌 호출은 그대로 둔다', () {
    final calls = <String, TrialFlow Function(TrialFlow)>{
      'openExam': (flow) => flow.openExam(),
      'convert': (flow) => flow.convert(),
      'openTodo': (flow) => flow.openTodo(),
      'startTimer': (flow) => flow.startTimer(const Duration(minutes: 25)),
      'openTimer': (flow) => flow.openTimer(),
      'finishTimer': (flow) => flow.finishTimer(),
    };
    final states = <String, TrialFlow Function()>{
      '달력': atCalendar,
      '일정 상세(변환 전)': atSchedule,
      '일정 상세(변환 후)': converted,
      '할 일(시작 전)': atTodo,
      '할 일(시작 후)': started,
      '타이머': atTimer,
      '끝': atEnd,
    };
    // 각 상태에서 다음으로 가는 호출
    const next = {
      '달력': 'openExam',
      '일정 상세(변환 전)': 'convert',
      '일정 상세(변환 후)': 'openTodo',
      '할 일(시작 전)': 'startTimer',
      '할 일(시작 후)': 'openTimer',
      '타이머': 'finishTimer',
    };

    for (final MapEntry(key: state, value: build) in states.entries) {
      for (final MapEntry(key: name, value: call) in calls.entries) {
        if (next[state] == name) continue;
        test('$state에서 $name', () {
          final flow = build();
          expect(call(flow), same(flow));
        });
      }
    }

    test('다음으로 간 뒤 같은 호출을 다시 해도 그대로다', () {
      for (final MapEntry(key: state, value: name) in next.entries) {
        final once = calls[name]!(states[state]!());
        expect(calls[name]!(once), same(once), reason: '$state의 $name');
      }
    });

    test('변환을 거듭해도 할 일은 하나이고 처음 것 그대로다', () {
      final once = converted();
      expect(once.convert().todo, same(once.todo));
    });
  });
}
