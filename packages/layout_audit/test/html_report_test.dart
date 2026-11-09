import 'dart:io';
import 'dart:ui' show Rect, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';

LayoutFinding _finding(
  LayoutSeverity severity,
  String message, {
  LayoutFindingKind kind = LayoutFindingKind.overlap,
  List<Rect> rects = const [],
}) =>
    LayoutFinding(
      kind: kind,
      severity: severity,
      message: message,
      rects: rects,
    );

LayoutReport _report(
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

Directory _tempDir() {
  final dir = Directory.systemTemp.createTempSync('layout_audit_');
  addTearDown(() => dir.deleteSync(recursive: true));
  return dir;
}

LayoutReportSink _sink(Directory dir, {Map<String, String> env = const {}}) =>
    LayoutReportSink(
      reportDir: dir.path,
      environment: env,
      writeLine: (_) {},
    );

void main() {
  test('HTML 보고서는 머리말을 한 번만 쓰고 섹션을 덧붙인다', () {
    final dir = _tempDir();
    final report = _report([_finding(LayoutSeverity.warning, '경고')]);

    emitLayoutReport(report, strict: false, sink: _sink(dir));
    emitLayoutReport(report, strict: false, sink: _sink(dir));

    final file = File('${dir.path}/홈_화면.html');
    expect(file.existsSync(), isTrue);
    final html = file.readAsStringSync();
    expect('<!doctype html>'.allMatches(html), hasLength(1));
    expect('<style'.allMatches(html), hasLength(1));
    expect('<section class="report"'.allMatches(html), hasLength(2));
    expect(RegExp('<h1>[^<]*홈 화면[^<]*</h1>').hasMatch(html), isTrue);
  });

  test('HTML 표는 심각도 클래스와 종류 데이터로 거를 수 있다', () {
    final dir = _tempDir();
    emitLayoutReport(
      _report([
        _finding(LayoutSeverity.warning, '넘침',
            kind: LayoutFindingKind.overflow),
        _finding(LayoutSeverity.notice, '겹침'),
        _finding(LayoutSeverity.info, '말줄임',
            kind: LayoutFindingKind.truncation),
      ]),
      strict: false,
      sink: _sink(dir),
    );

    final html = File('${dir.path}/홈_화면.html').readAsStringSync();
    expect(html, contains('<tr class="warning" data-kind="넘침">'));
    expect(html, contains('<tr class="notice" data-kind="겹침">'));
    expect(html, contains('<tr class="info" data-kind="말줄임">'));

    final inputs = RegExp('<input[^>]*>').allMatches(html).map((m) => m[0]!);
    for (final severity in ['warning', 'notice', 'info']) {
      expect(inputs.where((i) => i.contains('data-severity="$severity"')),
          hasLength(1));
    }
    for (final kind in ['겹침', '넘침', '잘라냄', '이탈', '말줄임', '이동']) {
      final input = inputs.singleWhere((i) => i.contains('data-kind="$kind"'));
      expect(input, contains('checked'));
    }
    expect(
      inputs.singleWhere((i) => i.contains('data-severity="info"')),
      isNot(contains('checked')),
    );
    expect(
      inputs.singleWhere((i) => i.contains('data-severity="warning"')),
      contains('checked'),
    );
  });

  test('겹침은 뷰포트 축소판 SVG에 두 상자와 교차 영역을 그린다', () {
    const a = Rect.fromLTWH(10, 20, 100, 30);
    const b = Rect.fromLTWH(50.25, 25, 100, 30);
    final overlap = _finding(
      LayoutSeverity.warning,
      '겹침',
      rects: [a, b, a.intersect(b)],
    );

    final section =
        _report([overlap], viewSize: const Size(360, 800)).toHtmlSection();
    expect('<svg'.allMatches(section), hasLength(1));
    expect(section, contains('viewBox="0 0 360 800"'));
    expect(section, contains('width="160"'));
    expect('<rect'.allMatches(section), hasLength(4));
    expect(section, contains('x="10.0" y="20.0" width="100.0" height="30.0"'));
    expect(section, contains('x="50.3" y="25.0" width="100.0" height="30.0"'));
    expect(section, contains('x="50.3" y="25.0" width="59.8" height="25.0"'));

    expect(_report([overlap]).toHtmlSection(), isNot(contains('<svg')));
    expect(
      _report([_finding(LayoutSeverity.warning, '위치 없음')],
              viewSize: const Size(360, 800))
          .toHtmlSection(),
      isNot(contains('<svg')),
    );
  });

  test('HTML은 메시지의 특수 문자를 이스케이프한다', () {
    final section = _report(
      [_finding(LayoutSeverity.warning, 'a<b & "c" | d')],
      name: '<이름>',
    ).toHtmlSection();

    expect(section, contains('a&lt;b &amp; &quot;c&quot; | d'));
    expect(section, isNot(contains('a<b')));
    expect(section, contains('data-name="&lt;이름&gt;"'));
  });

  test('발견이 없거나 LAYOUT_AUDIT=off면 HTML도 쓰지 않는다', () {
    final dir = _tempDir();

    emitLayoutReport(_report(const []), sink: _sink(dir));
    emitLayoutReport(
      _report([_finding(LayoutSeverity.warning, '경고')]),
      strict: false,
      sink: _sink(dir, env: const {'LAYOUT_AUDIT': 'off'}),
    );

    expect(dir.listSync(), isEmpty);
  });
}
