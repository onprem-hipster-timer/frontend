import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/domain/timer_repository.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_control_button.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/friend_providers.dart';

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

final _friendsSince = DateTime.utc(2026, 1, 5);

final _friends = [
  for (final (i, name) in ['모모', '토끼', '곰돌이', '다람쥐'].indexed)
    FriendRead(
      userId: 'friend-$i',
      friendshipId: 'friendship-$i',
      since: _friendsSince,
      displayName: name,
    ),
];

/// 공유 설정 버튼이 여는 시트가 읽는 Provider. [timer]의 공유 범위를 지금 설정으로 읽고,
/// 선택한 친구면 모모·토끼를 고른 채로 연다. 저장은 아무 데도 보내지 않는다
List<Override> sampleShareOverrides(TimerRead timer) => [
  timerRepositoryProvider.overrideWithValue(_SampleTimers(timer)),
  friendsProvider.overrideWith((ref) async => _friends),
  timerViewsProvider.overrideWith(TimerViewsNotifier.new),
];

/// [timer] 하나의 공유 설정만 견본으로 돌려주고, 저장은 받기만 한다
class _SampleTimers implements TimerRepository {
  _SampleTimers(this.timer);

  final TimerRead timer;

  VisibilityRead _visibility(VisibilityLevel level, List<String> userIds) =>
      VisibilityRead(
        id: 'visibility-${timer.id}',
        resourceType: ResourceType.timer,
        resourceId: timer.id,
        ownerId: 'me',
        level: level,
        createdAt: timer.createdAt,
        updatedAt: timer.updatedAt,
        allowedUserIds: userIds,
      );

  @override
  Future<VisibilityRead?> getVisibility(String timerId) async =>
      switch (timer.visibilityLevel) {
        null => null,
        final level => _visibility(level, [
          if (level == VisibilityLevel.selected)
            for (final friend in _friends.take(2)) friend.userId,
        ]),
      };

  @override
  Future<VisibilityRead> setVisibility(
    String timerId,
    VisibilityUpdate data,
  ) async => _visibility(data.level, data.allowedUserIds ?? const []);

  @override
  Future<void> clearVisibility(String timerId) async {}

  @override
  Future<TimerRead> getTimer(String timerId) async => timer;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('공유 설정 시트는 ${invocation.memberName}을 쓰지 않는다');
}
