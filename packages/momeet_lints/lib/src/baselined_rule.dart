import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:momeet_lints/src/lint_baseline.dart';
import 'package:momeet_lints/src/paths.dart';

/// 규칙이 찾은 대상 하나.
class Finding {
  Finding(this.symbol, this.at, {this.lines});

  /// baseline에 적는 이름(예: `_FooState`, `_FooState._buildRow`, `-`).
  final String symbol;

  /// 진단을 붙일 토큰.
  final Token at;

  /// 크기 규칙이면 줄 수.
  final int? lines;
}

/// `lib/` 아래 파일만 보고, [LintBaseline]에 적힌 기존 위반은 허용하는 규칙.
abstract class BaselinedRule extends MultiAnalysisRule {
  BaselinedRule({required this.code, required this.staleCode})
    : super(name: code.lowerCaseName, description: code.problemMessage);

  final LintCode code;

  final LintCode staleCode;

  /// 크기 규칙의 줄 수 상한. null이면 대상이 있기만 해도 위반이다.
  int? get limit => null;

  @override
  List<DiagnosticCode> get diagnosticCodes => [code, staleCode];

  Iterable<Finding> find(CompilationUnit unit, RuleContext context);

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addCompilationUnit(this, _UnitVisitor(this, context));
  }

  void _check(CompilationUnit unit, RuleContext context) {
    final path = packageRelativePath(context);
    if (!path.startsWith('lib/')) return;
    final allowed = LintBaseline.of(context).entriesFor(name, path);
    final findings = find(unit, context).toList();
    final limit = this.limit;

    for (final finding in findings) {
      final lines = finding.lines;
      final violates = limit == null
          ? !allowed.containsKey(finding.symbol)
          : lines! > _max(limit, allowed[finding.symbol]);
      if (!violates) continue;
      reportAtOffset(
        finding.at.offset,
        finding.at.length,
        diagnosticCode: code,
        arguments: limit == null
            ? [finding.symbol]
            : [finding.symbol, lines!, _max(limit, allowed[finding.symbol])],
      );
    }

    for (final symbol in allowed.keys) {
      final still = findings.any(
        (f) => f.symbol == symbol && (limit == null || f.lines! > limit),
      );
      if (still) continue;
      reportAtOffset(
        unit.beginToken.offset,
        unit.beginToken.length,
        diagnosticCode: staleCode,
        arguments: [symbol],
      );
    }
  }

  static int _max(int limit, int? baseline) =>
      baseline != null && baseline > limit ? baseline : limit;
}

class _UnitVisitor extends SimpleAstVisitor<void> {
  _UnitVisitor(this.rule, this.context);

  final BaselinedRule rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) => rule._check(node, context);
}

/// [first]부터 [last]까지 몇 줄인지.
int lineSpan(CompilationUnit unit, Token first, Token last) {
  final info = unit.lineInfo;
  return info.getLocation(last.end).lineNumber -
      info.getLocation(first.offset).lineNumber +
      1;
}
