import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// [count]가 바뀔 때마다 [child]를 옆으로 짧게 떤다. 화면이 값을 저절로 바꿨을 때 그 자리를 알린다.
///
/// 기기에서 애니메이션을 줄였으면 떨지 않는다.
class MeetingShake extends StatefulWidget {
  const MeetingShake({super.key, required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  State<MeetingShake> createState() => _MeetingShakeState();
}

class _MeetingShakeState extends State<MeetingShake>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(MeetingShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count &&
        !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final dx = math.sin(t * math.pi * 6) * 8 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
