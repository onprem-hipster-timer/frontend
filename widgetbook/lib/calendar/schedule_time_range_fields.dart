import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_time_range_fields.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '일정 시간 고르기',
  type: ScheduleTimeRangeFields,
  path: '[달력]',
)
Widget scheduleTimeRangeFields(BuildContext context) {
  final knobs = context.knobs;
  final allDay = knobs.boolean(label: '종일');
  final reversed = knobs.boolean(
    label: '종료가 시작보다 이름',
    description: '시간을 지정한 일정에서 종료가 시작보다 앞일 때 종료 칸 아래에 오류를 보인다',
  );
  final start = DateTime(2026, 3, 2, 10);
  final end = reversed ? DateTime(2026, 3, 2, 9) : DateTime(2026, 3, 2, 12);
  final ScheduleTimeRange value = allDay
      ? withAllDay((start: start, end: end, allDay: false), true)
      : (start: start, end: end, allDay: false);
  // 일정 폼 시트의 입력 칸 여백. 노브를 바꾸면 처음 값으로 다시 시작한다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: _TimeRangeDemo(key: ValueKey(value), initial: value),
  );
}

/// 종일 스위치와 날짜·시각 고르기가 바로 반영되도록 값을 들고 있는다
class _TimeRangeDemo extends StatefulWidget {
  const _TimeRangeDemo({super.key, required this.initial});

  final ScheduleTimeRange initial;

  @override
  State<_TimeRangeDemo> createState() => _TimeRangeDemoState();
}

class _TimeRangeDemoState extends State<_TimeRangeDemo> {
  late ScheduleTimeRange _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return ScheduleTimeRangeFields(
      value: _value,
      onChanged: (value) => setState(() => _value = value),
    );
  }
}
