import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_control_button.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 대시보드가 보이는 타이머 상태. 노브 선택지로 쓴다
enum SampleTimerState {
  idle('대기 중'),
  running('진행 중'),
  paused('일시정지'),
  timeUp('시간 종료');

  const SampleTimerState(this.label);

  final String label;
}

const sampleTimerTitles = [
  '보고서 초안 쓰기',
  '영어 단어 외우기',
  '운동 계획 세우기',
  '책 한 챕터 읽기',
  '방 정리하기',
];

/// 카탈로그가 늘 같게 보이도록 고정한 시각
final _created = DateTime.utc(2026, 3, 2, 9);

TimerRead sampleTimer({
  int index = 0,
  TimerStatus status = TimerStatus.running,
  String? title,
  Duration allocated = const Duration(minutes: 25),
  Duration remaining = const Duration(minutes: 12, seconds: 34),
  TodoRead? todo,
  bool isShared = false,
  VisibilityLevel? visibilityLevel,
}) {
  final created = _created.add(Duration(minutes: index));
  return TimerRead(
    id: 'timer-$index',
    allocatedDuration: allocated.inSeconds,
    elapsedTime: (allocated - remaining).inSeconds,
    status: status,
    createdAt: created,
    updatedAt: created,
    startedAt: created,
    title: title ?? sampleTimerTitles[index % sampleTimerTitles.length],
    todo: todo,
    isShared: isShared,
    visibilityLevel: visibilityLevel,
  );
}

TodoRead sampleTodo({String title = '보고서 초안 쓰기', TodoStatus? status}) =>
    TodoRead(
      id: 'todo-1',
      title: title,
      todoGroupId: 'group-1',
      status: status ?? TodoStatus.scheduled,
      createdAt: _created,
    );

/// 앱 대시보드와 같은 다이얼 색: 휴식은 3차색, 시간 종료는 오류색, 일시정지는 흐린 주색
Color sampleDialColor(
  ColorScheme colorScheme,
  SampleTimerState state, {
  bool rest = false,
}) => rest && state == SampleTimerState.idle
    ? colorScheme.tertiary
    : switch (state) {
        SampleTimerState.timeUp => colorScheme.error,
        SampleTimerState.paused => colorScheme.primary.withValues(alpha: 0.5),
        _ => colorScheme.primary,
      };

/// 앱 대시보드와 같은 다이얼 아래 상태 문구
String? sampleCaption(SampleTimerState state) => switch (state) {
  SampleTimerState.timeUp => '시간 종료',
  SampleTimerState.paused => '일시정지',
  _ => null,
};

/// [state]의 타이머에 맞춘 조작 버튼
TimerControlButton sampleControlButton(
  SampleTimerState state, {
  bool breakSelected = false,
  bool starting = false,
  bool breakAvailable = true,
}) => TimerControlButton(
  activeTimer: state == SampleTimerState.idle
      ? null
      : sampleTimer(
          status: state == SampleTimerState.paused
              ? TimerStatus.paused
              : TimerStatus.running,
        ),
  starting: starting,
  timeUp: state == SampleTimerState.timeUp,
  breakSelected: breakSelected,
  onStart: () {},
  onStartBreak: breakAvailable ? () {} : null,
  onStop: () {},
  onPause: () {},
  onResume: () {},
  onExtend: () {},
);
