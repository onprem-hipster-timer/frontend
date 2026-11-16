import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_help_icon.dart';

/// 모임 만들기의 소제목. 옆에 작은 설명([caption])과 물음표 도움말([help])을 붙인다
class MeetingSectionTitle extends StatelessWidget {
  const MeetingSectionTitle(this.title, {super.key, this.caption, this.help});

  final String title;
  final String? caption;
  final String? help;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caption = this.caption;
    final help = this.help;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (caption != null)
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (help != null) MeetingHelpIcon(help),
      ],
    );
  }
}
