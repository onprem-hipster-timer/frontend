// 체험하기 흐름. 서버에 보내지 않고 이 기기에서 아래 세 가지를 서버처럼 처리한다. 서버 동작이 바뀌면 손으로
// 맞춘다:
// - 할 일로 변환([TrialFlow.convert]): 일정의 제목·설명·태그를 담고 시작 시각을 마감으로 한 SCHEDULED 할 일이
//   생기고, 일정의 sourceTodoId가 그 할 일을 가리킨다
// - 타이머 시작([TrialFlow.startTimer]): 그 할 일에 이어진 RUNNING 타이머가 생긴다
// - 시간 종료([TrialFlow.finishTimer]): 타이머가 정한 시간을 모두 쓴 COMPLETED가 되고, 이어진 할 일은 DONE이
//   되어 그 시간을 누적 시간으로 보인다. 앱에서는 시간이 다 된 타이머가 일시정지로 기다리고, 사용자가 '완료'를
//   눌러 확인해야 끝나며 그때 할 일이 DONE이 된다. 체험은 이 둘을 시간 종료 하나로 합친다
//
// 테스트: test/features/trial/domain/trial_flow_test.dart, 화면을 따라 누르는 테스트는
// test/features/trial/presentation/pages/trial_page_test.dart
import 'package:flutter/foundation.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 체험에서 타이머의 정한 시간이 모두 지나가는 실제 시간
const trialTimerSweep = Duration(seconds: 3);

/// 체험하기의 단계. 보이는 차례다
enum TrialStep { calendar, schedule, todo, timer, end }

/// [today] 기준 견본 일정의 날: 시험은 일주일 뒤, 약속은 그 사흘 전(사흘 전이 앞 달이면 사흘 뒤). 둘 다
/// 달력이 여는 시험의 달 안에 든다
({DateTime exam, DateTime dinner}) trialDays(DateTime today) {
  final exam = DateTime(today.year, today.month, today.day + 7);
  final before = DateTime(exam.year, exam.month, exam.day - 3);
  return (
    exam: exam,
    dinner: before.month == exam.month
        ? before
        : DateTime(exam.year, exam.month, exam.day + 3),
  );
}

/// 체험하기를 한 단계씩 보이는 흐름. 시험 일정([exam])을 열고 → 할 일로 바꾸고 → 그 할 일로 타이머를 시작하고
/// → 시간이 다 되면 끝이다. 각 단계에서 다음으로 가는 동작만 받고, 차례가 아닌 호출은 그대로 둔다
@immutable
class TrialFlow {
  const TrialFlow({
    required this.exam,
    required this.dinner,
    required this.now,
    this.step = TrialStep.calendar,
    this.todo,
    this.timer,
  });

  /// 할 일로 바꿀 시험 일정
  final ScheduleRead exam;

  /// 날짜를 아직 정하지 않은 약속 일정(모임 만들기로 잇는다)
  final ScheduleRead dinner;

  /// 체험을 시작한 시각. 만드는 것의 시각으로 쓴다
  final DateTime now;

  final TrialStep step;

  /// 시험에서 바꾼 할 일. 바꾸기 전에는 null
  final TodoRead? todo;

  /// 할 일로 시작한 타이머. 시작하기 전에는 null
  final TimerRead? timer;

  /// 끝난 타이머로 남은 집중 시간(초)
  int get recordedSeconds =>
      timer?.status == TimerStatus.completed ? timer!.elapsedTime : 0;

  /// 달력에서 시험을 연다
  TrialFlow openExam() =>
      step == TrialStep.calendar ? _copy(step: TrialStep.schedule) : this;

  /// 시험을 할 일로 바꾼다. 상세에 머문다
  TrialFlow convert() {
    if (step != TrialStep.schedule || todo != null) return this;
    final converted = TodoRead(
      id: 'trial-todo',
      title: exam.title,
      todoGroupId: 'trial-todo-group',
      status: TodoStatus.scheduled,
      createdAt: now,
      tags: exam.tags,
      description: exam.description,
      deadline: exam.startTime,
    );
    return _copy(
      exam: exam.copyWith(sourceTodoId: converted.id),
      todo: converted,
    );
  }

  /// 바꾼 할 일을 연다
  TrialFlow openTodo() => step == TrialStep.schedule && todo != null
      ? _copy(step: TrialStep.todo)
      : this;

  /// 할 일에 이어 [duration] 동안 집중할 타이머를 시작한다. [title]이 비었으면 할 일 제목이다. 할 일에 머문다
  TrialFlow startTimer(Duration duration, {String title = ''}) {
    final todo = this.todo;
    if (step != TrialStep.todo || todo == null || timer != null) return this;
    return _copy(
      timer: TimerRead(
        id: 'trial-timer',
        allocatedDuration: duration.inSeconds,
        elapsedTime: 0,
        status: TimerStatus.running,
        createdAt: now,
        updatedAt: now,
        startedAt: now,
        todoId: todo.id,
        todo: todo,
        title: title.trim().isEmpty ? todo.title : title.trim(),
      ),
    );
  }

  /// 시작한 타이머를 연다
  TrialFlow openTimer() => step == TrialStep.todo && timer != null
      ? _copy(step: TrialStep.timer)
      : this;

  /// 타이머의 시간이 다 됐다. 끝으로 간다
  TrialFlow finishTimer() {
    final timer = this.timer;
    final todo = this.todo;
    if (step != TrialStep.timer || timer == null || todo == null) return this;
    final done = todo.copyWith(status: TodoStatus.done);
    return _copy(
      step: TrialStep.end,
      todo: done,
      timer: timer.copyWith(
        status: TimerStatus.completed,
        elapsedTime: timer.allocatedDuration,
        endedAt: timer.startedAt?.add(
          Duration(seconds: timer.allocatedDuration),
        ),
        todo: done,
      ),
    );
  }

  TrialFlow _copy({
    TrialStep? step,
    ScheduleRead? exam,
    TodoRead? todo,
    TimerRead? timer,
  }) => TrialFlow(
    exam: exam ?? this.exam,
    dinner: dinner,
    now: now,
    step: step ?? this.step,
    todo: todo ?? this.todo,
    timer: timer ?? this.timer,
  );
}
