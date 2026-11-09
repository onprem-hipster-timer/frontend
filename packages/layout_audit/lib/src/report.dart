import 'dart:io';
import 'dart:ui' show Rect, Size;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'finding.dart';
import 'source_location.dart';

/// `--dart-define=LAYOUT_AUDIT_STRICT=true`면 warning이 있는 보고서가 테스트를 실패시킨다.
const bool layoutAuditStrict = bool.fromEnvironment('LAYOUT_AUDIT_STRICT');

const _kindNames = {
  LayoutFindingKind.overlap: '겹침',
  LayoutFindingKind.overflow: '넘침',
  LayoutFindingKind.clipped: '잘라냄',
  LayoutFindingKind.offscreen: '이탈',
  LayoutFindingKind.truncation: '말줄임',
  LayoutFindingKind.moving: '이동',
};

/// GitHub 실행 화면이 어노테이션으로 덮이지 않도록 보고서당 상한.
const _maxAnnotations = 10;

class LayoutReport {
  const LayoutReport({
    required this.name,
    required this.caseLabel,
    required this.findings,
    this.viewSize,
  });

  final String name;
  final String caseLabel;
  final List<LayoutFinding> findings;

  /// 점검한 뷰의 논리 픽셀 크기. 있으면 HTML 보고서에 발견 위치를 축소판으로 그린다.
  final Size? viewSize;

  bool get isEmpty => findings.isEmpty;

  int countOf(LayoutSeverity severity) =>
      findings.where((f) => f.severity == severity).length;

  String get _counts => 'warning ${countOf(LayoutSeverity.warning)}, '
      'notice ${countOf(LayoutSeverity.notice)}, '
      'info ${countOf(LayoutSeverity.info)}';

  String get _header => '레이아웃 점검: $name / $caseLabel — $_counts';

  /// 콘솔용.
  String describe() =>
      [_header, ...findings.map((f) => f.toString())].join('\n');

  String toMarkdown() {
    final rows = _sorted(findings).map((f) {
      final message = f.message.replaceAll('|', r'\|').replaceAll('\n', ' ');
      return '| ${f.severity.name} | ${_kindNames[f.kind]} | $message | ${f.count} |';
    });
    return [
      '### $name — $caseLabel',
      '',
      '| 심각도 | 종류 | 내용 | 횟수 |',
      '| --- | --- | --- | --- |',
      ...rows,
    ].join('\n');
  }

  String toHtmlSection() {
    final rows = _sorted(findings).map((f) {
      final kind = _kindNames[f.kind]!;
      return '<tr class="${f.severity.name}" data-kind="$kind">'
          '<td>${f.severity.name}</td><td>$kind</td>'
          '<td>${_escapeHtml(f.message)}</td><td>${f.count}</td>'
          '<td>${_miniMap(f.rects)}</td></tr>';
    });
    return [
      '<section class="report" data-name="${_escapeHtml(name)}" '
          'data-case="${_escapeHtml(caseLabel)}">',
      '<h2>${_escapeHtml('$name — $caseLabel')}</h2>',
      '<p class="counts">${_escapeHtml(_counts)}</p>',
      '<table><tr><th>심각도</th><th>종류</th><th>내용</th><th>횟수</th>'
          '<th>위치(그림)</th></tr>',
      ...rows,
      '</table>',
      '</section>',
    ].join('\n');
  }

  String _miniMap(List<Rect> rects) {
    final view = viewSize;
    if (view == null || rects.isEmpty || view.isEmpty) {
      return '';
    }
    final height = _decimal(_miniMapWidth * view.height / view.width);
    final boxes = [
      for (final (i, r) in rects.indexed)
        '<rect class="${_rectClass(i, rects.length)}" x="${_decimal(r.left)}" '
            'y="${_decimal(r.top)}" width="${_decimal(r.width)}" '
            'height="${_decimal(r.height)}"><title>${i + 1}: '
            '${_decimal(r.left)}, ${_decimal(r.top)}, ${_decimal(r.right)}, '
            '${_decimal(r.bottom)}</title></rect>',
    ];
    return '<svg viewBox="0 0 ${_number(view.width)} ${_number(view.height)}" '
        'width="$_miniMapWidth" height="$height">'
        '<rect class="view" width="${_number(view.width)}" '
        'height="${_number(view.height)}"/>${boxes.join()}</svg>';
  }
}

const _miniMapWidth = 160;

String _rectClass(int index, int length) {
  if (length == 3 && index == 2) {
    return 'cross';
  }
  return index == 0 ? 'first' : 'second';
}

String _decimal(double value) => value.toStringAsFixed(1);

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

String _escapeHtml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _htmlHead(String name) => '''<!doctype html>
<html lang="ko"><head><meta charset="utf-8">
<title>layout audit — ${_escapeHtml(name)}</title>
<style>
body{font:13px/1.4 monospace;margin:0 16px 32px;color:#222;background:#fff}
.filters{position:sticky;top:0;background:#f4f4f4;padding:6px 8px;border-bottom:1px solid #ccc}
.filters label{margin-right:10px}
.hint,.counts{color:#666}
table{border-collapse:collapse;width:100%}
th,td{border:1px solid #ddd;padding:3px 6px;text-align:left;vertical-align:top}
tr.warning td:first-child{color:#c62828;font-weight:bold}
tr.notice td:first-child{color:#b26a00}
tr.info td:first-child{color:#888}
tr.warning{background:#fdecea}
tr.notice{background:#fff6e0}
svg .view{fill:#fafafa;stroke:#999;stroke-width:2}
svg .first{fill:#1e88e5;fill-opacity:.4}
svg .second{fill:#43a047;fill-opacity:.4}
svg .cross{fill:#e53935;fill-opacity:.7}
</style>
<script>
document.addEventListener('DOMContentLoaded', () => {
  const boxes = [...document.querySelectorAll('.filters input')];
  const apply = () => {
    const on = (attr) => new Set(boxes.filter((b) => b.dataset[attr] && b.checked).map((b) => b.dataset[attr]));
    const severities = on('severity');
    const kinds = on('kind');
    for (const row of document.querySelectorAll('tr[data-kind]')) {
      row.hidden = !severities.has(row.className) || !kinds.has(row.dataset.kind);
    }
    for (const section of document.querySelectorAll('section.report')) {
      section.hidden = [...section.querySelectorAll('tr[data-kind]')].every((r) => r.hidden);
    }
  };
  boxes.forEach((b) => b.addEventListener('change', apply));
  apply();
});
</script>
</head><body>
<h1>layout audit — ${_escapeHtml(name)}</h1>
<p class="hint">축소판: 파랑·초록은 겹친 두 상자, 빨강은 교차 영역. 상자에 마우스를 올리면 좌표가 보인다.</p>
<div class="filters">
심각도
<label><input type="checkbox" data-severity="warning" checked>warning</label>
<label><input type="checkbox" data-severity="notice" checked>notice</label>
<label><input type="checkbox" data-severity="info">info</label>
| 종류
${_kindNames.values.map((k) => '<label><input type="checkbox" data-kind="$k" checked>$k</label>').join('\n')}
</div>
''';

/// 보고서 출력 대상. 기본은 실제 파일·콘솔이고 테스트에서 바꿔 끼운다.
class LayoutReportSink {
  const LayoutReportSink({
    this.reportDir = 'build/layout_audit',
    this.environment,
    this.writeLine,
    this.onReport,
  });

  final String reportDir;

  /// null이면 [Platform.environment].
  final Map<String, String>? environment;

  /// null이면 [debugPrint]. `debugPrint`는 상수가 아니라 기본값으로 둘 수 없다.
  final void Function(String)? writeLine;
  final void Function(LayoutReport)? onReport;
}

/// [report]를 파일·콘솔·GitHub Actions로 내보내고 [strict]면 warning에서 실패시킨다.
void emitLayoutReport(
  LayoutReport report, {
  bool strict = layoutAuditStrict,
  LayoutReportSink sink = const LayoutReportSink(),
}) {
  sink.onReport?.call(report);
  final env = sink.environment ?? Platform.environment;
  // LAYOUT_AUDIT=off는 자동·명시 모드 모두의 출력을 끈다.
  if (report.isEmpty || env['LAYOUT_AUDIT'] == 'off') {
    return;
  }
  final writeLine = sink.writeLine ?? debugPrint;
  final markdown = '${report.toMarkdown()}\n\n';
  final slug = slugify(report.name);
  final file = File('${sink.reportDir}/$slug.md');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(markdown, mode: FileMode.append);
  final html = File('${sink.reportDir}/$slug.html');
  // 닫는 태그 없이 섹션만 덧붙인다. 브라우저는 끝나지 않은 body를 그대로 그린다.
  if (!html.existsSync()) {
    html.writeAsStringSync(_htmlHead(report.name));
  }
  html.writeAsStringSync('${report.toHtmlSection()}\n', mode: FileMode.append);
  writeLine('${report._header} → ${file.path} ($slug.html)');

  if (env['GITHUB_ACTIONS'] == 'true') {
    _annotations(report).forEach(writeLine);
    final summary = env['GITHUB_STEP_SUMMARY'];
    if (summary != null && summary.isNotEmpty) {
      File(summary).writeAsStringSync(markdown, mode: FileMode.append);
    }
  }

  if (strict && report.countOf(LayoutSeverity.warning) > 0) {
    fail(report.describe());
  }
}

List<LayoutFinding> _sorted(List<LayoutFinding> findings) =>
    [...findings]..sort((a, b) {
        final bySeverity = a.severity.index.compareTo(b.severity.index);
        return bySeverity != 0 ? bySeverity : b.count.compareTo(a.count);
      });

Iterable<String> _annotations(LayoutReport report) {
  final seen = <(LayoutFindingKind, String, int)>{};
  final lines = <String>[];
  for (final f in _sorted(report.findings)) {
    if (f.severity == LayoutSeverity.info) {
      continue;
    }
    final location = f.locations.whereType<SourceLocation>().firstOrNull;
    if (location == null || !seen.add((f.kind, location.file, location.line))) {
      continue;
    }
    final file = _escapeProperty(location.file);
    final title = _escapeProperty('레이아웃 ${_kindNames[f.kind]}');
    lines.add(
      '::${f.severity.name} file=$file,line=${location.line},title=$title'
      '::${_escapeData(f.message)}',
    );
  }
  return lines.take(_maxAnnotations);
}

String _escapeData(String value) => value
    .replaceAll('%', '%25')
    .replaceAll('\r', '%0D')
    .replaceAll('\n', '%0A');

String _escapeProperty(String value) =>
    _escapeData(value).replaceAll(':', '%3A').replaceAll(',', '%2C');

/// 소문자로 바꾸고 파일 이름에 못 쓰는 글자를 `_`로 바꾼다.
String slugify(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9가-힣._-]'), '_');
