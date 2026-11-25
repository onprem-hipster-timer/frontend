import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// [TrialSpotlight]가 강조할 컨트롤을 찾는 방법
@immutable
class TrialSpotlightTarget {
  const TrialSpotlightTarget({
    required this.id,
    required this.radius,
    required this.find,
  });

  /// [T] 위젯([where]를 주면 그에 맞는 것)
  static TrialSpotlightTarget ofType<T extends Widget>({
    required Object id,
    required double radius,
    bool Function(T widget)? where,
  }) => TrialSpotlightTarget(
    id: id,
    radius: radius,
    find: (root) => _descendants(
      root,
    ).where((e) => e.widget is T && (where?.call(e.widget as T) ?? true)),
  );

  /// [label] 글자가 든 단추
  static TrialSpotlightTarget button(String label, {required double radius}) =>
      TrialSpotlightTarget(
        id: label,
        radius: radius,
        find: (root) => [
          for (final text in _descendants(root))
            if (text.widget case Text(data: final data) when data == label)
              ?_ancestor<ButtonStyleButton>(text),
        ],
      );

  /// 바뀌면 강조가 처음부터 다시 나타난다
  final Object id;

  /// 컨트롤 모서리의 둥글기. 짧은 변의 반을 넘으면 알약 모양이다
  final double radius;

  /// [root] 아래에서 강조할 컨트롤 후보. 화면 안에 있는 첫 것을 강조한다
  final Iterable<Element> Function(Element root) find;
}

List<Element> _descendants(Element root) {
  final found = <Element>[];
  void visit(Element element) {
    found.add(element);
    element.visitChildren(visit);
  }

  root.visitChildren(visit);
  return found;
}

Element? _ancestor<T extends Widget>(Element element) {
  Element? found;
  element.visitAncestorElements((ancestor) {
    if (ancestor.widget is! T) return true;
    found = ancestor;
    return false;
  });
  return found;
}

/// 다음에 누를 컨트롤([target])을 강조한다. [child] 안에서 그 컨트롤을 찾아, 모양을 따라 주색 테두리를 두르고
/// 그 바깥으로 옅은 테두리가 몇 픽셀 퍼지며 사라지기를 [pulse]마다 되풀이한다. 내용이 자리 잡은 뒤([settle])
/// 나타나고, 애니메이션을 줄였으면 바로 나타나 움직이지 않는다.
///
/// 테두리는 [child] 위 층에 그려 배치를 바꾸지 않고 누르기를 가로채지 않는다. 그려지는 프레임마다 자리를 다시
/// 찾아 컨트롤이 움직이거나 늦게 그려져도 따라간다.
/// [target]이 없거나 찾지 못하면 그리지 않는다.
///
/// 테스트: test/features/trial/presentation/widgets/trial_spotlight_test.dart
class TrialSpotlight extends StatefulWidget {
  const TrialSpotlight({super.key, required this.target, required this.child});

  /// 그린 테두리 자리(컨트롤과 같은 자리)
  static const ringKey = ValueKey('trial-spotlight-ring');

  static const pulse = Duration(seconds: 2);
  static const settle = Duration(milliseconds: 450);

  final TrialSpotlightTarget? target;
  final Widget child;

  @override
  State<TrialSpotlight> createState() => _TrialSpotlightState();
}

class _TrialSpotlightState extends State<TrialSpotlight>
    with TickerProviderStateMixin {
  final _childKey = GlobalKey();
  late final _pulse = AnimationController(
    vsync: this,
    duration: TrialSpotlight.pulse,
  );
  late final _fade = AnimationController(
    vsync: this,
    duration: Durations.medium2,
  );
  Timer? _delay;
  Rect? _rect;
  bool? _still;

  /// 다음 프레임 뒤에 자리를 다시 찾기로 했다
  var _following = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still != _still) {
      _still = still;
      _restart();
    }
  }

  @override
  void didUpdateWidget(TrialSpotlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target?.id != widget.target?.id) _restart();
  }

  void _restart() {
    _delay?.cancel();
    _pulse.stop();
    _pulse.value = 0;
    if (widget.target == null) {
      _fade.value = 0;
    } else if (_still ?? false) {
      _fade.value = 1;
    } else {
      _fade.value = 0;
      _delay = Timer(TrialSpotlight.settle, () {
        _fade.forward();
        _pulse.repeat();
      });
    }
  }

  /// 강조할 것이 있는 동안 그려지는 프레임마다 자리를 다시 찾는다. 프레임을 새로 부르지는 않는다
  void _follow() {
    if (_following) return;
    _following = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _following = false;
      if (!mounted) return;
      _locate();
      if (widget.target != null) _follow();
    });
  }

  /// 강조할 컨트롤의 자리를 다시 찾는다
  void _locate() {
    final root = _childKey.currentContext as Element?;
    final stack = context.findRenderObject();
    final target = widget.target;
    Rect? rect;
    if (target != null && root != null && stack is RenderBox && stack.hasSize) {
      final bounds = Offset.zero & stack.size;
      for (final element in target.find(root)) {
        final box = element.renderObject;
        if (box is! RenderBox || !box.attached || !box.hasSize) continue;
        final found = MatrixUtils.transformRect(
          box.getTransformTo(stack),
          Offset.zero & box.size,
        );
        // 넘겨 볼 수 있게 미리 그려 둔 화면 밖 것은 건너뛴다
        if (bounds.contains(found.center)) {
          rect = found;
          break;
        }
      }
    }
    if (rect != _rect) setState(() => _rect = rect);
  }

  @override
  void dispose() {
    _delay?.cancel();
    _pulse.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _follow();
    final rect = _rect;
    final target = widget.target;
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        KeyedSubtree(key: _childKey, child: widget.child),
        if (rect != null && target != null)
          Positioned.fromRect(
            rect: rect,
            child: IgnorePointer(
              child: FadeTransition(
                opacity: _fade,
                child: CustomPaint(
                  key: TrialSpotlight.ringKey,
                  painter: _RingPainter(
                    pulse: _pulse,
                    color: Theme.of(context).colorScheme.primary,
                    radius: target.radius,
                    moving: !(_still ?? false),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 컨트롤 모양을 따라 두른 테두리와 그 바깥으로 퍼지며 사라지는 옅은 테두리
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.pulse,
    required this.color,
    required this.radius,
    required this.moving,
  }) : super(repaint: pulse);

  final Animation<double> pulse;
  final Color color;
  final double radius;
  final bool moving;

  /// 컨트롤과 테두리 사이
  static const _gap = 3.0;

  /// 옅은 테두리가 퍼지는 거리
  static const _spread = 6.0;

  RRect _around(Size size, double outset) {
    final rect = (Offset.zero & size).inflate(outset);
    return RRect.fromRectAndRadius(
      rect,
      Radius.circular(math.min(radius + outset, rect.shortestSide / 2)),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(_around(size, _gap), stroke..color = color);
    if (!moving || pulse.value == 0) return;
    final t = Curves.easeOut.transform(pulse.value);
    canvas.drawRRect(
      _around(size, _gap + _spread * t),
      stroke..color = color.withValues(alpha: 0.5 * (1 - t)),
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.moving != moving;
}
