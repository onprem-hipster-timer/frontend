import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 모임 화면 옆(좁으면 아래)의 상자. 제목 줄과 내용
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
    final trailing = this.trailing;
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
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: foreground,
                            ),
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
