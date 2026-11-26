import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// 한 줄 높이만 차지하는 글자 링크. 흐린 글자색에 밑줄을 긋고, 누르는 자리는 배치를 키우지 않고 사방으로 [hitSlop]만큼
/// 넓힌다. 넓힌 자리가 이웃 버튼과 겹치지 않게 위아래에 [hitSlop] 이상 띄워 둔다. 키보드로 고르면 둥근 강조로 보인다
class AppTextLink extends StatelessWidget {
  const AppTextLink({super.key, required this.label, required this.onPressed});

  /// 누르는 자리를 글자 밖으로 넓히는 거리
  static const hitSlop = 8.0;

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return _HitSlop(
      slop: hitSlop,
      child: Semantics(
        link: true,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? theme.colorScheme.onSurface.withAlpha(31)
                : Colors.transparent,
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              decoration: TextDecoration.underline,
              decorationColor: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// [child]의 크기는 그대로 두고, 바깥 [slop] 안의 누르기도 [child]로 보낸다
class _HitSlop extends SingleChildRenderObjectWidget {
  const _HitSlop({required this.slop, required super.child});

  final double slop;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHitSlop(slop);

  @override
  void updateRenderObject(BuildContext context, _RenderHitSlop renderObject) {
    renderObject.slop = slop;
  }
}

class _RenderHitSlop extends RenderProxyBox {
  _RenderHitSlop(this.slop);

  double slop;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!(Offset.zero & size).inflate(slop).contains(position)) return false;
    // 넓힌 자리의 누르기는 가장 가까운 글자 자리로 옮겨 [child]가 받게 한다
    final inside = Offset(
      position.dx.clamp(0, size.width - precisionErrorTolerance),
      position.dy.clamp(0, size.height - precisionErrorTolerance),
    );
    return hitTestChildren(result, position: inside);
  }
}
