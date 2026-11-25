import 'package:flutter/foundation.dart';
import 'package:widgetbook/widgetbook.dart';

/// 레이아웃 점검(packages/layout_audit의 `TestViewports`)이 보는 화면 가운데 비율이 유난한 것들.
/// 크기와 화소 배율은 그쪽과 같다.
///
/// 테스트: widgetbook/test/edge_viewports_test.dart
const edgeViewports = <ViewportData>[
  ViewportData(
    name: 'iPhone SE 1세대 (가장 작은 폰)',
    width: 320,
    height: 568,
    pixelRatio: 2,
    platform: TargetPlatform.iOS,
  ),
  ViewportData(
    name: 'Galaxy Z Flip 펼침 (22:9)',
    width: 412,
    height: 1006,
    pixelRatio: 2.625,
    platform: TargetPlatform.android,
  ),
  ViewportData(
    name: 'Galaxy Z Flip 커버 화면',
    width: 360,
    height: 374,
    pixelRatio: 2,
    platform: TargetPlatform.android,
  ),
  ViewportData(
    name: 'Galaxy Z Fold 안쪽 화면',
    width: 906,
    height: 1088,
    pixelRatio: 2,
    platform: TargetPlatform.android,
  ),
  ViewportData(
    name: 'Surface Duo 한쪽 화면 (3:4)',
    width: 540,
    height: 720,
    pixelRatio: 2.5,
    platform: TargetPlatform.android,
  ),
  ViewportData(
    name: 'Surface Duo 두 화면 펼침 (3:2)',
    width: 1080,
    height: 720,
    pixelRatio: 2.5,
    platform: TargetPlatform.android,
  ),
  ViewportData(
    name: '가로로 눕힌 폰',
    width: 800,
    height: 360,
    pixelRatio: 3,
    platform: TargetPlatform.android,
  ),
  ViewportData(
    name: '울트라와이드 모니터 (21:9)',
    width: 2560,
    height: 1080,
    pixelRatio: 1,
    platform: TargetPlatform.windows,
  ),
];
