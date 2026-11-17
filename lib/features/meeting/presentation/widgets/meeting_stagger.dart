import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_step_switcher.dart';

/// 넘어가며 나타나는 질문의 한 조각. [order]번째(질문 글 0, 안내 1, 답 2) 차례에 흐림과 아래 [meetingStepRise]
/// 자리에서 올라오며 나타난다([MeetingStepSwitcher]). 넘어가는 질문 밖이거나 다 나타났으면 그대로 그린다.
/// 투명도와 그리는 자리만 바꾼다(배치는 그대로다)
class MeetingStagger extends StatelessWidget {
  const MeetingStagger({super.key, required this.order, required this.child});

  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final entrance = meetingStepEntrance(context);
    if (entrance == null) return child;
    final shown = entrance.drive(CurveTween(curve: meetingStepInterval(order)));
    return FadeTransition(
      opacity: shown,
      child: AnimatedBuilder(
        animation: shown,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, meetingStepRise * (1 - shown.value)),
          child: child,
        ),
        child: child,
      ),
    );
  }
}
