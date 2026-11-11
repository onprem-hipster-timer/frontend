import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'leaf_geometry.dart';
import 'source_location.dart';

/// 점검할 render 트리의 뿌리. [within]이 없으면 화면 전체다.
Iterable<RenderObject> auditRoots(WidgetTester tester, Finder? within) {
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

/// 화면 전체의 논리 픽셀 사각형.
Rect auditViewRect(WidgetTester tester) =>
    Offset.zero & (tester.view.physicalSize / tester.view.devicePixelRatio);

/// 보고서 문구에 쓰는 글자(20자까지)와 소스 위치.
String describeLeaf(ContentLeaf leaf) {
  final text = leaf.text.isEmpty
      ? '[이미지]'
      : "'${leaf.text.length > 20 ? '${leaf.text.substring(0, 20)}…' : leaf.text}'";
  return '$text(${sourceLocationOf(leaf.box) ?? '위치 불명'})';
}
