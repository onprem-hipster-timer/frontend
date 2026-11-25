import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_detail_info.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_plan.dart';

const _states = {
  '계획됨': ScheduleState.planned,
  '확정됨': ScheduleState.confirmed,
  '취소됨': ScheduleState.cancelled,
};

const _repeats = {
  '없음': null,
  '매주 (월, 수)': 'FREQ=WEEKLY;BYDAY=MO,WE',
  '매일': 'FREQ=DAILY',
  '2주마다': 'FREQ=WEEKLY;INTERVAL=2',
  '매월': 'FREQ=MONTHLY',
};

@widgetbook.UseCase(name: '일정 상세 정보', type: ScheduleDetailInfo, path: '[달력]')
Widget scheduleDetailInfo(BuildContext context) {
  final knobs = context.knobs;
  final time = knobs.object.dropdown(
    label: '시간',
    options: const ['하루 중 몇 시간', '종일', '여러 날에 걸침'],
  );
  final state = knobs.object.dropdown(
    label: '상태',
    options: _states.keys.toList(),
    initialOption: '확정됨',
  );
  final description = knobs.object.dropdown(
    label: '설명',
    options: const ['짧게', '길게', '없음'],
  );
  final tagCount = knobs.int.slider(
    label: '태그 수',
    initialValue: 2,
    min: 0,
    max: planTags.length,
  );
  final repeat = knobs.object.dropdown(
    label: '반복',
    options: _repeats.keys.toList(),
    initialOption: '매주 (월, 수)',
  );
  final (start, end) = switch (time) {
    '종일' => (DateTime(2026, 3, 2), DateTime(2026, 3, 3)),
    '여러 날에 걸침' => (DateTime(2026, 3, 2, 10), DateTime(2026, 3, 4, 18)),
    _ => (DateTime(2026, 3, 2, 10), DateTime(2026, 3, 2, 12)),
  };
  final schedule = planSchedule(
    id: 'schedule-1',
    title: '분기 계획 회의',
    start: start,
    end: end,
    state: _states[state]!,
    tags: planTags.take(tagCount).toList(),
    description: switch (description) {
      '짧게' => '회의실 B에서 분기 계획을 함께 봅니다.',
      '길게' =>
        '회의실 B에서 분기 계획을 함께 봅니다. 지난 분기 회고 자료와 이번 분기 목표 초안을 '
            '미리 읽어 오고, 발표 순서는 모모, 토끼, 곰돌이 순으로 합니다. 끝나고 점심을 같이 먹어요.',
      _ => null,
    },
    recurrenceRule: _repeats[repeat],
  );
  // 일정 상세 화면의 본문 여백
  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: ScheduleDetailInfo(schedule: schedule),
  );
}
