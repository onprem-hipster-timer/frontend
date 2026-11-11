import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';

import 'recorded_reports.dart';
import 'support.dart';

void main() {
  final dir = Directory.systemTemp.createTempSync('layout_audit_reg_');
  final reports = <LayoutReport>[];
  var verified = 0;
  final cases = ValueVariant<LayoutAuditCase>({
    const LayoutAuditCase(TestViewports.iphoneSe1, 1.0),
    const LayoutAuditCase(TestViewports.phoneLarge, 2.0),
  });

  testLayoutAudit(
    'registry',
    subject: '제목',
    texts: const [StressTexts.emoji, StressTexts.numeric],
    variant: cases,
    sink: LayoutReportSink(
      reportDir: dir.path,
      environment: const {},
      writeLine: (_) {},
      onReport: reports.add,
    ),
    within: find.byType(OverlappingPair),
    build: (text) => MaterialApp(
      home: Scaffold(
        body:
            Column(children: [squareText(text.value), const OverlappingPair()]),
      ),
    ),
    verify: (tester) {
      verified++;
      expect(find.byType(OverlappingPair), findsOneWidget);
    },
  );

  tearDownAll(() {
    dir.deleteSync(recursive: true);

    // 텍스트 2개 × 조합 2개 = 테스트 4개가 각자 보고하고 verify를 부른다.
    expect(reports, hasLength(4));
    expect(verified, 4);
    expect(reports.map((r) => r.name).toSet(), {'registry'});
    expect(
      reports.map((r) => r.caseLabel),
      containsAll([
        '${cases.values.first} · 제목 · ${StressTexts.emoji.label}',
        '${cases.values.last} · 제목 · ${StressTexts.numeric.label}',
      ]),
    );
    for (final report in reports) {
      expect(ofKind(report.findings, LayoutFindingKind.overlap), hasLength(1));
    }

    // 명시 모드로 점검한 테스트는 자동 감사가 다시 보고하지 않는다.
    expect(
      recordedReports.where((r) => r.name.contains(slugify('제목에서 겹침·넘침·잘림을'))),
      isEmpty,
    );
  });
}
