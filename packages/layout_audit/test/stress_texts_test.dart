import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';

void main() {
  test('스트레스 텍스트는 네 종류이고 라틴 문자열에는 공백이 없다', () {
    expect(StressTexts.all, hasLength(4));
    expect(StressTexts.all.map((t) => t.label).toSet(), hasLength(4));
    expect(StressTexts.latinUnbroken.value, isNot(contains(' ')));
    expect(StressTexts.koreanLong.value.length, greaterThanOrEqualTo(50));
  });
}
