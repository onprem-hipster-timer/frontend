import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:momeet_lints/src/paths.dart';
import 'package:momeet_lints/src/widget_types.dart';

/// `lib/` 파일 하나에는 공개 위젯 클래스를 하나만 둔다.
///
/// 한 파일에 공개 위젯이 쌓이면 화면 하나가 여러 위젯의 집이 되고, 찾기·나누기가 어려워진다.
/// 함께 쓰는 조각은 비공개(`_Foo`)로 두거나 자기 파일로 옮긴다.
class OnePublicWidgetPerFile extends AnalysisRule {
  OnePublicWidgetPerFile()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'one_public_widget_per_file',
    '이 파일에는 이미 공개 위젯 {0}이(가) 있습니다. '
        '{1}은(는) 자기 파일로 옮기거나 비공개로 두세요.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addCompilationUnit(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    if (!packageRelativePath(context).startsWith('lib/')) return;
    String? first;
    for (final declaration in node.declarations) {
      if (declaration is! ClassDeclaration) continue;
      final name = declaration.namePart.typeName;
      if (name.lexeme.startsWith('_')) continue;
      if (!isWidgetClass(declaration.declaredFragment?.element)) continue;
      if (first == null) {
        first = name.lexeme;
        continue;
      }
      rule.reportAtToken(name, arguments: [first, name.lexeme]);
    }
  }
}
