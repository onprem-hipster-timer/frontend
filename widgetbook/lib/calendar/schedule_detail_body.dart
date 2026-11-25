import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_detail_body.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_timer_section_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet_widgetbook/timer/samples_timer.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_plan.dart';

/// 견본 타이머가 시작한 시각
final _now = DateTime.utc(2026, 3, 2, 9);

@widgetbook.UseCase(name: '일정 상세', type: ScheduleDetailBody, path: '[달력]')
Widget scheduleDetailBody(BuildContext context) {
  final knobs = context.knobs;
  final linked = knobs.boolean(
    label: '할 일과 이어짐',
    description: '할 일로 바꾼 일정은 \'할 일로 변환\' 대신 \'연결된 할 일 보기\'를 둔다',
  );
  final timers = knobs.boolean(
    label: '타이머 기록',
    initialValue: true,
    description: '이 일정에서 시작한 타이머가 없으면 그 자리를 비운다',
  );
  final busy = knobs.object.dropdown(
    label: '진행 중',
    options: const ['없음', '할 일로 바꾸는 중', '삭제하는 중'],
    description: '하나가 진행되는 동안 다른 버튼은 누를 수 없다',
  );
  final schedule = planSchedule(
    id: 'schedule-1',
    title: '분기 계획 회의',
    start: DateTime(2026, 3, 2, 10),
    end: DateTime(2026, 3, 2, 12),
    tags: planTags.take(2).toList(),
    description: '회의실 B에서 분기 계획을 함께 봅니다.',
  ).copyWith(sourceTodoId: linked ? 'todo-1' : null);
  final idle = busy == '없음';
  // 일정 상세 화면의 본문 여백. 버튼을 누르면 앱처럼 반응하지 않고 그대로다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: ScheduleDetailBody(
      schedule: schedule,
      timerSection: ScheduleTimerSectionView(
        timers: AsyncData([
          if (timers)
            sampleTimer(
              status: TimerStatus.completed,
              title: '분기 계획 자료 읽기',
              remaining: Duration.zero,
            ),
        ]),
        now: _now,
      ),
      converting: busy == '할 일로 바꾸는 중',
      deleting: busy == '삭제하는 중',
      onOpenLinked: idle ? () {} : null,
      onConvert: idle ? () {} : null,
      onEdit: idle ? () {} : null,
      onDelete: idle ? () {} : null,
    ),
  );
}
