import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_help_icon.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_quiet_panels.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 모임 화면 옆(좁으면 아래)의 상자. 제목 줄(있으면 도움말 [help], 오른쪽 끝 [trailing])과 내용. 제목 줄이
/// 한 줄에 들어가지 않으면 [trailing]을 다음 줄로 내린다.
///
/// [MeetingQuietPanels] 아래에서는 상자 없이 작은 제목과 내용만 두어 앞의 것보다 덜 눈에 띈다(좁은 화면 끝의
/// 일정 참여자·링크). [fill]이면 받은 높이를 채우고 내용은 제목 줄 아래 남은 높이를 쓴다(내용이 스스로 굴린다).
class MeetingPanel extends StatelessWidget {
  const MeetingPanel({
    super.key,
    required this.title,
    required this.child,
    this.help,
    this.trailing,
    this.color,
    this.foreground,
    this.fill = false,
  });

  final String title;
  final Widget child;
  final String? help;
  final bool fill;

  /// 제목 줄 오른쪽 끝
  final Widget? trailing;

  /// 상자 바탕색과 그 위 글자색. 없으면 카드 색이다
  final Color? color;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quiet = MeetingQuietPanels.of(context);
    final help = this.help;
    final titleRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: quiet
                  ? theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  : theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
            ),
          ),
        ),
        if (help != null) MeetingHelpIcon(help),
      ],
    );
    final trailing = this.trailing;
    // 제목과 오른쪽 끝이 한 줄에 들어가지 않으면 오른쪽 끝을 다음 줄로 내린다
    final heading = trailing == null
        ? Align(alignment: AlignmentDirectional.centerStart, child: titleRow)
        : Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 4,
            children: [titleRow, trailing],
          );
    if (quiet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: heading,
          ),
          const SizedBox(height: 4),
          child,
        ],
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: heading,
            ),
            const SizedBox(height: 8),
            if (fill) Expanded(child: child) else child,
          ],
        ),
      ),
    );
  }
}
