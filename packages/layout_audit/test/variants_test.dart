import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';

void main() {
  test('phones는 21개, large는 18개, all은 39개 조합이다', () {
    expect(LayoutAuditCases.phones, hasLength(21));
    expect(LayoutAuditCases.large, hasLength(18));
    expect(LayoutAuditCases.all, hasLength(39));
    expect(LayoutAuditVariants.all.values, hasLength(39));
  });

  test('조합 이름은 화면과 글자 배율을 함께 적는다', () {
    expect(
      const LayoutAuditCase(TestViewports.iphoneSe1, 2.0).toString(),
      'iphone-se-1 320x568 @2.0x, 글자 2.0배',
    );
  });

  test('같은 화면과 배율이면 같은 조합이다', () {
    const a = LayoutAuditCase(TestViewports.phoneSmall, 1.3);
    const b = LayoutAuditCase(TestViewports.phoneSmall, 1.3);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(const LayoutAuditCase(TestViewports.phoneSmall, 2.0)));
  });
}
