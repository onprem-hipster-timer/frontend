import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auditor.dart';
import 'binding.dart';
import 'devices.dart';
import 'finding.dart';
import 'overflow_recorder.dart';
import 'report.dart';
import 'scale_audit.dart';
import 'variants.dart';

extension LayoutAuditTester on WidgetTester {
  /// 조합을 적용해 [child]를 띄우고 두 프레임을 비교해 감사한 뒤 보고한다.
  ///
  /// [wrap]이 null이면 `MaterialApp(home: Scaffold(body: child))`로 감싼다.
  /// [settle]은 입장 애니메이션이 끝나길 기다리는 시간, [frameGap]은 비교할 두 프레임 사이 간격이다.
  /// [label]은 보고서 제목에 조합 뒤에 붙는다(예: 어떤 스트레스 텍스트였는지).
  /// [scale]이 켜져 있으면 같은 [name]·[label]·화면 크기를 기준 배율로 점검해 둔 장면과 비교해
  /// `<name>_scale` 보고서를 따로 내고, 그 보고서는 [strict]가 아니라 [scaleStrict]로 실패시킨다.
  Future<LayoutReport> pumpAndAuditLayout({
    required String name,
    required LayoutAuditCase auditCase,
    required Widget child,
    String? label,
    Widget Function(Widget child)? wrap,
    Finder? within,
    LayoutAuditOptions options = const LayoutAuditOptions(),
    bool strict = layoutAuditStrict,
    ScaleAuditOptions scale = const ScaleAuditOptions(),
    bool scaleStrict = layoutAuditScaleStrict,
    LayoutReportSink sink = const LayoutReportSink(),
    Duration settle = const Duration(milliseconds: 500),
    Duration frameGap = const Duration(milliseconds: 100),
  }) async {
    setTestViewport(auditCase.viewport);
    platformDispatcher.textScaleFactorTestValue = auditCase.textScale;
    addTearDown(platformDispatcher.clearTextScaleFactorTestValue);
    // 배율 비교는 버튼을 시맨틱스 트리에서 찾는다. 장면을 찍자마자 닫는다.
    final semantics = scale.enabled ? ensureSemantics() : null;

    final List<LayoutFinding> overflows;
    final Map<RenderObject, List<Rect>> previous;
    final ScaleSnapshot? scaleSnapshot;
    try {
      overflows = await recordLayoutOverflows(() async {
        await pumpWidget(
          wrap?.call(child) ?? MaterialApp(home: Scaffold(body: child)),
        );
        await pumpStableFrames();
        // pumpAndSettle은 반복 애니메이션에서 끝나지 않는다.
        await pump(settle);
      });
      previous = snapshotLeafBoxes(this, within: within);
      await pump(frameGap);
      scaleSnapshot = scale.enabled
          ? captureScaleSnapshot(
              this,
              within: within,
              previousFrame: previous,
              options: scale,
            )
          : null;
    } finally {
      semantics?.dispose();
    }

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

    if (scaleSnapshot != null) {
      final scaleFindings = recordScaleCase(
        '$name\u0000${label ?? ''}\u0000${auditCase.viewport}',
        auditCase.textScale,
        scaleSnapshot,
        scale,
      );
      if (scaleFindings != null) {
        emitLayoutReport(
          LayoutReport(
            name: scaleReportName(name),
            caseLabel: report.caseLabel,
            viewSize: auditCase.viewport.logicalSize,
            findings: scaleFindings,
          ),
          strict: scaleStrict,
          sink: sink,
        );
      }
    }
    return report;
  }
}
