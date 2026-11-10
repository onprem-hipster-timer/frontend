import 'package:flutter/semantics.dart';
import 'package:layout_audit/layout_audit.dart';

/// flutter_test_config.dart가 설치한 바인딩이 이 패키지 테스트마다 남긴 보고서.
final recordedReports = <LayoutReport>[];

/// true인 동안 정책의 `ignore`가 던진다.
bool throwInIgnore = false;

/// 이 패키지 테스트가 쓰는 정책. flutter_test_config.dart가 바인딩에 넣는다.
final testPolicy = LayoutAuditPolicy(
  floatingWidgets: const {'FloatingActionButton', 'Drawer', 'NavigationDrawer'},
  coveringLayers: const {'_RenderTheater'},
  // 아이콘 글꼴의 글리프(사용자 정의 영역)만으로 된 문단
  isUnscaledText: (text) =>
      text.isNotEmpty &&
      text.runes.every((r) => (r >= 0xE000 && r <= 0xF8FF) || r >= 0xF0000),
  isBackdrop: (data) => data.hasAction(SemanticsAction.dismiss),
  ignore: (_) {
    if (throwInIgnore) {
      throw StateError('ignore 실패');
    }
    return false;
  },
);
