import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 시간별 격자 위아래의 '받지 않는 시간' 띠([text], 예: '0:00–6:00 · 받지 않는 시간'). 모든 날짜 열에 걸친 한
/// 덩어리를 칸 테두리 없이 옅은 바탕과 점무늬로 그려 내 '불가능' 빗금과 다르게 보인다. 칸이 아니라서 누르거나
/// 칠할 수 없고, 스크린 리더는 [text] 하나만 읽는다
class MeetingHourlyBand extends StatelessWidget {
  const MeetingHourlyBand({
    super.key,
    required this.text,
    required this.height,
  });

  final String text;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return IgnorePointer(
      child: Semantics(
        container: true,
        label: text,
        child: ExcludeSemantics(
          child: CustomPaint(
            painter: _BandPainter(
              fill: scheme.surfaceContainerHigh,
              dot: scheme.onSurfaceVariant.withValues(alpha: 0.22),
            ),
            child: SizedBox(
              height: height,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  // 한 줄로 두고, 띠보다 넓은 글꼴이면 띠에 맞춰 줄인다
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      text,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 둥근 사각형 바탕과 그 위의 성긴 점무늬
class _BandPainter extends CustomPainter {
  const _BandPainter({required this.fill, required this.dot});

  final Color fill;
  final Color dot;

  static const _spacing = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadius.sm),
    );
    canvas
      ..save()
      ..clipRRect(shape)
      ..drawRect(Offset.zero & size, Paint()..color = fill);
    final paint = Paint()..color = dot;
    for (var y = _spacing / 2; y < size.height; y += _spacing) {
      // 줄마다 반 칸씩 엇갈린다
      final shift = (y ~/ _spacing).isOdd ? _spacing / 2 : 0;
      for (var x = _spacing / 2 + shift; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BandPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.dot != dot;
}
