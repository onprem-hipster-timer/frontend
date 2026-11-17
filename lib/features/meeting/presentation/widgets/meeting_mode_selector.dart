import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 모임 시간을 받는 방식 고르기
class MeetingModeSelector extends StatelessWidget {
  const MeetingModeSelector({
    super.key,
    required this.mode,
    required this.hourlyEnabled,
    required this.onChanged,
  });

  static const _icons = {
    MeetingMode.hourly: Icons.table_chart_outlined,
    MeetingMode.daily: Icons.calendar_today_outlined,
    MeetingMode.weekly: Icons.calendar_view_week_outlined,
  };

  final MeetingMode mode;

  /// 시간별을 고를 수 있는지
  final bool hourlyEnabled;

  final ValueChanged<MeetingMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        for (final option in MeetingMode.$valuesDefined)
          _ModeButton(
            icon: _icons[option]!,
            label: meetingModeLabel(option),
            selected: option == mode,
            onPressed: option == MeetingMode.hourly && !hourlyEnabled
                ? null
                : () => onChanged(option),
          ),
      ],
    );
  }
}

/// 방식 하나. 고른 방식은 강조색과 굵은 글자로 보인다
class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return MergeSemantics(
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: TextButton.icon(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: selected ? scheme.primary : scheme.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }
}
