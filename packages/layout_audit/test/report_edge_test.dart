import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';

void main() {
  test('GitHub 모드에 요약 파일 변수가 없어도 어노테이션만 쓰고 넘어간다', () {
    final dir = Directory.systemTemp.createTempSync('layout_audit_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final lines = <String>[];
    emitLayoutReport(
      LayoutReport(
        name: 'n',
        caseLabel: 'c',
        findings: [
          LayoutFinding(
            kind: LayoutFindingKind.overlap,
            severity: LayoutSeverity.warning,
            message: '경고',
            locations: const [SourceLocation('lib/a.dart', 1, 1)],
          ),
        ],
      ),
      strict: false,
      sink: LayoutReportSink(
        reportDir: dir.path,
        environment: const {'GITHUB_ACTIONS': 'true'},
        writeLine: lines.add,
      ),
    );
    expect(lines.where((l) => l.startsWith('::warning')), hasLength(1));
  });

  testWidgets('한 번의 펌프에서 난 넘침은 RenderObject마다 하나씩 기록한다', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final findings = await recordLayoutOverflows(
      () => tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Row(children: [SizedBox(width: 500, height: 10)]),
                Row(children: [SizedBox(width: 400, height: 10)]),
              ],
            ),
          ),
        ),
      ),
    );
    expect(findings, hasLength(2));
    expect(findings.map((f) => f.message).join(), contains('140.0px'));
    expect(findings.map((f) => f.message).join(), contains('40.0px'));
    expect(tester.takeException(), isNull);
  });
}
