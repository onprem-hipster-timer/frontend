import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

/// 모임 만들기의 한 질문. [animate]면 처음 나타날 때 [delay]만큼 기다렸다 아래로 펼쳐지며 떠오르고, 화면에 보이게
/// 굴리며, 스크린 리더에 [announcement]를 알린다(초점은 옮기지 않는다). 애니메이션을 줄였으면 기다리지 않고 바로
/// 나타나고 바로 굴린다. 처음부터 보이는 질문(첫 질문, 되살린 폼)은 [animate] 없이 그대로 둔다
class MeetingRevealStep extends StatefulWidget {
  const MeetingRevealStep({
    super.key,
    required this.child,
    required this.animate,
    required this.announcement,
    this.delay = Duration.zero,
  });

  final Widget child;
  final bool animate;
  final String announcement;
  final Duration delay;

  @override
  State<MeetingRevealStep> createState() => _MeetingRevealStepState();
}

class _MeetingRevealStepState extends State<MeetingRevealStep>
    with SingleTickerProviderStateMixin {
  static const _entrance = Duration(milliseconds: 320);

  late final _controller = AnimationController(
    vsync: this,
    duration: widget.delay + _entrance,
    value: widget.animate ? 0 : 1,
  );

  /// [MeetingRevealStep.delay] 동안은 그대로 있다가 펼쳐진다
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMicroseconds / (widget.delay + _entrance).inMicroseconds,
      1,
      curve: Curves.easeOut,
    ),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.animate) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _enter(reduce: MediaQuery.disableAnimationsOf(context));
    });
  }

  void _enter({required bool reduce}) {
    SemanticsService.sendAnnouncement(
      View.of(context),
      widget.announcement,
      Directionality.of(context),
    );
    if (reduce) {
      _controller.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _show(Duration.zero));
      return;
    }
    _controller.forward().whenComplete(
      () => _show(const Duration(milliseconds: 300)),
    );
  }

  /// 다 펼쳐진 질문이 화면 안에 들게 굴린다
  void _show(Duration duration) {
    if (!mounted) return;
    Scrollable.ensureVisible(
      context,
      duration: duration,
      curve: Curves.easeOut,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = _curve;
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
