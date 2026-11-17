import 'package:material_ui/material_ui.dart';

/// 나타나고 사라질 때 크기와 투명도가 함께 바뀌는 자리. [child]가 있으면 펼쳐지며 나타나고([Durations.medium1],
/// [Easing.emphasizedDecelerate]), null이 되면 마지막 모습 그대로 접히며 사라진다([Durations.short3],
/// [Easing.emphasizedAccelerate]. 그동안 누를 수 없고 스크린 리더도 읽지 않는다). 처음 그릴 때는 움직이지 않고,
/// 애니메이션을 줄였으면 바로 바뀐다
class MeetingPresence extends StatefulWidget {
  const MeetingPresence({
    super.key,
    required this.child,
    this.axis = Axis.vertical,
  });

  /// 보일 것. null이면 사라진다
  final Widget? child;

  /// 접히는 방향
  final Axis axis;

  @override
  State<MeetingPresence> createState() => _MeetingPresenceState();
}

class _MeetingPresenceState extends State<MeetingPresence>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: Durations.medium1,
    reverseDuration: Durations.short3,
    value: widget.child == null ? 0 : 1,
  )..addStatusListener(_statusChanged);

  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Easing.emphasizedDecelerate,
    // 사라질 때는 천천히 시작해 빨라진다
    reverseCurve: Easing.emphasizedAccelerate.flipped,
  );

  /// 사라지는 동안 그리는 마지막 모습
  late Widget? _last = widget.child;

  void _statusChanged(AnimationStatus status) {
    if (status.isDismissed && mounted) setState(() => _last = null);
  }

  @override
  void didUpdateWidget(MeetingPresence oldWidget) {
    super.didUpdateWidget(oldWidget);
    final child = widget.child;
    if (child != null) _last = child;
    final shown = child != null;
    if (shown == (oldWidget.child != null)) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = shown ? 1 : 0;
    } else if (shown) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _last;
    if (last == null) return const SizedBox.shrink();
    final leaving = widget.child == null;
    return IgnorePointer(
      ignoring: leaving,
      child: ExcludeSemantics(
        excluding: leaving,
        child: SizeTransition(
          sizeFactor: _curve,
          axis: widget.axis,
          alignment: AlignmentDirectional.topStart,
          child: FadeTransition(opacity: _curve, child: last),
        ),
      ),
    );
  }
}
