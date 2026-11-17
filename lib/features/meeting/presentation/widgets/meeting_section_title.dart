import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_help_icon.dart';

/// 모임 만들기의 소제목. 옆에 작은 설명([caption])과 물음표 도움말([help])을 붙인다
class MeetingSectionTitle extends StatelessWidget {
  const MeetingSectionTitle(
    this.title, {
    super.key,
    this.caption,
    this.help,
    this.captionEmphasis = false,
  });

  final String title;
  final String? caption;
  final String? help;

  /// 설명 줄이 지금 할 일을 알릴 때 눈에 띄게 한다
  final bool captionEmphasis;

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
              color: captionEmphasis
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: captionEmphasis ? FontWeight.w600 : null,
            ),
          ),
        if (help != null) MeetingHelpIcon(help),
      ],
    );
  }
}
