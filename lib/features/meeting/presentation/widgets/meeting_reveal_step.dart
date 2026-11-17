import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

/// 모임 만들기 폼의 한 단계. [animate]면 처음 나타날 때 아래로 펼쳐지며 떠오르고, 화면에 보이게 굴리며,
/// 스크린 리더에 [announcement]를 알린다(초점은 옮기지 않는다). 애니메이션을 줄였으면 바로 나타나고 바로 굴린다.
/// 처음부터 보이는 단계(되살린 폼 등)는 [animate] 없이 그대로 둔다
class MeetingRevealStep extends StatefulWidget {
  const MeetingRevealStep({
    super.key,
    required this.child,
    required this.animate,
    required this.announcement,
  });

  final Widget child;
  final bool animate;
  final String announcement;

  @override
  State<MeetingRevealStep> createState() => _MeetingRevealStepState();
}

class _MeetingRevealStepState extends State<MeetingRevealStep>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: widget.animate ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.animate) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduce = MediaQuery.disableAnimationsOf(context);
      if (reduce) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
      Scrollable.ensureVisible(
        context,
        duration: reduce ? Duration.zero : const Duration(milliseconds: 360),
        curve: Curves.easeOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
      SemanticsService.sendAnnouncement(
        View.of(context),
        widget.announcement,
        Directionality.of(context),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return SizeTransition(
      sizeFactor: curve,
      alignment: AlignmentDirectional.topStart,
      child: FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curve),
          child: widget.child,
        ),
      ),
    );
  }
}
