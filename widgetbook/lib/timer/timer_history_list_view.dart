import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncError, AsyncLoading, AsyncValue;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/shared_timer_item_view.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_history_item_view.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_history_list_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../sample_provider_scope.dart';
import '../shared/samples_shared.dart';
import 'samples_timer.dart';

enum _Load { done, loading, failed }

/// 내 타이머 기록의 상태. 앞의 둘은 아직 도는 타이머다
const _statuses = [
  TimerStatus.running,
  TimerStatus.paused,
  TimerStatus.completed,
  TimerStatus.completed,
  TimerStatus.cancelled,
  TimerStatus.completed,
];

final _since = DateTime.utc(2026, 1, 5);

/// 견본 시각. 진행 중 타이머의 남은 시간을 여기서 센다
final _now = DateTime.utc(2026, 3, 2, 9);

/// 앱처럼 도는 타이머는 남은 시간, 끝난 타이머는 집중한 시간
Duration _shown(TimerRead timer) =>
    timer.status == TimerStatus.running || timer.status == TimerStatus.paused
    ? displayRemaining(timer, _now)
    : displayElapsed(timer, _now);

/// 친구 타이머의 주인. 이름 없는 친구가 있고, friend-3은 친구 목록에 없다
final _friends = [
  for (final (i, name) in ['모모', '토끼', null].indexed)
    FriendRead(
      userId: 'friend-$i',
      friendshipId: 'friendship-$i',
      since: _since,
      displayName: name,
    ),
];

/// [i]번째 기록. 셋씩 하루 앞 날짜로 묶인다
TimerRead _history(int i) {
  final timer = sampleTimer(
    index: i,
    status: _statuses[i % _statuses.length],
    visibilityLevel: i.isEven ? VisibilityLevel.friends : null,
  );
  final started = DateTime.utc(
    2026,
    3,
    2,
    9,
    i,
  ).subtract(Duration(days: i ~/ 3));
  return timer.copyWith(
    startedAt: started,
    endedAt: i < 2 ? null : started.add(const Duration(minutes: 25)),
  );
}

TimerRead _shared(int i) => sampleTimer(
  index: i + 2,
  status: _statuses[i % _statuses.length],
  isShared: true,
).copyWith(ownerId: 'friend-${i % 4}');

@widgetbook.UseCase(name: '타이머 목록', type: TimerHistoryListView, path: '[타이머]')
Widget timerHistoryListView(BuildContext context) {
  final knobs = context.knobs;
  final load = knobs.object.dropdown(
    label: '상태',
    options: _Load.values,
    labelBuilder: (load) => switch (load) {
      _Load.done => '불러옴',
      _Load.loading => '불러오는 중',
      _Load.failed => '불러올 수 없음',
    },
    description: '내 타이머와 친구 타이머 탭에 함께 쓴다',
  );
  final count = knobs.int.slider(
    label: '타이머 수',
    description: '내 타이머는 날짜별로 묶는다. 0이면 없다고 알린다',
    initialValue: 5,
    max: 12,
  );
  AsyncValue<List<TimerRead>> loaded(TimerRead Function(int i) timer) =>
      switch (load) {
        _Load.done => AsyncData([for (var i = 0; i < count; i++) timer(i)]),
        _Load.loading => const AsyncLoading(),
        _Load.failed => AsyncError(Exception('불러오기 실패'), StackTrace.empty),
      };
  // 앱에서는 좁은 화면에서 타이머 화면의 목록 버튼을 누르면 화면 높이의 60%로 올라오고,
  // 넓은 화면에서는 대시보드 오른쪽 칸에 놓인다. 공유 설정 버튼을 누르면 시트가 열린다
  return SampleProviderScope(
    overrides: sampleShareOverrides(sampleTimer()),
    child: SheetPreview(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: _List(history: loaded(_history), shared: loaded(_shared)),
      ),
    ),
  );
}

/// 고른 탭(내 타이머·친구 타이머)이 바로 보이도록 들고 있는다
class _List extends StatefulWidget {
  const _List({required this.history, required this.shared});

  final AsyncValue<List<TimerRead>> history;
  final AsyncValue<List<TimerRead>> shared;

  @override
  State<_List> createState() => _ListState();
}

class _ListState extends State<_List> {
  var _shared = false;

  @override
  Widget build(BuildContext context) {
    return TimerHistoryListView(
      shared: _shared,
      onSharedChanged: (shared) => setState(() => _shared = shared),
      history: widget.history,
      sharedTimers: widget.shared,
      friends: _friends,
      historyItemBuilder: (timer) => TimerHistoryItemView(
        timer: timer,
        duration: _shown(timer),
        timeUp: false,
        onExtend: () {},
        onPause: () {},
        onResume: () {},
        onStop: () {},
      ),
      sharedItemBuilder: (timer, ownerName) => SharedTimerItemView(
        timer: timer,
        ownerName: ownerName,
        duration: _shown(timer),
      ),
    );
  }
}
