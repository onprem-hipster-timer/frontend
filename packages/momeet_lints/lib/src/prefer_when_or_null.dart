import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// `loading`과 `error`가 null만 돌려주는 `when`은 `whenOrNull(data: …)`로 쓴다.
class PreferWhenOrNull extends AnalysisRule {
  PreferWhenOrNull()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'prefer_when_or_null',
    'loading·error가 null만 돌려주면 whenOrNull(data: …)로 쓰세요.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'when') return;
    final named = {
      for (final arg in node.argumentList.arguments)
        if (arg is NamedArgument) arg.name.lexeme: arg.argumentExpression,
    };
    if (!named.containsKey('data')) return;
    if (!_returnsNull(named['loading']) || !_returnsNull(named['error'])) {
      return;
    }
    rule.reportAtNode(node.methodName);
  }

  /// `() => null` 꼴인지
  static bool _returnsNull(Expression? expression) {
    if (expression is! FunctionExpression) return false;
    final body = expression.body;
    return body is ExpressionFunctionBody && body.expression is NullLiteral;
  }
}
