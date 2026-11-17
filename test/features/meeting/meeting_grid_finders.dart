import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// 스크린 리더 이름이 [label]인 격자 칸의 화면 가운데(논리 픽셀).
///
/// 칸은 그림 하나 위의 접근성 항목이라 위젯 대신 접근성 트리에서 자리를 찾는다.
/// `tester.ensureSemantics()`를 켠 뒤에 부른다.
Offset cellCenter(WidgetTester tester, String label) {
  final node = find.semantics.byLabel(label).evaluate().single;
  var transform = Matrix4.identity();
  for (SemanticsNode? at = node; at != null; at = at.parent) {
    final local = at.transform;
    if (local != null) transform = local.multiplied(transform);
  }
  return MatrixUtils.transformRect(transform, node.rect).center /
      tester.view.devicePixelRatio;
}

/// 스크린 리더 이름이 [label]인 격자 칸의 접근성 정보
SemanticsData cellData(String label) =>
    find.semantics.byLabel(label).evaluate().single.getSemanticsData();
