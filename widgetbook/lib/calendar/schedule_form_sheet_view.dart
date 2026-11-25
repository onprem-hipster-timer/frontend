import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_form_sheet_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../shared/samples_shared.dart';
import 'samples_plan.dart';

@widgetbook.UseCase(name: '일정 입력 시트', type: ScheduleFormSheetView, path: '[달력]')
Widget scheduleFormSheetView(BuildContext context) {
  final knobs = context.knobs;
  final edit = knobs.boolean(
    label: '일정 수정',
    description: '끄면 새 일정. 수정은 지금 제목·시간·설명으로 채워 연다',
  );
  final allDay = knobs.boolean(
    label: '종일',
    description: '시작이 그날 0시, 끝이 다음 날 0시인 시간을 받으면 종일로 연다',
  );
  final long = knobs.boolean(label: '긴 제목', description: '일정 수정에서 채워 둔 제목');
  final busy = knobs.boolean(
    label: '저장 중',
    description: '저장·수정을 누른 뒤 끝날 때까지 버튼에 진행 표시를 둔다',
  );
  final day = DateTime(2026, 3, 2);
  final (start, end) = allDay
      ? (day, day.add(const Duration(days: 1)))
      : (DateTime(2026, 3, 2, 10), DateTime(2026, 3, 2, 11));
  final schedule = edit
      ? planSchedule(
          id: 'schedule-1',
          title: long ? '분기 계획 회의와 지난 분기 회고 자료 같이 보기' : '분기 계획 회의',
          start: start,
          end: end,
          description: '회의실 B에서 분기 계획을 함께 봅니다.',
        )
      : null;
  // 앱에서는 달력의 + 버튼이나 날짜를 길게 누르면, 수정은 일정 상세의 수정을 누르면 아래에서 올라온다.
  // 노브를 바꾸면 입력한 값을 버리고 처음부터 채운다
  return SheetPreview(
    child: ScheduleFormSheetView(
      key: ValueKey((edit, allDay, long)),
      initialStartTime: start,
      initialEndTime: end,
      existingSchedule: schedule,
      busy: busy,
      onSubmit: (_, _, _) => Navigator.of(context).pop(),
    ),
  );
}
