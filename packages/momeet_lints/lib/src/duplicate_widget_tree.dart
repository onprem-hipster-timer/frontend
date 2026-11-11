import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:momeet_lints/src/paths.dart';
import 'package:momeet_lints/src/widget_types.dart';

/// 같은 모양의 위젯 트리가 한 파일에 두 번 이상 나오면 위젯 클래스 하나로 모은다.
///
/// 모양은 위젯·인자 이름·구조로 비교하고, 글자·숫자·변수 이름은 다르더라도 같은 것으로 본다.
/// 작은 조각까지 잡지 않도록 노드 [minNodes]개 이상인 트리만 본다.
class DuplicateWidgetTree extends AnalysisRule {
  DuplicateWidgetTree()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'duplicate_widget_tree',
    '같은 모양의 위젯 트리가 이 파일 {0}줄에도 있습니다. '
        '다른 부분을 인자로 받는 위젯 클래스 하나로 모으세요.',
    severity: DiagnosticSeverity.WARNING,
  );

  /// 이보다 작은 트리는 비교하지 않는다
  static const minNodes = 30;

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addCompilationUnit(this, _Visitor(this, context));
  }

  /// [node]의 모양 지문과 노드 수
  static (String, int) fingerprint(AstNode node) {
    final buffer = StringBuffer();
    var count = 0;
    void walk(SyntacticEntity entity) {
      if (entity is Token) {
        buffer
          ..write(entity.lexeme)
          ..write(' ');
        return;
      }
      final node = entity as AstNode;
      count++;
      buffer
        ..write(node.runtimeType)
        ..write('(');
      if (node is Literal || node is StringInterpolation) {
        buffer.write(')');
        return;
      }
      if (node is SimpleIdentifier) {
        buffer.write(_keepsName(node) ? node.name : '#');
        buffer.write(')');
        return;
      }
      node.childEntities.forEach(walk);
      buffer.write(')');
    }

    walk(node);
    return (buffer.toString(), count);
  }

  /// 위젯·인자·메서드 이름은 모양의 일부, 그 밖의 변수·속성 이름은 값으로 본다
  static bool _keepsName(SimpleIdentifier node) {
    final parent = node.parent;
    return parent is NamedType ||
        parent is Label ||
        parent is ConstructorName ||
        (parent is MethodInvocation && parent.methodName == node);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    if (!packageRelativePath(context).startsWith('lib/')) return;
    final collector = _WidgetCreationCollector();
    node.accept(collector);
    final groups = <String, List<InstanceCreationExpression>>{};
    final sizes = <String, int>{};
    for (final creation in collector.creations) {
      final (print, size) = DuplicateWidgetTree.fingerprint(creation);
      if (size < DuplicateWidgetTree.minNodes) continue;
      groups.putIfAbsent(print, () => []).add(creation);
      sizes[print] = size;
    }
    // 큰 트리부터 보고하고, 보고한 트리 안쪽의 겹치는 조각은 다시 보고하지 않는다
    final reported = <InstanceCreationExpression>[];
    final prints = groups.keys.where((p) => groups[p]!.length >= 2).toList()
      ..sort((a, b) => sizes[b]!.compareTo(sizes[a]!));
    final lineInfo = node.lineInfo;
    for (final print in prints) {
      final members = groups[print]!
          .where((m) => !reported.any((r) => _contains(r, m)))
          .toList();
      if (members.length < 2) continue;
      for (final member in members) {
        final other = members.firstWhere((m) => m != member);
        final line = lineInfo.getLocation(other.offset).lineNumber;
        rule.reportAtNode(member.constructorName, arguments: ['$line']);
      }
      reported.addAll(members);
    }
  }

  static bool _contains(AstNode outer, AstNode inner) =>
      outer != inner && inner.offset >= outer.offset && inner.end <= outer.end;
}

/// 파일 안의 위젯 생성식을 모두 모은다
class _WidgetCreationCollector extends RecursiveAstVisitor<void> {
  final creations = <InstanceCreationExpression>[];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (isWidgetType(node.staticType)) creations.add(node);
    super.visitInstanceCreationExpression(node);
  }
}
