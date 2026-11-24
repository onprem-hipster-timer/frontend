import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 달력 보기 설정 서랍. 바꾼 값마다 그 콜백을 부른다.
///
/// [header]를 주면 맨 위에 둔다(예: 낮은 화면의 화면 이동).
class CalendarSettingsDrawerView extends StatelessWidget {
  const CalendarSettingsDrawerView({
    super.key,
    this.header,
    required this.settings,
    required this.onShowHolidaysChanged,
    required this.onHighlightWeekendsChanged,
    required this.onUse24HourFormatChanged,
    required this.onFirstDayOfWeekChanged,
    required this.onMonthEventsPerDayChanged,
  });

  final Widget? header;

  /// 지금 설정
  final CalendarSettingsState settings;
  final ValueChanged<bool> onShowHolidaysChanged;
  final ValueChanged<bool> onHighlightWeekendsChanged;
  final ValueChanged<bool> onUse24HourFormatChanged;
  final ValueChanged<int> onFirstDayOfWeekChanged;

  /// 월 보기 칸의 일정 수. null은 자동
  final ValueChanged<int?> onMonthEventsPerDayChanged;

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            if (header != null) ...[header, const Divider(height: 32)],
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: AppSectionHeader('달력 보기'),
            ),
            SwitchListTile(
              title: const Text('공휴일 표시'),
              value: settings.showHolidays,
              onChanged: onShowHolidaysChanged,
            ),
            SwitchListTile(
              title: const Text('주말 강조'),
              subtitle: const Text('토·일요일 날짜에 색을 칠합니다'),
              value: settings.highlightWeekends,
              onChanged: onHighlightWeekendsChanged,
            ),
            SwitchListTile(
              title: const Text('24시간제'),
              subtitle: Text(settings.use24HourFormat ? '13:00' : '오후 1:00'),
              value: settings.use24HourFormat,
              onChanged: onUse24HourFormatChanged,
            ),
            const _Label('주 시작 요일'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: DateTime.sunday, label: Text('일요일')),
                  ButtonSegment(value: DateTime.monday, label: Text('월요일')),
                ],
                selected: {settings.firstDayOfWeek},
                showSelectedIcon: false,
                onSelectionChanged: (days) =>
                    onFirstDayOfWeekChanged(days.single),
              ),
            ),
            const _Label('월 보기 칸의 일정 수', hint: '자동은 화면 높이와 글자 크기에 맞춥니다'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final count in const [null, 1, 2, 3, 4, 5, 6])
                    ChoiceChip(
                      label: Text(count == null ? '자동' : '$count'),
                      selected: settings.monthEventsPerDay == count,
                      onSelected: (_) => onMonthEventsPerDayChanged(count),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.hint});

  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = this.hint;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: theme.textTheme.bodyLarge),
          if (hint != null)
            Text(
              hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
