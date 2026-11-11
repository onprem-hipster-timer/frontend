import 'dart:ui' show Rect;

import 'source_location.dart';

enum LayoutFindingKind {
  overlap,
  overflow,
  clipped,
  offscreen,
  truncation,
  moving,

  /// 아래는 배율 비교(`scale_audit.dart`)가 낸다.
  scaleTruncation,
  scaleVanished,
  scaleUnreachable,
  scaleInversion,
}

enum LayoutSeverity { warning, notice, info }

class LayoutFinding {
  const LayoutFinding({
    required this.kind,
    required this.severity,
    required this.message,
    this.rects = const <Rect>[],
    this.locations = const <SourceLocation?>[],
    this.texts = const <String>[],
    this.insideStack = false,
    this.coveredFraction,
    this.coveringRoot,
    this.zOrderKnown = false,
    this.count = 1,
  });

  /// 점검 자체가 오류로 끝났음을 알린다. 테스트를 실패시키지 않도록 info다.
  LayoutFinding.auditFailed(Object error)
      : this(
          kind: LayoutFindingKind.overlap,
          severity: LayoutSeverity.info,
          message: '[점검 실패] 레이아웃 점검 중 오류가 났습니다: $error',
        );

  /// 글자·이미지가 너무 많아 점검을 건너뛰었음을 알린다.
  LayoutFinding.auditSkipped({required int leaves, required int maxLeaves})
      : this(
          kind: LayoutFindingKind.overlap,
          severity: LayoutSeverity.info,
          message:
              '[점검 건너뜀] 텍스트·이미지가 $leaves개로 maxLeaves($maxLeaves)를 넘어 검사를 건너뜁니다',
        );

  final LayoutFindingKind kind;
  final LayoutSeverity severity;

  /// 사람이 읽는 한국어 설명.
  final String message;

  /// 전역 논리 픽셀. 대상 leaf마다 [texts]와 같은 순서로 하나씩, 겹침이면 마지막에 교차 영역.
  final List<Rect> rects;

  /// [texts]와 같은 순서. 순서를 아는 겹침이면 위에 그려진 쪽이 먼저다.
  final List<SourceLocation?> locations;

  /// 이미지는 빈 문자열.
  final List<String> texts;

  /// 두 leaf의 가장 가까운 공통 조상이 Stack이다.
  final bool insideStack;

  /// 작은 쪽 leaf 면적 중 큰 쪽이 덮는 비율.
  final double? coveredFraction;

  /// 공통 조상 바로 아래에서 위쪽 leaf를 품은 위젯의 위치.
  final SourceLocation? coveringRoot;

  final bool zOrderKnown;

  /// 같은 (kind, locations)로 묶인 발견 수.
  final int count;

  LayoutFinding copyWith({int? count, LayoutSeverity? severity}) =>
      LayoutFinding(
        kind: kind,
        severity: severity ?? this.severity,
        message: message,
        rects: rects,
        locations: locations,
        texts: texts,
        insideStack: insideStack,
        coveredFraction: coveredFraction,
        coveringRoot: coveringRoot,
        zOrderKnown: zOrderKnown,
        count: count ?? this.count,
      );

  @override
  String toString() => count > 1 ? '$message (x$count)' : message;
}
