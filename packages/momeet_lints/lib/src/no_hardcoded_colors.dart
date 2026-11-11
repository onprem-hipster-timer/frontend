import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:momeet_lints/src/paths.dart';

/// Material 이름 색(`Colors.blue` 등)은 `lib/shared/ui/theme/` 밖에서 쓰지 않는다.
///
/// 화면 색은 ColorScheme 역할이나 AppColors 토큰에서 가져와야 다크 모드와 브랜드 색을 따른다.
/// 투명과 흰·검정·회색은 임의의 배경 위 대비나 중립 표시처럼 테마와 무관하게 쓰이므로 허용한다.
class NoHardcodedColors extends AnalysisRule {
  NoHardcodedColors()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'no_hardcoded_colors',
    'Colors.{0} 대신 Theme.of(context).colorScheme 역할이나 '
        'AppColors 토큰을 쓰세요.',
    severity: DiagnosticSeverity.WARNING,
  );

  /// 테마와 무관하게 써도 되는 이름
  static const allowed = {'transparent', 'white', 'black', 'black87', 'grey'};

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addPrefixedIdentifier(this, _Visitor(this, context));
  }

  /// 토큰을 정의하는 테마 폴더와 테스트는 검사하지 않는다
  static bool isExempt(String path) =>
      path.startsWith('lib/shared/ui/theme/') || path.startsWith('test/');
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name != 'Colors') return;
    // 이름만 같은 변수가 아니라 Colors 클래스여야 한다
    if (node.prefix.element is! ClassElement) return;
    final name = node.identifier.name;
    if (NoHardcodedColors.allowed.contains(name)) return;
    if (NoHardcodedColors.isExempt(packageRelativePath(context))) return;
    rule.reportAtNode(node, arguments: [name]);
  }
}
