import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'format.dart';
import 'finding.dart';
import 'leaf_geometry.dart';
import 'rect_math.dart';
import 'source_location.dart';

class LayoutAuditOptions {
  const LayoutAuditOptions({
    this.ignore,
    this.minOverlap = 2.0,
    this.coveredWarningRatio = 0.25,
    this.maxLeaves = 2000,
    this.edgeTolerance = 2.0,
  });

  /// true를 돌려준 발견은 버린다. 묶기 전에 발견 하나하나에 불린다.
  final bool Function(LayoutFinding)? ignore;

  /// 교차 영역의 가로·세로가 모두 이 값(px)을 넘어야 겹침이다.
  final double minOverlap;

  /// 작은 쪽이 이 비율 이상 가려지면 warning, 아니면 notice.
  final double coveredWarningRatio;

  /// leaf가 이보다 많으면 검사를 건너뛴다.
  final int maxLeaves;

  /// 잘라냄·이탈로 보기 전에 허용하는 여유(px).
  final double edgeTolerance;
}

/// 현재 화면(또는 [within] 아래)의 겹침·잘라냄·이탈·말줄임을 찾는다.
///
/// [previousFrame]은 [snapshotLeafBoxes]로 직전 프레임에 찍어 둔 값이다.
List<LayoutFinding> auditLayout(
  WidgetTester tester, {
  Finder? within,
  LayoutAuditOptions options = const LayoutAuditOptions(),
  Map<RenderObject, List<Rect>>? previousFrame,
}) {
  return auditRenderTree(
    _roots(tester, within),
    viewRect: _viewRect(tester),
    hitTest: (position) => tester.hitTestOnBinding(position),
    options: options,
    previousFrame: previousFrame,
  );
}

/// leaf마다 클립 전 전역 사각형. [auditLayout]의 `previousFrame`으로 넘긴다.
Map<RenderObject, List<Rect>> snapshotLeafBoxes(
  WidgetTester tester, {
  Finder? within,
}) {
  try {
    return {
      for (final leaf in collectContentLeaves(
        _roots(tester, within),
        _viewRect(tester),
      ))
        leaf.box: leaf.rawBoxes,
    };
  } on Object {
    // 스냅샷 실패는 감사 실패로 이어지지 않게 빈 값으로 둔다.
    return const {};
  }
}

Iterable<RenderObject> _roots(WidgetTester tester, Finder? within) {
  if (within == null) {
    return tester.binding.renderViews;
  }
  // 레이아웃이 중단된 트리에서는 파인더 평가가 던질 수 있다. 그때는 전체를 본다.
  try {
    return tester.renderObjectList(within).toList();
  } on Object {
    return tester.binding.renderViews;
  }
}

Rect _viewRect(WidgetTester tester) =>
    Offset.zero & (tester.view.physicalSize / tester.view.devicePixelRatio);

/// [auditLayout]의 WidgetTester 없는 형태. 예외를 던지지 않고 info 발견으로 돌려준다.
///
/// [previousFrame]이 있으면 직전 프레임 뒤로 0.5px 넘게 움직인 문단은 `moving`으로
/// 보고하고 잘라냄·이탈·말줄임 검사에서 빼며, 움직였거나 새로 나타난 leaf가 낀
/// 발견은 지속되지 않은 것으로 보고 info로 낮춘다.
List<LayoutFinding> auditRenderTree(
  Iterable<RenderObject> roots, {
  required Rect viewRect,
  required HitTestResult Function(Offset global) hitTest,
  LayoutAuditOptions options = const LayoutAuditOptions(),
  Map<RenderObject, List<Rect>>? previousFrame,
}) {
  try {
    return _Audit(viewRect, hitTest, options, previousFrame).run(roots);
  } on Object catch (error) {
    return [LayoutFinding.auditFailed(error)];
  }
}

class _Raw {
  const _Raw(this.finding, this.leaves);

  final LayoutFinding finding;
  final List<RenderBox> leaves;
}

class _Audit {
  _Audit(this.viewRect, this.hitTest, this.options, this.previousFrame);

  final Rect viewRect;
  final HitTestResult Function(Offset global) hitTest;
  final LayoutAuditOptions options;
  final Map<RenderObject, List<Rect>>? previousFrame;

  final Set<RenderBox> _moving = {};
  final Set<RenderBox> _unsettled = {};

  List<LayoutFinding> run(Iterable<RenderObject> roots) {
    final leaves = collectContentLeaves(roots, viewRect);
    if (leaves.length > options.maxLeaves) {
      return [
        LayoutFinding.auditSkipped(
          leaves: leaves.length,
          maxLeaves: options.maxLeaves,
        ),
      ];
    }
    final raw = <_Raw>[
      ..._movement(leaves),
      ..._overlaps(leaves),
      for (final leaf in leaves)
        if (!_moving.contains(leaf.box)) ..._edges(leaf),
    ];
    final findings = [
      for (final r in raw)
        if (r.leaves.any(_unsettled.contains) &&
            r.finding.kind != LayoutFindingKind.moving)
          r.finding.copyWith(severity: LayoutSeverity.info)
        else
          r.finding,
    ];
    final ignore = options.ignore;
    return _group([
      for (final finding in findings)
        if (ignore == null || !ignore(finding)) finding,
    ]);
  }

  List<_Raw> _movement(List<ContentLeaf> leaves) {
    final previous = previousFrame;
    if (previous == null) {
      return const [];
    }
    final found = <_Raw>[];
    for (final leaf in leaves) {
      final before = previous[leaf.box];
      if (before == null || before.isEmpty) {
        _unsettled.add(leaf.box);
        continue;
      }
      if (leaf.box is! RenderParagraph) {
        continue;
      }
      final shift = _shift(unionRect(before), unionRect(leaf.rawBoxes));
      if (shift <= 0.5) {
        continue;
      }
      _moving.add(leaf.box);
      _unsettled.add(leaf.box);
      found.add(
        _Raw(
          LayoutFinding(
            kind: LayoutFindingKind.moving,
            severity: LayoutSeverity.notice,
            message:
                '[이동] ${_describe(leaf)} 프레임 사이에 ${formatPx(shift)}px 이동했습니다',
            rects: [leaf.bounds],
            locations: [sourceLocationOf(leaf.box)],
            texts: [leaf.text],
          ),
          [leaf.box],
        ),
      );
    }
    return found;
  }

  List<_Raw> _overlaps(List<ContentLeaf> leaves) {
    final sorted = [...leaves]
      ..sort((a, b) => a.bounds.left.compareTo(b.bounds.left));
    final found = <_Raw>[];
    for (var i = 0; i < sorted.length; i++) {
      final a = sorted[i];
      final boundsA = a.bounds;
      for (var j = i + 1; j < sorted.length; j++) {
        final b = sorted[j];
        final boundsB = b.bounds;
        if (boundsB.left >= boundsA.right) {
          break;
        }
        if (boundsB.top >= boundsA.bottom || boundsA.top >= boundsB.bottom) {
          continue;
        }
        // WidgetSpan 안의 leaf는 바깥 문단의 자리 표시자 위에 그려지는 것이 정상이다.
        if (a.ancestors.contains(b.box) || b.ancestors.contains(a.box)) {
          continue;
        }
        final finding = _overlap(a, b);
        if (finding != null) {
          found.add(_Raw(finding, [a.box, b.box]));
        }
      }
    }
    return found;
  }

  LayoutFinding? _overlap(ContentLeaf a, ContentLeaf b) {
    final intersections = <Rect>[
      for (final boxA in a.visibleBoxes)
        for (final boxB in b.visibleBoxes) boxA.intersect(boxB),
    ].where(
        (i) => i.width > options.minOverlap && i.height > options.minOverlap);
    final focus = largestRect(intersections);
    if (focus == null) {
      return null;
    }

    final aIsSmaller = a.visibleArea <= b.visibleArea;
    final fraction = _coveredFraction(
      aIsSmaller ? a : b,
      aIsSmaller ? b : a,
    );
    final severity = fraction >= options.coveredWarningRatio
        ? LayoutSeverity.warning
        : LayoutSeverity.notice;

    final top = _topLeaf(a, b, focus);
    final first = top ?? a;
    final second = identical(first, a) ? b : a;

    final chainFirst = [first.box, ...first.ancestors];
    final ancestorsOfSecond = {second.box, ...second.ancestors};
    final lcaIndex = chainFirst.indexWhere(ancestorsOfSecond.contains);
    final lca = lcaIndex < 0 ? null : chainFirst[lcaIndex];
    // Overlay 위 라우트(다이얼로그·시트)가 뒤 화면을 덮는 것은 설계다.
    if (lca != null && lca.runtimeType.toString() == '_RenderTheater') {
      return null;
    }
    final insideStack = lca is RenderStack;
    final coveringRoot = top != null && lcaIndex > 0
        ? sourceLocationOf(chainFirst[lcaIndex - 1])
        : null;
    final where = [
      if (coveringRoot != null) '가리는 위젯: $coveringRoot',
      if (insideStack) 'Stack 안',
    ].join(', ');
    final body = top != null
        ? '${_describe(first)}이 ${_describe(second)}을 ${(fraction * 100).round()}% 가립니다'
        : "${_describe(first)}와 ${_describe(second)}가 ${formatPx(focus.width)}x${formatPx(focus.height)} 겹칩니다 (순서 불명)";
    return LayoutFinding(
      kind: LayoutFindingKind.overlap,
      severity: severity,
      message:
          '[겹침] $body${where.isEmpty ? '' : ' ($where)'} | ∩=(${formatLtrb(focus)})',
      rects: [first.bounds, second.bounds, focus],
      locations: [sourceLocationOf(first.box), sourceLocationOf(second.box)],
      texts: [first.text, second.text],
      insideStack: insideStack,
      coveredFraction: fraction,
      coveringRoot: coveringRoot,
      zOrderKnown: top != null,
    );
  }

  double _coveredFraction(ContentLeaf smaller, ContentLeaf larger) {
    var total = 0.0;
    var covered = 0.0;
    for (final box in smaller.visibleBoxes) {
      final area = rectArea(box);
      total += area;
      try {
        covered += area * coveredFraction(box, larger.visibleBoxes);
      } on StateError {
        covered += math.min(
          area,
          larger.visibleBoxes.fold(
            0.0,
            (sum, other) => sum + overlapArea(box, other),
          ),
        );
      }
    }
    return total == 0 ? 0 : covered / total;
  }

  /// 교차 영역 몇 곳을 히트 테스트해 더 자주 맨 앞에 맞은 쪽. 같거나 아무도 안 맞으면 null.
  ContentLeaf? _topLeaf(ContentLeaf a, ContentLeaf b, Rect focus) {
    final points = [
      focus.center,
      for (final dx in const [0.25, 0.75])
        for (final dy in const [0.25, 0.75])
          Offset(focus.left + focus.width * dx, focus.top + focus.height * dy),
    ];
    var votesA = 0;
    var votesB = 0;
    for (final point in points) {
      for (final entry in hitTest(point).path) {
        if (isRenderObjectAncestorOfTarget(a.box, entry.target)) {
          votesA++;
          break;
        }
        if (isRenderObjectAncestorOfTarget(b.box, entry.target)) {
          votesB++;
          break;
        }
      }
    }
    if (votesA == votesB) {
      return null;
    }
    return votesA > votesB ? a : b;
  }

  List<_Raw> _edges(ContentLeaf leaf) {
    final box = leaf.box;
    if (box is! RenderParagraph) {
      return const [];
    }
    final found = <_Raw>[];
    void add(LayoutFindingKind kind, LayoutSeverity severity, String message) {
      found.add(
        _Raw(
          LayoutFinding(
            kind: kind,
            severity: severity,
            message: message,
            rects: [unionRect(leaf.rawBoxes)],
            locations: [sourceLocationOf(box)],
            texts: [leaf.text],
          ),
          [box],
        ),
      );
    }

    final ellipsized = box.overflow == TextOverflow.ellipsis ||
        box.overflow == TextOverflow.fade;
    if (!ellipsized) {
      final (_, clipped) = maxOvershoot(leaf.rawBoxes, [
        if (leaf.contentClipRect != null) leaf.contentClipRect!,
        // visible이면 제 상자 밖도 그려지므로 잘린 것이 아니다.
        if (box.overflow != TextOverflow.visible)
          globalRect(box, Offset.zero & box.size),
      ]);
      if (clipped > options.edgeTolerance) {
        add(
          LayoutFindingKind.clipped,
          LayoutSeverity.warning,
          '[잘라냄] ${_describe(leaf)} 글자가 상자 밖으로 ${formatPx(clipped)}px 잘려 나갑니다',
        );
      }
    }

    if (!leaf.hasClipAncestor) {
      final (side, outside) = maxOvershoot(leaf.rawBoxes, [viewRect]);
      if (outside > options.edgeTolerance) {
        add(
          LayoutFindingKind.offscreen,
          LayoutSeverity.warning,
          '[이탈] ${_describe(leaf)} 화면 $side 밖으로 ${formatPx(outside)}px 나갑니다',
        );
      }
    }

    if (ellipsized && box.didExceedMaxLines) {
      add(
        LayoutFindingKind.truncation,
        LayoutSeverity.notice,
        '[말줄임] ${_describe(leaf)} 텍스트가 말줄임 처리됐습니다 (maxLines ${box.maxLines})',
      );
    }
    return found;
  }
}

double _shift(Rect a, Rect b) => [
      (a.left - b.left).abs(),
      (a.top - b.top).abs(),
      (a.right - b.right).abs(),
      (a.bottom - b.bottom).abs(),
    ].reduce(math.max);

List<LayoutFinding> _group(List<LayoutFinding> findings) {
  final groups = <String, LayoutFinding>{};
  for (final finding in findings) {
    // 위치를 모르면 서로 다른 발견이 한데 묶이지 않도록 글자까지 키에 넣는다.
    final key = [
      finding.kind.name,
      ...finding.locations.map((l) => '$l'),
      if (finding.locations.contains(null)) ...finding.texts,
    ].join('\u0000');
    final existing = groups[key];
    if (existing == null) {
      groups[key] = finding;
      continue;
    }
    groups[key] = existing.copyWith(
      count: existing.count + finding.count,
      severity: finding.severity.index < existing.severity.index
          ? finding.severity
          : existing.severity,
    );
  }
  return groups.values.toList();
}

String _describe(ContentLeaf leaf) {
  final text = leaf.text.isEmpty
      ? '[이미지]'
      : "'${leaf.text.length > 20 ? '${leaf.text.substring(0, 20)}…' : leaf.text}'";
  return '$text(${sourceLocationOf(leaf.box) ?? '위치 불명'})';
}
