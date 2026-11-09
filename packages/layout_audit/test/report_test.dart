import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';

import 'support.dart';

List<String> _tableRows(String markdown) => markdown
    .split('\n')
    .where((l) =>
        l.startsWith('| ') && !l.startsWith('| 심각도') && !l.startsWith('| ---'))
    .toList();

void main() {
  final mixed = makeReport([
    makeFinding(LayoutSeverity.notice, '알림 하나', count: 1),
    makeFinding(LayoutSeverity.info, '정보'),
    makeFinding(LayoutSeverity.notice, '알림 둘', count: 2),
    makeFinding(
      LayoutSeverity.warning,
      '경고 a|b',
      kind: LayoutFindingKind.overflow,
      count: 3,
    ),
  ]);

  test('describe와 toMarkdown이 심각도 순으로 정리한다', () {
    final lines = mixed.describe().split('\n');
    expect(
        lines.first, '레이아웃 점검: 홈 화면 / 360x800 — warning 1, notice 2, info 1');
    expect(lines.skip(1), hasLength(4));
    expect(lines.skip(1), contains('경고 a|b (x3)'));

    final markdown = mixed.toMarkdown();
    expect(
        markdown, startsWith('### 홈 화면 — 360x800\n\n| 심각도 | 종류 | 내용 | 횟수 |\n'));
    final rows = _tableRows(markdown);
    expect(rows, [
      r'| warning | 넘침 | 경고 a\|b | 3 |',
      '| notice | 겹침 | 알림 둘 | 2 |',
      '| notice | 겹침 | 알림 하나 | 1 |',
      '| info | 겹침 | 정보 | 1 |',
    ]);
    expect(mixed.countOf(LayoutSeverity.notice), 2);
    expect(mixed.isEmpty, isFalse);
    expect(makeReport(const []).isEmpty, isTrue);
  });

  test('종류는 모두 한국어로 표에 쓴다', () {
    final markdown = makeReport([
      for (final kind in LayoutFindingKind.values)
        makeFinding(LayoutSeverity.info, kind.name, kind: kind),
    ]).toMarkdown();

    for (final word in ['겹침', '넘침', '잘라냄', '이탈', '말줄임', '이동']) {
      expect(markdown, contains('| $word |'));
    }
  });

  test('마크다운 보고서를 reportDir에 남기고 발견이 없으면 남기지 않는다', () {
    final dir = tempDir();
    final lines = <String>[];
    final sink = LayoutReportSink(
      reportDir: '${dir.path}/out',
      environment: const {},
      writeLine: lines.add,
    );

    emitLayoutReport(makeReport(const [], name: 'Home Screen!'), sink: sink);
    expect(dir.listSync(recursive: true), isEmpty);
    expect(lines, isEmpty);

    final report = makeReport([makeFinding(LayoutSeverity.warning, '경고')],
        name: 'Home Screen!');
    emitLayoutReport(report, strict: false, sink: sink);
    final file = File('${dir.path}/out/home_screen_.md');
    expect(file.existsSync(), isTrue);
    expect(file.readAsStringSync(), '${report.toMarkdown()}\n\n');
    expect(lines.single, contains(file.path));
    expect(lines.single,
        startsWith('레이아웃 점검: Home Screen! / 360x800 — warning 1'));

    emitLayoutReport(report, strict: false, sink: sink);
    expect(
      '### '.allMatches(file.readAsStringSync()),
      hasLength(2),
    );
  });

  test('strict이면 warning으로만 실패하고 notice·info로는 실패하지 않는다', () {
    final dir = tempDir();
    final sink = sinkFor(dir);
    final warning = makeReport([makeFinding(LayoutSeverity.warning, '경고')]);

    expect(
      () => emitLayoutReport(warning, strict: true, sink: sink),
      throwsA(
        isA<TestFailure>().having((e) => e.message, 'message', contains('경고')),
      ),
    );
    emitLayoutReport(
      makeReport([makeFinding(LayoutSeverity.notice, '알림')]),
      strict: true,
      sink: sink,
    );
    emitLayoutReport(
      makeReport([makeFinding(LayoutSeverity.info, '정보')]),
      strict: true,
      sink: sink,
    );
    emitLayoutReport(warning, strict: false, sink: sink);
  });

  test('GitHub 모드에서 어노테이션은 10개까지, 요약 표는 전체를 쓴다', () {
    final dir = tempDir();
    final summary = File('${dir.path}/summary.md');
    final lines = <String>[];
    final sink = LayoutReportSink(
      reportDir: '${dir.path}/out',
      environment: {
        'GITHUB_ACTIONS': 'true',
        'GITHUB_STEP_SUMMARY': summary.path,
      },
      writeLine: lines.add,
    );
    final report = makeReport([
      makeFinding(LayoutSeverity.notice, '알림', file: 'lib/n.dart'),
      for (var i = 0; i < 12; i++)
        makeFinding(
          LayoutSeverity.warning,
          i == 0 ? '100%\n둘째 줄' : '경고 $i',
          file: i == 0 ? 'lib/a,b.dart' : 'lib/w.dart',
          line: i + 1,
          count: i == 0 ? 99 : 1,
        ),
    ]);

    emitLayoutReport(report, strict: false, sink: sink);

    final warnings = lines.where((l) => l.startsWith('::warning')).toList();
    expect(warnings, hasLength(10));
    expect(lines.where((l) => l.startsWith('::notice')), isEmpty);
    expect(
      warnings.first,
      '::warning file=lib/a%2Cb.dart,line=1,title=레이아웃 겹침::100%25%0A둘째 줄',
    );
    expect(_tableRows(summary.readAsStringSync()), hasLength(13));
  });

  test('GitHub 어노테이션은 같은 종류·위치를 하나로 묶고 info와 위치 없는 발견은 뺀다', () {
    final dir = tempDir();
    final lines = <String>[];
    final sink =
        sinkFor(dir, env: const {'GITHUB_ACTIONS': 'true'}, lines: lines);

    emitLayoutReport(
      makeReport([
        makeFinding(LayoutSeverity.warning, '첫째', file: 'lib/x.dart', line: 3),
        makeFinding(LayoutSeverity.warning, '둘째', file: 'lib/x.dart', line: 3),
        makeFinding(LayoutSeverity.notice, '알림', file: 'lib/y.dart', line: 4),
        makeFinding(LayoutSeverity.info, '정보', file: 'lib/z.dart'),
        makeFinding(LayoutSeverity.warning, '위치 없음'),
      ]),
      strict: false,
      sink: sink,
    );

    final annotations = lines.where((l) => l.startsWith('::')).toList();
    expect(annotations, [
      '::warning file=lib/x.dart,line=3,title=레이아웃 겹침::첫째',
      '::notice file=lib/y.dart,line=4,title=레이아웃 겹침::알림',
    ]);
  });

  test('onReport는 빈 보고서에도 불린다', () {
    final seen = <LayoutReport>[];
    final empty = makeReport(const []);

    emitLayoutReport(
      empty,
      sink: LayoutReportSink(
        environment: const {},
        writeLine: (_) => fail('빈 보고서는 출력하지 않는다'),
        onReport: seen.add,
      ),
    );

    expect(seen.single, same(empty));
  });

  test('LAYOUT_AUDIT=off면 파일도 콘솔도 쓰지 않고 onReport만 부른다', () {
    final dir = tempDir();
    final seen = <LayoutReport>[];
    final report = makeReport([makeFinding(LayoutSeverity.warning, '경고')]);

    emitLayoutReport(
      report,
      strict: false,
      sink: LayoutReportSink(
        reportDir: dir.path,
        environment: const {'LAYOUT_AUDIT': 'off'},
        writeLine: (_) => fail('꺼져 있으면 출력하지 않는다'),
        onReport: seen.add,
      ),
    );

    expect(seen.single, same(report));
    expect(dir.listSync(), isEmpty);
  });
}
