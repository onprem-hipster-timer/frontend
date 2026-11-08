import 'dart:io';

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
  });

  final String name;
  final String caseLabel;
  final List<LayoutFinding> findings;

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
}

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
  if (report.isEmpty) {
    return;
  }
  final writeLine = sink.writeLine ?? debugPrint;
  final markdown = '${report.toMarkdown()}\n\n';
  final file = File('${sink.reportDir}/${_slug(report.name)}.md');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(markdown, mode: FileMode.append);
  writeLine('${report._header} → ${file.path}');

  final env = sink.environment ?? Platform.environment;
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

String _slug(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9가-힣._-]'), '_');
