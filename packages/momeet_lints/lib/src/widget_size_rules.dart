import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:momeet_lints/src/baselined_rule.dart';
import 'package:momeet_lints/src/widget_types.dart';

const _stale = '{0}은(는) 이제 규칙을 지킵니다. lint_baseline.txt에서 이 줄을 지우세요.';

Iterable<ClassDeclaration> _widgetClasses(CompilationUnit unit) =>
    unit.declarations
        .whereType<ClassDeclaration>()
        .where((c) => isWidgetOrStateClass(c.declaredFragment?.element));

/// 위젯·State 클래스는 200줄 이하.
class MaxWidgetClassLines extends BaselinedRule {
  MaxWidgetClassLines() : super(code: _code, staleCode: _staleCode);

  static const _code = LintCode(
    'max_widget_class_lines',
    '위젯 클래스 {0}이(가) {1}줄입니다(허용 {2}줄). 작은 위젯으로 나누세요.',
    severity: DiagnosticSeverity.WARNING,
  );
  static const _staleCode = LintCode(
    'max_widget_class_lines_baseline_stale',
    _stale,
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  int get limit => 200;

  @override
  Iterable<Finding> find(CompilationUnit unit, RuleContext context) =>
      _widgetClasses(unit).map(
        (c) => Finding(
          c.namePart.typeName.lexeme,
          c.namePart.typeName,
          lines:
              lineSpan(unit, c.firstTokenAfterCommentAndMetadata, c.endToken),
        ),
      );
}

/// 위젯·State의 build는 80줄 이하.
class MaxBuildLines extends BaselinedRule {
  MaxBuildLines() : super(code: _code, staleCode: _staleCode);

  static const _code = LintCode(
    'max_build_lines',
    '{0}이(가) {1}줄입니다(허용 {2}줄). 화면 조각을 위젯 클래스로 나누세요.',
    severity: DiagnosticSeverity.WARNING,
  );
  static const _staleCode = LintCode(
    'max_build_lines_baseline_stale',
    _stale,
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  int get limit => 80;

  @override
  Iterable<Finding> find(CompilationUnit unit, RuleContext context) sync* {
    for (final c in _widgetClasses(unit)) {
      for (final m in c.body.members.whereType<MethodDeclaration>()) {
        if (m.name.lexeme != 'build') continue;
        yield Finding(
          '${c.namePart.typeName.lexeme}.build',
          m.name,
          lines:
              lineSpan(unit, m.firstTokenAfterCommentAndMetadata, m.endToken),
        );
      }
    }
  }
}

/// `lib/` 파일은 400줄 이하.
class MaxFileLines extends BaselinedRule {
  MaxFileLines() : super(code: _code, staleCode: _staleCode);

  static const _code = LintCode(
    'max_file_lines',
    '파일이 {1}줄입니다(허용 {2}줄). 파일을 나누세요.',
    severity: DiagnosticSeverity.WARNING,
  );
  static const _staleCode = LintCode(
    'max_file_lines_baseline_stale',
    _stale,
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  int get limit => 400;

  @override
  Iterable<Finding> find(CompilationUnit unit, RuleContext context) {
    final content = context.currentUnit?.content ?? '';
    var lines = '\n'.allMatches(content).length;
    if (content.isNotEmpty && !content.endsWith('\n')) lines++;
    return [Finding('-', unit.beginToken, lines: lines)];
  }
}
