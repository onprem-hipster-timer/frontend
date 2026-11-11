import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/src/format.dart';

void main() {
  test('formatPx는 소수 첫째 자리까지 쓴다', () {
    expect(formatPx(2), '2.0');
    expect(formatPx(140.04), '140.0');
    expect(formatPx(-3.25), '-3.3');
  });

  test('formatCompact는 정수면 소수점 없이, 아니면 둘째 자리까지 끝의 0을 떼고 쓴다', () {
    expect(formatCompact(3), '3');
    expect(formatCompact(2.625), '2.63');
    expect(formatCompact(1.3), '1.3');
    expect(formatCompact(1.30000001), '1.3');
  });

  test('formatLtrb는 네 변을 순서대로 쓴다', () {
    const rect = Rect.fromLTRB(1, 2.25, 30, 40);
    expect(formatLtrb(rect), '1.0,2.3,30.0,40.0');
    expect(formatLtrb(rect, separator: ', '), '1.0, 2.3, 30.0, 40.0');
  });
}
