import 'package:flutter/semantics.dart' show SemanticsData;

import 'finding.dart';

/// 설계상 허용하는 배치와 보지 않을 발견.
///
/// 점검 코드는 예외를 갖지 않는다. 쓰는 쪽이 `LayoutAuditConfig.policy` 한 곳에서 정하면
/// 자동 모드와 명시 모드가 같이 쓴다. 기본값은 예외가 없다.
class LayoutAuditPolicy {
  const LayoutAuditPolicy({
    this.floatingWidgets = const {},
    this.coveringLayers = const {},
    this.isUnscaledText,
    this.isBackdrop,
    this.ignore,
  });

  /// 뒤 내용 위에 떠서 덮는 것이 설계인 위젯의 타입 이름. 그 안의 글자가 낀 겹침은 보지 않는다.
  final Set<String> floatingWidgets;

  /// 두 글자의 가장 가까운 공통 조상이 이 render 객체 타입이면, 위층이 아래층을 덮는 설계로 보고
  /// 겹침을 보지 않는다.
  final Set<String> coveringLayers;

  /// 글자 배율을 따르지 않는 문단. 배율 비교에서 뺀다.
  final bool Function(String text)? isUnscaledText;

  /// 누르기 동작이 있어도 버튼이 아닌 영역. 배율 밀려남에서 뺀다.
  final bool Function(SemanticsData data)? isBackdrop;

  /// true를 돌려준 발견은 버린다. 기존 점검과 배율 비교 모두에 묶기 전 발견 하나하나에 불린다.
  final bool Function(LayoutFinding finding)? ignore;
}
