import 'dart:ui' show Rect;

/// 픽셀 양·좌표. 소수 첫째 자리까지.
String formatPx(double value) => value.toStringAsFixed(1);

/// 화면 크기·배율. 정수면 소수점 없이, 아니면 둘째 자리까지 쓰고 끝의 0은 뗀다.
String formatCompact(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String formatLtrb(Rect rect, {String separator = ','}) => [
      rect.left,
      rect.top,
      rect.right,
      rect.bottom,
    ].map(formatPx).join(separator);
