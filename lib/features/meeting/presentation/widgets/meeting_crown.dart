import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 모임 주인 표시 왕관
class MeetingCrown extends StatelessWidget {
  const MeetingCrown({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CrownPainter(AppColors.of(context).owner),
    );
  }
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = color;
    final crown = Path()
      ..moveTo(w * 0.08, h * 0.74)
      ..lineTo(w * 0.08, h * 0.28)
      ..lineTo(w * 0.32, h * 0.50)
      ..lineTo(w * 0.50, h * 0.16)
      ..lineTo(w * 0.68, h * 0.50)
      ..lineTo(w * 0.92, h * 0.28)
      ..lineTo(w * 0.92, h * 0.74)
      ..close();
    canvas
      ..drawPath(crown, paint)
      ..drawRect(Rect.fromLTWH(w * 0.08, h * 0.80, w * 0.84, h * 0.10), paint);
  }

  @override
  bool shouldRepaint(_CrownPainter old) => old.color != color;
}
