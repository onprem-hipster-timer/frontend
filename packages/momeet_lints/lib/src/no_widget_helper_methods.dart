import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:momeet_lints/src/baselined_rule.dart';
import 'package:momeet_lints/src/widget_types.dart';

/// Widget을 돌려주는 메서드·getter·최상위 함수 대신 위젯 클래스를 쓴다.
///
/// `build`, `@override`(프레임워크가 정한 메서드), 추상 선언은 제외한다.
/// 함수 안의 지역 함수와 builder 콜백은 보지 않는다.
class NoWidgetHelperMethods extends BaselinedRule {
  NoWidgetHelperMethods() : super(code: _code, staleCode: _staleCode);

  static const _code = LintCode(
    'no_widget_helper_methods',
    '{0}이(가) Widget을 돌려줍니다. 위젯 클래스로 만드세요.',
    severity: DiagnosticSeverity.WARNING,
  );
  static const _staleCode = LintCode(
    'no_widget_helper_methods_baseline_stale',
    '{0}은(는) 이제 규칙을 지킵니다. lint_baseline.txt에서 이 줄을 지우세요.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  Iterable<Finding> find(CompilationUnit unit, RuleContext context) {
    final collector = _Collector();
    unit.accept(collector);
    return collector.findings;
  }
}

class _Collector extends RecursiveAstVisitor<void> {
  final findings = <Finding>[];

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final element = node.declaredFragment?.element;
    if (node.name.lexeme != 'build' &&
        node.body is! EmptyFunctionBody &&
        !_hasOverride(node.metadata) &&
        element != null &&
        isWidgetType(element.returnType)) {
      final owner = element.enclosingElement?.name ?? '?';
      findings.add(Finding('$owner.${node.name.lexeme}', node.name));
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is! CompilationUnit) return;
    final element = node.declaredFragment?.element;
    if (element != null && isWidgetType(element.returnType)) {
      findings.add(Finding(node.name.lexeme, node.name));
    }
  }

  static bool _hasOverride(NodeList<Annotation> metadata) =>
      metadata.any((a) => a.name.name == 'override');
}
