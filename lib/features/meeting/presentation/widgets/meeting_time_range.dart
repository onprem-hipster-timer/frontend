import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 시간별 하루 범위. 정각 단위로 시작(0~23시)과 끝(시작 뒤~24시)을 고른다
class MeetingTimeRange extends StatelessWidget {
  const MeetingTimeRange({
    super.key,
    required this.startHour,
    required this.endHour,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final int startHour;
  final int endHour;
  final ValueChanged<int> onStartChanged;
  final ValueChanged<int> onEndChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _HourPicker(
          label: '시작 시각',
          value: startHour,
          hours: [for (var h = 0; h < 24; h++) h],
          onChanged: onStartChanged,
        ),
        const Text('~'),
        _HourPicker(
          label: '끝 시각',
          value: endHour,
          hours: [for (var h = startHour + 1; h <= 24; h++) h],
          onChanged: onEndChanged,
        ),
      ],
    );
  }
}

/// 정각 고르기 상자
class _HourPicker extends StatelessWidget {
  const _HourPicker({
    required this.label,
    required this.value,
    required this.hours,
    required this.onChanged,
  });

  final String label;
  final int value;
  final List<int> hours;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadius.mdAll,
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              borderRadius: AppRadius.mdAll,
              items: [
                for (final hour in hours)
                  DropdownMenuItem(value: hour, child: Text(hourLabel(hour))),
              ],
              onChanged: (hour) {
                if (hour != null) onChanged(hour);
              },
            ),
          ),
        ),
      ),
    );
  }
}
