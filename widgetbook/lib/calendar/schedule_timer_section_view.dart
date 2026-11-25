import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncError, AsyncLoading, AsyncValue;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_timer_section_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet_widgetbook/timer/samples_timer.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

enum _Load { done, loading, failed }

/// 일정에서 시작한 타이머들의 상태. 앞에서부터 쓴다
const _statuses = [
  TimerStatus.completed,
  TimerStatus.running,
  TimerStatus.paused,
  TimerStatus.completed,
  TimerStatus.cancelled,
];

/// 견본 타이머가 시작한 시각. 진행 중 타이머의 경과 시간을 여기서 센다
final _now = DateTime.utc(2026, 3, 2, 9);

@widgetbook.UseCase(
  name: '일정의 타이머',
  type: ScheduleTimerSectionView,
  path: '[달력]',
)
Widget scheduleTimerSectionView(BuildContext context) {
  final knobs = context.knobs;
  final load = knobs.object.dropdown(
    label: '상태',
    options: _Load.values,
    labelBuilder: (load) => switch (load) {
      _Load.done => '불러옴',
      _Load.loading => '불러오는 중',
      _Load.failed => '불러올 수 없음',
    },
    description: '불러오는 중에는 아무것도 두지 않는다',
  );
  final count = knobs.int.slider(
    label: '타이머 수',
    description: '이 일정에서 시작한 타이머. 0이면 섹션을 두지 않는다',
    initialValue: 3,
    max: _statuses.length,
  );
  final long = knobs.boolean(
    label: '긴 제목',
    description: '제목은 한 줄로 줄이고, 시간과 상태는 좁으면 다음 줄로 꺾는다',
  );
  final AsyncValue<List<TimerRead>> timers = switch (load) {
    _Load.done => AsyncData([
      for (var i = 0; i < count; i++)
        sampleTimer(
          index: i,
          status: _statuses[i],
          title: long ? '분기 계획 회의 자료 미리 읽고 질문할 거리 정리해 두기' : null,
          allocated: const Duration(minutes: 50),
          remaining: Duration(minutes: 5 + i * 7),
        ),
    ]),
    _Load.loading => const AsyncLoading(),
    _Load.failed => AsyncError(Exception('불러오기 실패'), StackTrace.empty),
  };
  // 앱에서는 일정 상세 화면의 일정 정보 아래, 좌우 24 여백 안에 놓인다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: ScheduleTimerSectionView(timers: timers, now: _now),
  );
}
