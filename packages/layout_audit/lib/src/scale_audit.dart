import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'audit_support.dart';
import 'finding.dart';
import 'format.dart';
import 'leaf_geometry.dart';
import 'rect_math.dart';
import 'source_location.dart';

/// `--dart-define=LAYOUT_AUDIT_SCALE_STRICT=true`면 배율 비교 보고서의 warning이 테스트를 실패시킨다.
///
/// 기존 점검의 `LAYOUT_AUDIT_STRICT`와 따로 켠다.
const bool layoutAuditScaleStrict = bool.fromEnvironment(
  'LAYOUT_AUDIT_SCALE_STRICT',
);

/// 배율 비교가 내는 발견 종류.
const scaleFindingKinds = {
  LayoutFindingKind.scaleTruncation,
  LayoutFindingKind.scaleVanished,
  LayoutFindingKind.scaleUnreachable,
  LayoutFindingKind.scaleInversion,
};

/// 점검 이름 [name]의 배율 비교 보고서 이름.
String scaleReportName(String name) => '${name}_scale';

class ScaleAuditOptions {
  const ScaleAuditOptions({
    this.enabled = true,
    this.baseScale = 1.0,
    this.userTexts = const [],
    this.groupHeightFraction = 1 / 3,
    this.inversionRatio = 1.1,
    this.edgeTolerance = 2.0,
    this.ignore,
  });

  final bool enabled;

  /// 같은 화면 크기에서 이 배율로 점검한 화면을 기준으로 더 큰 배율을 비교한다.
  final double baseScale;

  /// 사용자가 넣는 글자. 길이를 앱이 정할 수 없으므로 이 글자를 품은 문단은 말줄임을 보지 않는다.
  final List<String> userTexts;

  /// 두 글자를 품은 가장 가까운 공통 조상의 높이가 화면 높이의 이 비율 이하일 때 한 묶음(카드·행)으로 보고
  /// 크기를 비교한다.
  final double groupHeightFraction;

  /// 한쪽 글자 크기가 다른 쪽의 이 배 이상일 때만 크기 차이로 본다.
  final double inversionRatio;

  /// 잘림으로 보기 전에 허용하는 여유(px).
  final double edgeTolerance;

  /// true를 돌려준 발견은 버린다.
  final bool Function(LayoutFinding)? ignore;

  ScaleAuditOptions withUserTexts(List<String> texts) => ScaleAuditOptions(
        enabled: enabled,
        baseScale: baseScale,
        userTexts: [...userTexts, ...texts],
        groupHeightFraction: groupHeightFraction,
        inversionRatio: inversionRatio,
        edgeTolerance: edgeTolerance,
        ignore: ignore,
      );
}

/// 한 배율에서 본 화면. 배율이 다른 두 장면을 [compareScaleSnapshots]로 비교한다.
class ScaleSnapshot {
  const ScaleSnapshot({
    required this.texts,
    required this.targets,
    required this.groups,
  });

  /// 읽는 순서(위→아래, 왼→오른)로 둔 문단.
  final List<ScaleText> texts;

  /// 누를 수 있는 것.
  final List<ScaleTarget> targets;

  /// 한 묶음 안에 있는 두 문단의 [ScaleText.key] 쌍. 작은 키가 앞이다.
  final Set<(String, String)> groups;
}

class ScaleText {
  const ScaleText({
    required this.key,
    required this.text,
    required this.location,
    required this.rect,
    required this.fontSize,
    required this.visible,
    required this.shownWhole,
    required this.scroll,
    required this.moving,
  });

  /// 소스 위치·글자·같은 것 중 몇 번째인지로 만든, 배율이 달라도 같은 문단을 가리키는 키.
  final String key;
  final String text;
  final SourceLocation? location;
  final Rect rect;

  /// 화면에 그려지는 글자 크기(논리 px). 글자 배율과 FittedBox 같은 축소가 반영된다.
  final double fontSize;
  final bool visible;

  /// 말줄임되지 않았고 상자 밖으로 잘리지도 않았다.
  final bool shownWhole;

  /// 품고 있는 가장 가까운 스크롤 영역의 소스 위치. 스크롤 밖이면 null.
  final String? scroll;

  bool get inScroll => scroll != null;

  /// 직전 프레임 뒤로 움직였다(흐르는 글자).
  final bool moving;
}

class ScaleTarget {
  const ScaleTarget({
    required this.key,
    required this.label,
    required this.rect,
    required this.reachable,
    required this.inScroll,
  });

  final String key;
  final String label;
  final Rect rect;

  /// 화면 안에 보여 바로 누를 수 있다.
  final bool reachable;
  final bool inScroll;
}

/// 지금 화면을 [ScaleSnapshot]으로 찍는다. 버튼을 모으려면 시맨틱스가 켜져 있어야 한다.
ScaleSnapshot captureScaleSnapshot(
  WidgetTester tester, {
  Finder? within,
  Map<RenderObject, List<Rect>>? previousFrame,
  ScaleAuditOptions options = const ScaleAuditOptions(),
}) {
  final view = auditViewRect(tester);
  final leaves = [
    for (final leaf in collectContentLeaves(auditRoots(tester, within), view))
      if (leaf.box is RenderParagraph && !_isIcon(leaf.text)) leaf,
  ]..sort(_readingOrder);
  final texts = _keyed(
    leaves,
    (leaf) => '${sourceLocationOf(leaf.box)}\u0000${leaf.text}',
    (leaf, key) => _textOf(leaf, key, previousFrame, options),
  );
  return ScaleSnapshot(
    texts: texts,
    targets: _targets(tester, view),
    groups: _groups(leaves, texts, view, options),
  );
}

/// 같은 화면 크기의 [base]보다 큰 배율인 [scaled]에서 배율 탓에 생긴 잘림·사라짐·밀려남·위계 역전을 찾는다.
List<LayoutFinding> compareScaleSnapshots(
  ScaleSnapshot base,
  ScaleSnapshot scaled, {
  ScaleAuditOptions options = const ScaleAuditOptions(),
}) {
  final findings = [
    ..._truncations(base, scaled, options),
    ..._vanished(base, scaled, options),
    ..._unreachable(base, scaled),
    ..._inversions(base, scaled, options),
  ];
  final ignore = options.ignore;
  return [
    for (final finding in findings)
      if (ignore == null || !ignore(finding)) finding,
  ];
}

final _baselines = <String, ScaleSnapshot>{};

/// [baselineKey]로 기준 배율 장면을 기억해 두고, 더 큰 배율이면 기억한 장면과 비교한다.
///
/// 기준 장면이 아직 없으면(기준 배율을 점검하지 않았으면) null.
List<LayoutFinding>? recordScaleCase(
  String baselineKey,
  double textScale,
  ScaleSnapshot snapshot,
  ScaleAuditOptions options,
) {
  if (textScale == options.baseScale) {
    _baselines[baselineKey] = snapshot;
    return null;
  }
  final base = _baselines[baselineKey];
  if (base == null || textScale < options.baseScale) {
    return null;
  }
  return compareScaleSnapshots(base, snapshot, options: options);
}

/// 아이콘 글꼴의 글리프(사용자 정의 영역)만으로 된 문단. 아이콘은 글자 배율을 따르지 않는다.
bool _isIcon(String text) =>
    text.isNotEmpty &&
    text.runes.every(
      (r) => (r >= 0xE000 && r <= 0xF8FF) || r >= 0xF0000,
    );

int _readingOrder(ContentLeaf a, ContentLeaf b) {
  final ra = unionRect(a.rawBoxes);
  final rb = unionRect(b.rawBoxes);
  final byTop = ra.top.compareTo(rb.top);
  return byTop != 0 ? byTop : ra.left.compareTo(rb.left);
}

/// [identity]가 같은 것끼리 순서대로 번호를 붙여 키를 만든다.
List<R> _keyed<T, R>(
  List<T> items,
  String Function(T) identity,
  R Function(T, String key) make,
) {
  final seen = <String, int>{};
  return [
    for (final item in items)
      () {
        final id = identity(item);
        final n = seen[id] = (seen[id] ?? -1) + 1;
        return make(item, '$id#$n');
      }(),
  ];
}

ScaleText _textOf(
  ContentLeaf leaf,
  String key,
  Map<RenderObject, List<Rect>>? previousFrame,
  ScaleAuditOptions options,
) {
  final paragraph = leaf.box as RenderParagraph;
  final rect = unionRect(leaf.rawBoxes);
  final before = previousFrame?[leaf.box];
  final moving = before != null &&
      before.isNotEmpty &&
      _shift(unionRect(before), rect) > 0.5;
  final (_, clipped) = maxOvershoot(leaf.rawBoxes, [
    if (leaf.contentClipRect != null) leaf.contentClipRect!,
    if (paragraph.overflow != TextOverflow.visible)
      globalRect(paragraph, Offset.zero & paragraph.size),
  ]);
  return ScaleText(
    key: key,
    text: leaf.text,
    location: sourceLocationOf(leaf.box),
    rect: rect,
    fontSize: _fontSize(paragraph),
    visible: leaf.isVisible,
    shownWhole:
        !paragraph.didExceedMaxLines && clipped <= options.edgeTolerance,
    scroll: switch (leaf.ancestors.whereType<RenderAbstractViewport>()) {
      final viewports when viewports.isNotEmpty =>
        '${sourceLocationOf(viewports.first as RenderObject)}',
      _ => null,
    },
    moving: moving,
  );
}

double _shift(Rect a, Rect b) => [
      (a.left - b.left).abs(),
      (a.top - b.top).abs(),
      (a.right - b.right).abs(),
      (a.bottom - b.bottom).abs(),
    ].reduce(math.max);

double _fontSize(RenderParagraph paragraph) {
  var size = 0.0;
  paragraph.text.visitChildren((span) {
    size = math.max(size, span.style?.fontSize ?? 0);
    return true;
  });
  // 크기를 적지 않은 문단은 Flutter 기본 글자 크기다.
  if (size == 0) size = 14;
  // getMaxScaleOnAxis는 늘 1인 z축까지 보므로 세로 1px이 화면에서 몇 px인지로 잰다.
  final transform = MatrixUtils.transformRect(
    paragraph.getTransformTo(null),
    const Rect.fromLTWH(0, 0, 1, 1),
  ).height;
  return paragraph.textScaler.scale(size) * transform;
}

Set<(String, String)> _groups(
  List<ContentLeaf> leaves,
  List<ScaleText> texts,
  Rect view,
  ScaleAuditOptions options,
) {
  final limit = view.height * options.groupHeightFraction;
  final chains = [
    for (final leaf in leaves)
      {for (final (i, a) in leaf.ancestors.indexed) a: i},
  ];
  final groups = <(String, String)>{};
  for (var i = 0; i < leaves.length; i++) {
    if (!texts[i].visible) continue;
    for (var j = i + 1; j < leaves.length; j++) {
      if (!texts[j].visible) continue;
      final lca = leaves[j].ancestors.firstWhere(
            chains[i].containsKey,
            orElse: () => leaves[j].box,
          );
      if (lca is! RenderBox || !lca.hasSize) continue;
      if (globalRect(lca, Offset.zero & lca.size).height > limit) continue;
      final (a, b) = (texts[i].key, texts[j].key);
      groups.add(a.compareTo(b) <= 0 ? (a, b) : (b, a));
    }
  }
  return groups;
}

List<ScaleTarget> _targets(WidgetTester tester, Rect view) {
  final roots = [
    for (final renderView in tester.binding.renderViews)
      if (renderView.owner?.semanticsOwner?.rootSemanticsNode case final root?)
        root,
  ];
  final found = <(SemanticsNode, Rect, bool)>[];
  for (final root in roots) {
    // 뿌리 노드는 물리 픽셀이다. 논리 픽셀로 되돌린다.
    final ratio = root.rect.width == 0 ? 1.0 : root.rect.width / view.width;
    void visit(SemanticsNode node, bool inScroll) {
      final data = node.getSemanticsData();
      final scroll = inScroll ||
          node.flagsCollection.hasImplicitScrolling ||
          data.hasAction(SemanticsAction.scrollUp) ||
          data.hasAction(SemanticsAction.scrollDown) ||
          data.hasAction(SemanticsAction.scrollLeft) ||
          data.hasAction(SemanticsAction.scrollRight);
      // 눌러서 닫는 영역(시트·다이얼로그 뒤 장벽)은 버튼이 아니다.
      if (!node.isMergedIntoParent &&
          data.hasAction(SemanticsAction.tap) &&
          !data.hasAction(SemanticsAction.dismiss)) {
        final rect = _semanticsRect(node);
        found.add((
          node,
          Rect.fromLTRB(
            rect.left / ratio,
            rect.top / ratio,
            rect.right / ratio,
            rect.bottom / ratio,
          ),
          scroll,
        ));
      }
      node.visitChildren((child) {
        visit(child, scroll);
        return true;
      });
    }

    visit(root, false);
  }
  found.sort((a, b) {
    final byTop = a.$2.top.compareTo(b.$2.top);
    return byTop != 0 ? byTop : a.$2.left.compareTo(b.$2.left);
  });
  return _keyed(
    found,
    (t) => _labelOf(t.$1),
    (t, key) {
      final (node, rect, inScroll) = t;
      final shown = rect.intersect(view);
      return ScaleTarget(
        key: key,
        label: _labelOf(node),
        rect: rect,
        reachable: !node.flagsCollection.isHidden &&
            shown.width > 1 &&
            shown.height > 1,
        inScroll: inScroll,
      );
    },
  );
}

String _labelOf(SemanticsNode node) {
  final data = node.getSemanticsData();
  return data.label.isNotEmpty ? data.label : data.tooltip;
}

Rect _semanticsRect(SemanticsNode node) {
  var rect = node.rect;
  for (SemanticsNode? n = node; n != null; n = n.parent) {
    final transform = n.transform;
    if (transform != null) rect = MatrixUtils.transformRect(transform, rect);
  }
  return rect;
}

String _describe(ScaleText text) {
  final shown =
      text.text.length > 20 ? '${text.text.substring(0, 20)}…' : text.text;
  return "'$shown'(${text.location ?? '위치 불명'})";
}

bool _isUserText(ScaleText text, ScaleAuditOptions options) =>
    options.userTexts.any((u) => u.isNotEmpty && text.text.contains(u));

LayoutFinding _finding(
  LayoutFindingKind kind,
  String message,
  List<ScaleText> texts, {
  LayoutSeverity severity = LayoutSeverity.warning,
}) =>
    LayoutFinding(
      kind: kind,
      severity: severity,
      message: message,
      rects: [for (final t in texts) t.rect],
      locations: [for (final t in texts) t.location],
      texts: [for (final t in texts) t.text],
    );

Iterable<LayoutFinding> _truncations(
  ScaleSnapshot base,
  ScaleSnapshot scaled,
  ScaleAuditOptions options,
) sync* {
  final before = {for (final t in base.texts) t.key: t};
  for (final after in scaled.texts) {
    final was = before[after.key];
    if (was == null ||
        !was.visible ||
        !was.shownWhole ||
        was.moving ||
        !after.visible ||
        after.shownWhole ||
        after.moving ||
        _isUserText(after, options)) {
      continue;
    }
    yield _finding(
      LayoutFindingKind.scaleTruncation,
      '[배율 말줄임] ${_describe(after)} 기준 배율에서는 다 보였는데 큰 배율에서 잘립니다',
      [after],
    );
  }
}

Iterable<LayoutFinding> _vanished(
  ScaleSnapshot base,
  ScaleSnapshot scaled,
  ScaleAuditOptions options,
) sync* {
  final after = {for (final t in scaled.texts) t.key};
  final baseKeys = {for (final t in base.texts) t.key};
  // 다른 위젯이 같은 글자를 그리거나(흐르는 글자 등) 같은 자리에서 글자만 바뀐 문단은 사라진 것이 아니다.
  // 새로 생긴 문단 수만큼 글자별·자리별로 상쇄한다.
  final addedTexts = <String, int>{};
  final addedSpots = <String, int>{};
  for (final t in scaled.texts) {
    if (!baseKeys.contains(t.key)) {
      addedTexts.update(t.text, (n) => n + 1, ifAbsent: () => 1);
      addedSpots.update('${t.location}', (n) => n + 1, ifAbsent: () => 1);
    }
  }
  bool consume(Map<String, int> added, String id) {
    final n = added[id] ?? 0;
    if (n == 0) return false;
    added[id] = n - 1;
    return true;
  }

  // 같은 글자가 아직 보이면 사본 하나가 접힌 것(+N 등)이라 정보는 남아 있다.
  final shown = {
    for (final t in scaled.texts)
      if (t.visible) t.text,
  };
  for (final (i, was) in base.texts.indexed) {
    if (!was.visible ||
        was.moving ||
        after.contains(was.key) ||
        shown.contains(was.text)) {
      continue;
    }
    if (consume(addedTexts, was.text) ||
        consume(addedSpots, '${was.location}')) {
      continue;
    }
    // 스크롤 목록은 화면 아래 항목을 만들지 않는다. 같은 목록의 뒤 문단이 남아 있을 때만 사라진 것으로 본다.
    if (was.inScroll &&
        !base.texts.skip(i + 1).any(
              (later) =>
                  later.scroll == was.scroll && after.contains(later.key),
            )) {
      continue;
    }
    yield _finding(
      LayoutFindingKind.scaleVanished,
      '[배율 사라짐] ${_describe(was)} 기준 배율에서는 보였는데 큰 배율에서 사라집니다',
      [was],
    );
  }
}

Iterable<LayoutFinding> _unreachable(
  ScaleSnapshot base,
  ScaleSnapshot scaled,
) sync* {
  final after = {for (final t in scaled.targets) t.key: t};
  for (final was in base.targets) {
    if (!was.reachable) continue;
    final now = after[was.key];
    if (now != null && now.reachable) continue;
    // 완전히 잘려 나간 버튼은 시맨틱스 트리에서 빠진다.
    final inScroll = now?.inScroll ?? was.inScroll;
    final name = was.label.isEmpty ? '이름 없는 버튼' : "'${was.label}'";
    yield LayoutFinding(
      kind: LayoutFindingKind.scaleUnreachable,
      severity: inScroll ? LayoutSeverity.notice : LayoutSeverity.warning,
      message: inScroll
          ? '[배율 밀려남] $name 버튼이 큰 배율에서 화면 밖으로 밀려 스크롤해야 닿습니다'
          : '[배율 밀려남] $name 버튼이 큰 배율에서 화면 밖으로 밀려 닿을 수 없습니다',
      rects: [now?.rect ?? was.rect],
      texts: [was.label],
    );
  }
}

Iterable<LayoutFinding> _inversions(
  ScaleSnapshot base,
  ScaleSnapshot scaled,
  ScaleAuditOptions options,
) sync* {
  final before = {for (final t in base.texts) t.key: t};
  final after = {for (final t in scaled.texts) t.key: t};
  final r = options.inversionRatio;
  for (final (ka, kb) in base.groups.intersection(scaled.groups)) {
    final (a0, b0, a1, b1) = (before[ka]!, before[kb]!, after[ka]!, after[kb]!);
    if ([a0, b0, a1, b1].any((t) => t.moving)) continue;
    final (big0, small0, big1, small1) =
        a0.fontSize >= b0.fontSize ? (a0, b0, a1, b1) : (b0, a0, b1, a1);
    if (big0.fontSize < small0.fontSize * r ||
        small1.fontSize < big1.fontSize * r) {
      continue;
    }
    yield _finding(
      LayoutFindingKind.scaleInversion,
      '[위계 역전] ${_describe(big1)}이 기준 배율에서는 ${_describe(small1)}보다 컸는데 '
      '큰 배율에서는 더 작습니다 (${formatPx(big0.fontSize)}→${formatPx(big1.fontSize)}px, '
      '${formatPx(small0.fontSize)}→${formatPx(small1.fontSize)}px)',
      [big1, small1],
    );
  }
}
