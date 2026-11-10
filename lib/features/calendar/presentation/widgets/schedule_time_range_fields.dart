import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 일정의 시작·종료와 종일 여부
typedef ScheduleTimeRange = ({DateTime start, DateTime end, bool allDay});

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59);

/// 종일을 켜면 시작을 그날 00:00, 종료를 그날 23:59로 맞춘다. 끄면 시각은 그대로 둔다
ScheduleTimeRange withAllDay(ScheduleTimeRange range, bool allDay) => allDay
    ? (start: _startOfDay(range.start), end: _endOfDay(range.end), allDay: true)
    : (start: range.start, end: range.end, allDay: false);

/// 시작을 [start]로 바꾼다. 종료보다 늦어지면 종료를 1시간 뒤(종일이면 그날 23:59)로 옮긴다
ScheduleTimeRange withStart(ScheduleTimeRange range, DateTime start) {
  final end = !start.isAfter(range.end)
      ? range.end
      : range.allDay
      ? _endOfDay(start)
      : start.add(const Duration(hours: 1));
  return (start: start, end: end, allDay: range.allDay);
}

/// 종료를 [end]로 바꾼다. 시작보다 빨라지면 시작을 1시간 앞(종일이면 그날 00:00)으로 옮긴다
ScheduleTimeRange withEnd(ScheduleTimeRange range, DateTime end) {
  final start = !end.isBefore(range.start)
      ? range.start
      : range.allDay
      ? _startOfDay(end)
      : end.subtract(const Duration(hours: 1));
  return (start: start, end: end, allDay: range.allDay);
}

/// 일정 폼의 종일 스위치와 시작·종료 고르기
///
/// 종일이면 날짜만, 아니면 날짜와 시각(24시간)을 차례로 고른다.
class ScheduleTimeRangeFields extends StatelessWidget {
  const ScheduleTimeRangeFields({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ScheduleTimeRange value;
  final ValueChanged<ScheduleTimeRange> onChanged;

  static final _dateTimeFormat = DateFormat('M월 d일 (E) HH:mm', 'ko');
  static final _dateFormat = DateFormat('M월 d일 (E)', 'ko');

  @override
  Widget build(BuildContext context) {
    final allDay = value.allDay;
    final format = allDay ? _dateFormat : _dateTimeFormat;
    final icon = allDay ? Icons.calendar_today : Icons.schedule;
    return Column(
      children: [
        SwitchListTile(
          title: const Text('종일'),
          subtitle: Text(
            allDay ? '하루 종일 일정으로 설정됩니다' : '시간을 지정할 수 있습니다',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          value: allDay,
          onChanged: (on) => onChanged(withAllDay(value, on)),
          contentPadding: EdgeInsets.zero,
        ),
        AppPickerField(
          label: '시작',
          icon: icon,
          value: format.format(value.start),
          onTap: () => _pick(context, isStart: true),
        ),
        AppPickerField(
          label: '종료',
          icon: icon,
          value: format.format(value.end),
          onTap: () => _pick(context, isStart: false),
          errorText: !allDay && value.end.isBefore(value.start)
              ? '종료 시간은 시작 시간보다 늦어야 합니다'
              : null,
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context, {required bool isStart}) async {
    final current = isStart ? value.start : value.end;
    final date = await showAppDatePicker(context, initial: current);
    if (date == null || !context.mounted) return;

    final DateTime picked;
    if (value.allDay) {
      picked = isStart ? _startOfDay(date) : _endOfDay(date);
    } else {
      final time = await showAppTimePicker(
        context,
        initial: TimeOfDay.fromDateTime(current),
      );
      if (time == null || !context.mounted) return;
      picked = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    }
    onChanged(isStart ? withStart(value, picked) : withEnd(value, picked));
  }
}
