import 'package:material_ui/material_ui.dart';

/// [background] 위에서 읽히는 글자색
Color _contrastOn(Color background) =>
    background.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

/// 일정 색 [color]의 블록 위 글자색. 공유받은 일정은 옅은 바탕이라 화면 글자색을 쓴다
Color scheduleBlockTextColor(BuildContext context, Color color, bool shared) =>
    shared ? Theme.of(context).colorScheme.onSurface : _contrastOn(color);

/// 일정 색 [color]의 블록 바탕. 내 일정은 [alpha]만큼 칠하고, 공유받은 일정은 옅게 칠하고 테두리를 둔다
BoxDecoration scheduleBlockDecoration(
  BuildContext context,
  Color color, {
  required double alpha,
  required bool shared,
  required BorderRadius radius,
}) => shared
    ? BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.15),
          Theme.of(context).colorScheme.surface,
        ),
        borderRadius: radius,
        border: Border.all(color: color, width: 1.5),
      )
    : BoxDecoration(
        color: color.withValues(alpha: alpha),
        borderRadius: radius,
      );
