import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';

/// 테마의 줄 높이·자간을 지워 테스트 글꼴의 글자가 20px 정사각형이 되게 한다.
const squareStyle = TextStyle(fontSize: 20, height: 1, letterSpacing: 0);

Widget squareText(String text) => Text(text, style: squareStyle);

Widget at(double left, double top, Widget child) =>
    Positioned(left: left, top: top, child: child);

/// 360x800 논리 픽셀, 기기 픽셀 비율 3인 화면에 [body]를 띄운다.
Future<void> pumpInApp(WidgetTester tester, Widget body) async {
  tester.view.physicalSize = const Size(360 * 3, 800 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: body)));
}

List<LayoutFinding> ofKind(
  Iterable<LayoutFinding> findings,
  LayoutFindingKind kind,
) =>
    findings.where((f) => f.kind == kind).toList();

/// 'BBBB'가 'AAAA' 오른쪽 70px을 덮는 Stack.
class OverlappingPair extends StatelessWidget {
  const OverlappingPair({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 30,
        child: Stack(
          children: [
            at(0, 0, squareText('AAAA')),
            at(10, 0, squareText('BBBB'))
          ],
        ),
      );
}

Directory tempDir() {
  final dir = Directory.systemTemp.createTempSync('layout_audit_');
  addTearDown(() => dir.deleteSync(recursive: true));
  return dir;
}

LayoutFinding makeFinding(
  LayoutSeverity severity,
  String message, {
  LayoutFindingKind kind = LayoutFindingKind.overlap,
  int count = 1,
  String? file,
  int line = 1,
  List<Rect> rects = const [],
}) =>
    LayoutFinding(
      kind: kind,
      severity: severity,
      message: message,
      count: count,
      rects: rects,
      locations: [if (file != null) SourceLocation(file, line, 1)],
    );

LayoutReport makeReport(
  List<LayoutFinding> findings, {
  String name = '홈 화면',
  Size? viewSize,
}) =>
    LayoutReport(
      name: name,
      caseLabel: '360x800',
      findings: findings,
      viewSize: viewSize,
    );

/// [dir]에 쓰고 환경 변수는 [env]만 보는 출력 대상. [lines]가 있으면 콘솔 줄을 모은다.
LayoutReportSink sinkFor(
  Directory dir, {
  Map<String, String> env = const {},
  List<String>? lines,
}) =>
    LayoutReportSink(
      reportDir: dir.path,
      environment: env,
      writeLine: lines?.add ?? (_) {},
    );
