import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 내 모임을 불러오는 동안의 자리: 제목 줄과 설명 줄 모양 세 개. 스크린 리더는 불러오는 중이라고 한 번 읽는다
class MyMeetingsSkeleton extends StatelessWidget {
  const MyMeetingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: fill, borderRadius: AppRadius.smAll),
    );
    return Semantics(
      container: true,
      label: '내 ${Terms.meeting.withJosa('을', '를')} 불러오는 중',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                bar(160, 16),
                const SizedBox(height: 8),
                bar(120, 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
