import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auditor.dart';
import 'devices.dart';
import 'overflow_recorder.dart';
import 'report.dart';
import 'variants.dart';

extension LayoutAuditTester on WidgetTester {
  /// 조합을 적용해 [child]를 띄우고 두 프레임을 비교해 감사한 뒤 보고한다.
  ///
  /// [wrap]이 null이면 `MaterialApp(home: Scaffold(body: child))`로 감싼다.
  /// [settle]은 입장 애니메이션이 끝나길 기다리는 시간, [frameGap]은 비교할 두 프레임 사이 간격이다.
  Future<LayoutReport> pumpAndAuditLayout({
    required String name,
    required LayoutAuditCase auditCase,
    required Widget child,
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
      caseLabel: auditCase.toString(),
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
    emitLayoutReport(report, strict: strict, sink: sink);
    return report;
  }
}
