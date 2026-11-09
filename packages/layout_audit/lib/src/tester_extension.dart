import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auditor.dart';
import 'binding.dart';
import 'devices.dart';
import 'overflow_recorder.dart';
import 'report.dart';
import 'variants.dart';

extension LayoutAuditTester on WidgetTester {
  /// 조합을 적용해 [child]를 띄우고 두 프레임을 비교해 감사한 뒤 보고한다.
  ///
  /// [wrap]이 null이면 `MaterialApp(home: Scaffold(body: child))`로 감싼다.
  /// [settle]은 입장 애니메이션이 끝나길 기다리는 시간, [frameGap]은 비교할 두 프레임 사이 간격이다.
  /// [label]은 보고서 제목에 조합 뒤에 붙는다(예: 어떤 스트레스 텍스트였는지).
  Future<LayoutReport> pumpAndAuditLayout({
    required String name,
    required LayoutAuditCase auditCase,
    required Widget child,
    String? label,
    Widget Function(Widget child)? wrap,
    Finder? within,
    LayoutAuditOptions options = const LayoutAuditOptions(),
    bool strict = layoutAuditStrict,
    LayoutReportSink sink = const LayoutReportSink(),
    Duration settle = const Duration(milliseconds: 500),
    Duration frameGap = const Duration(milliseconds: 100),
  }) async {
    setTestViewport(auditCase.viewport);
    platformDispatcher.textScaleFactorTestValue = auditCase.textScale;
    addTearDown(platformDispatcher.clearTextScaleFactorTestValue);

    final overflows = await recordLayoutOverflows(() async {
      await pumpWidget(
        wrap?.call(child) ?? MaterialApp(home: Scaffold(body: child)),
      );
      await pumpStableFrames();
      // pumpAndSettle은 반복 애니메이션에서 끝나지 않는다.
      await pump(settle);
    });
    final previous = snapshotLeafBoxes(this, within: within);
    await pump(frameGap);

    final report = LayoutReport(
      name: name,
      caseLabel: label == null ? auditCase.toString() : '$auditCase · $label',
      viewSize: auditCase.viewport.logicalSize,
      findings: [
        ...overflows,
        ...auditLayout(
          this,
          within: within,
          options: options,
          previousFrame: previous,
        ),
      ],
    );
    final binding = this.binding;
    if (binding is LayoutAuditBinding) {
      binding.skipAutoAudit();
    }
    emitLayoutReport(report, strict: strict, sink: sink);
    return report;
  }
}
