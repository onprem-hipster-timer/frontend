import 'dart:math' as math;
import 'dart:ui' show Rect;

/// [outer]에서 [overlaps]를 뺀 나머지를 서로 겹치지 않는 사각형들로 돌려준다.
///
/// axe-core(MIT)의 split-rects처럼 가린 사각형의 변을 따라 자른다. 다만 조각의
/// 면적을 더해 쓰므로 좌우 조각은 가린 사각형의 세로 범위로 제한해 겹치지 않게 한다.
List<Rect> splitRects(Rect outer, Iterable<Rect> overlaps) {
  var rects = <Rect>[outer];
  for (final overlap in overlaps) {
    rects = <Rect>[for (final rect in rects) ..._splitRect(rect, overlap)];
    if (rects.length > 4000) {
      throw StateError('splitRects: 조각이 너무 많습니다 (${rects.length})');
    }
  }
  return rects;
}

List<Rect> _splitRect(Rect rect, Rect cut) {
  if (!rect.overlaps(cut)) {
    return <Rect>[rect];
  }
  final top = math.max(rect.top, cut.top);
  final bottom = math.min(rect.bottom, cut.bottom);
  return <Rect>[
    if (cut.top > rect.top)
      Rect.fromLTRB(rect.left, rect.top, rect.right, cut.top),
    if (cut.bottom < rect.bottom)
      Rect.fromLTRB(rect.left, cut.bottom, rect.right, rect.bottom),
    if (cut.left > rect.left) Rect.fromLTRB(rect.left, top, cut.left, bottom),
    if (cut.right < rect.right)
      Rect.fromLTRB(cut.right, top, rect.right, bottom),
  ];
}

/// 뒤집힌(폭·높이가 음수인) 사각형은 0.
double rectArea(Rect rect) =>
    math.max(0.0, rect.width) * math.max(0.0, rect.height);

double totalArea(Iterable<Rect> rects) =>
    rects.fold(0, (sum, rect) => sum + rectArea(rect));

Rect unionRect(Iterable<Rect> rects) =>
    rects.reduce((a, b) => a.expandToInclude(b));

/// [rects]가 [limits] 중 하나의 밖으로 가장 많이 나간 (방향, 양). 나간 것이 없으면 양은 0 이하.
(String, double) maxOvershoot(Iterable<Rect> rects, Iterable<Rect> limits) {
  var result = ('', 0.0);
  for (final limit in limits) {
    for (final rect in rects) {
      for (final side in [
        ('왼쪽', limit.left - rect.left),
        ('위쪽', limit.top - rect.top),
        ('오른쪽', rect.right - limit.right),
        ('아래쪽', rect.bottom - limit.bottom),
      ]) {
        if (side.$2 > result.$2) {
          result = side;
        }
      }
    }
  }
  return result;
}

double overlapArea(Rect a, Rect b) => rectArea(a.intersect(b));

/// [target] 면적 중 [covers]가 덮는 비율(0~1).
double coveredFraction(Rect target, Iterable<Rect> covers) {
  if (target.isEmpty) {
    return 0;
  }
  final remaining = totalArea(splitRects(target, covers));
  return (1 - remaining / rectArea(target)).clamp(0.0, 1.0);
}

Rect? largestRect(Iterable<Rect> rects) {
  Rect? largest;
  for (final rect in rects) {
    if (largest == null || rectArea(rect) > rectArea(largest)) {
      largest = rect;
    }
  }
  return largest;
}
