import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'devices.dart';

/// 화면 하나와 글자 배율 하나의 조합.
@immutable
class LayoutAuditCase {
  const LayoutAuditCase(this.viewport, this.textScale);

  final TestViewport viewport;
  final double textScale;

  @override
  bool operator ==(Object other) =>
      other is LayoutAuditCase &&
      other.viewport == viewport &&
      other.textScale == textScale;

  @override
  int get hashCode => Object.hash(viewport, textScale);

  @override
  String toString() => '$viewport, 글자 $textScale배';
}

abstract final class LayoutAuditCases {
  static const phoneScales = [1.0, 1.3, 2.0];

  // 큰 화면에서 2배 글자는 폰 2배 조합이 이미 잡는 문제를 되풀이한다.
  static const largeScales = [1.0, 1.3];

  static final Set<LayoutAuditCase> phones = {
    for (final viewport in const [
      TestViewports.phoneSmall,
      TestViewports.phoneLarge,
      TestViewports.iphoneSe1,
      TestViewports.iphoneMini,
      TestViewports.zFlipMain,
      TestViewports.zFlipCover,
      TestViewports.phoneSmallLandscape,
    ])
      for (final scale in phoneScales) LayoutAuditCase(viewport, scale),
  };

  static final Set<LayoutAuditCase> large = {
    for (final viewport in const [
      TestViewports.duoSingle,
      TestViewports.duoSpanned,
      TestViewports.zFoldInner,
      TestViewports.tabletPortrait,
      TestViewports.tabletLandscape,
      TestViewports.desktop4x3,
      TestViewports.desktop16x10,
      TestViewports.desktopFhd16x9,
      TestViewports.ultraWide21x9,
    ])
      for (final scale in largeScales) LayoutAuditCase(viewport, scale),
  };

  static final Set<LayoutAuditCase> all = {...phones, ...large};
}

abstract final class LayoutAuditVariants {
  static final phones = ValueVariant<LayoutAuditCase>(LayoutAuditCases.phones);
  static final large = ValueVariant<LayoutAuditCase>(LayoutAuditCases.large);
  static final all = ValueVariant<LayoutAuditCase>(LayoutAuditCases.all);
}
