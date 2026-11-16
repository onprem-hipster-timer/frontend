import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';

/// 날짜·시간을 어느 시간대로 읽는지 한 줄로 보인다
class MeetingTimezoneLabel extends StatelessWidget {
  const MeetingTimezoneLabel(this.timezone, {super.key});

  /// IANA 시간대 이름
  final String timezone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(Icons.public, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            timezoneBasisText(timezone),
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
