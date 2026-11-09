import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auditor.dart';
import 'report.dart';
import 'stress_texts.dart';
import 'tester_extension.dart';
import 'variants.dart';

/// [texts]마다 `testWidgets`를 하나씩 등록해 [variant]의 조합 전부에서 [build]가 만든 화면을 점검한다.
///
/// 테스트 이름은 `'<텍스트 이름> <subject>에서 겹침·넘침·잘림을 보고한다'`, 보고서 라벨은
/// `'<subject> · <텍스트 이름>'`이다. [build]는 MaterialApp 같은 앱 껍데기까지 포함한 위젯을 돌려준다.
/// [verify]는 점검 뒤 예외가 없을 때 불리며 화면별 단언을 둔다.
void testLayoutAudit(
  String name, {
  required String subject,
  required Widget Function(StressText text) build,
  Finder? within,
  List<StressText> texts = StressTexts.all,
  ValueVariant<LayoutAuditCase>? variant,
  FutureOr<void> Function(WidgetTester tester)? verify,
  LayoutAuditOptions options = const LayoutAuditOptions(),
  LayoutReportSink sink = const LayoutReportSink(),
}) {
  final cases = variant ?? LayoutAuditVariants.all;
  for (final text in texts) {
    testWidgets('${text.label} $subject에서 겹침·넘침·잘림을 보고한다', variant: cases, (
      tester,
    ) async {
      await tester.pumpAndAuditLayout(
        name: name,
        auditCase: cases.currentValue!,
        label: '$subject · ${text.label}',
        wrap: (child) => child,
        within: within,
        options: options,
        sink: sink,
        child: build(text),
      );
      expect(tester.takeException(), isNull);
      await verify?.call(tester);

      // 반복 애니메이션·타이머가 다음 테스트로 남지 않게 내린다.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
