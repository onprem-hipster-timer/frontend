import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:qr/qr.dart';

/// [data]를 담은 QR 코드(오류 정정 M). [size] 크기이고, 자리가 좁으면 그 폭에 맞춰 줄인다.
///
/// 스캐너가 읽을 수 있게 앱 테마와 상관없이 흰 바탕에 검은 칸이고, 둘레에 규격의 여백 4칸을 둔다.
class MeetingQrCode extends StatelessWidget {
  const MeetingQrCode({super.key, required this.data, this.size = 200});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = QrImage(
      QrCode(
        payload: QrPayload.fromString(data),
        errorCorrectLevel: QrErrorCorrectLevel.medium,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) => Semantics(
        label: '모임 링크 QR 코드',
        image: true,
        child: SizedBox.square(
          dimension: math.min(size, constraints.maxWidth),
          child: CustomPaint(painter: MeetingQrPainter(image)),
        ),
      ),
    );
  }
}

/// QR 칸을 그린다. 흰 바탕 위에 여백 [quietModules]칸을 두고 어두운 칸을 검게 칠한다
class MeetingQrPainter extends CustomPainter {
  MeetingQrPainter(this.image);

  /// QR 규격의 여백(quiet zone) 칸 수
  static const quietModules = 4;

  final QrImage image;

  @override
  void paint(Canvas canvas, Size size) {
    final count = image.moduleCount;
    final module = size.shortestSide / (count + quietModules * 2);
    // 칸 사이에 틈이 보이지 않게 가장자리를 흐리지 않는다
    final dark = Paint()
      ..color = Colors.black
      ..isAntiAlias = false;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    for (var row = 0; row < count; row++) {
      for (var col = 0; col < count; col++) {
        if (!image.isDark(row, col)) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            (col + quietModules) * module,
            (row + quietModules) * module,
            module,
            module,
          ),
          dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(MeetingQrPainter oldDelegate) =>
      oldDelegate.image != image;
}
