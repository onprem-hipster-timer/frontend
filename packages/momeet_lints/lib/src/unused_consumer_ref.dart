import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// `ref`를 쓰지 않는 ConsumerWidget·ConsumerState는 StatelessWidget·State로 둔다.
///
/// Riverpod 위젯은 구독 관리 비용이 있고, 읽는 사람이 상태 의존이 있다고 오해한다.
class UnusedConsumerRef extends AnalysisRule {
  UnusedConsumerRef()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'unused_consumer_ref',
    '{0}은(는) ref를 쓰지 않습니다. {1}(으)로 바꾸세요.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final superclass = node.extendsClause?.superclass.name.lexeme;
    final className = node.namePart.typeName.lexeme;
    switch (superclass) {
      case 'ConsumerWidget':
        final build = node.body.members
            .whereType<MethodDeclaration>()
            .where((m) => m.name.lexeme == 'build')
            .firstOrNull;
        final params = build?.parameters?.parameters;
        if (build == null || params == null || params.length < 2) return;
        final refName = params[1].name?.lexeme;
        if (refName == null) return;
        if (_uses(build.body, refName)) return;
        rule.reportAtToken(
          node.namePart.typeName,
          arguments: [className, 'StatelessWidget'],
        );
      case 'ConsumerState':
        if (_uses(node.body, 'ref')) return;
        rule.reportAtToken(
          node.namePart.typeName,
          arguments: [className, 'State'],
        );
    }
  }

  /// [node] 안에서 [name]을 값으로 읽는 곳이 있는지
  static bool _uses(AstNode node, String name) {
    final finder = _IdentifierFinder(name);
    node.accept(finder);
    return finder.found;
  }
}

class _IdentifierFinder extends RecursiveAstVisitor<void> {
  _IdentifierFinder(this.name);

  final String name;
  bool found = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name && !node.inDeclarationContext()) found = true;
  }
}
