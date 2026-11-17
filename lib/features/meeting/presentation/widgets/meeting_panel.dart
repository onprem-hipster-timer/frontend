import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_quiet_panels.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 모임 화면 옆(좁으면 아래)의 상자. 제목 줄과 내용.
///
/// [MeetingQuietPanels] 아래에서는 상자 없이 작은 제목과 내용만 두어 앞의 것보다 덜 눈에 띈다(좁은 화면 끝의
/// 일정 참여자·링크).
class MeetingPanel extends StatelessWidget {
  const MeetingPanel({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.color,
    this.foreground,
  });

  final String title;
  final Widget child;

  /// 제목 줄 오른쪽 끝
  final Widget? trailing;

  /// 상자 바탕색과 그 위 글자색. 없으면 카드 색이다
  final Color? color;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quiet = MeetingQuietPanels.of(context);
    final heading = Row(
      children: [
        Expanded(
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
        ?trailing,
      ],
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
            child,
          ],
        ),
      ),
    );
  }
}
