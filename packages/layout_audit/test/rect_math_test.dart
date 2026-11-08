import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';

double _totalArea(List<Rect> rects) =>
    rects.fold(0, (sum, rect) => sum + rect.width * rect.height);

void main() {
  test('splitRects가 가린 사각형을 빼고 남은 영역을 돌려준다', () {
    const outer = Rect.fromLTRB(0, 0, 100, 100);

    final partial = splitRects(outer, const [Rect.fromLTRB(50, 50, 150, 150)]);
    expect(_totalArea(partial), 7500);
    for (final rect in partial) {
      expect(overlapArea(rect, const Rect.fromLTRB(50, 50, 150, 150)), 0);
      for (final other in partial) {
        if (!identical(rect, other)) {
          expect(overlapArea(rect, other), 0);
        }
      }
    }

    final middle = splitRects(outer, const [Rect.fromLTRB(25, 25, 75, 75)]);
    expect(middle, hasLength(4));
    expect(_totalArea(middle), 7500);

    expect(
        splitRects(outer, const [Rect.fromLTRB(-10, -10, 110, 110)]), isEmpty);
    expect(splitRects(outer, const [Rect.fromLTRB(100, 0, 200, 100)]), [outer]);
    expect(splitRects(outer, const []), [outer]);
  });

  test('겹친 가림 사각형 여러 개도 면적을 한 번만 뺀다', () {
    const outer = Rect.fromLTRB(0, 0, 100, 100);
    final rest = splitRects(outer, const [
      Rect.fromLTRB(0, 0, 60, 100),
      Rect.fromLTRB(40, 0, 100, 50),
    ]);
    expect(_totalArea(rest), 40 * 50);
  });

  test('가린 비율은 대상 면적 기준이다', () {
    const target = Rect.fromLTRB(0, 0, 100, 20);
    expect(
        coveredFraction(target, const [Rect.fromLTRB(50, -10, 300, 300)]), 0.5);
    expect(
        coveredFraction(target, const [Rect.fromLTRB(-1, -1, 101, 21)]), 1.0);
    expect(coveredFraction(target, const [Rect.fromLTRB(200, 0, 300, 20)]), 0);
    expect(coveredFraction(Rect.zero, const [Rect.fromLTRB(0, 0, 10, 10)]), 0);
  });

  test('largestRect는 면적이 가장 큰 사각형을, 비면 null을 돌려준다', () {
    expect(largestRect(const []), isNull);
    expect(
      largestRect(const [
        Rect.fromLTRB(0, 0, 10, 10),
        Rect.fromLTRB(0, 0, 30, 5),
        Rect.fromLTRB(0, 0, 5, 5),
      ]),
      const Rect.fromLTRB(0, 0, 30, 5),
    );
  });
}
