import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:momeet_lints/src/paths.dart';

/// Flutter(material_ui·cupertino_ui 포함)가 선언한 `show…` 함수·메서드(시트·다이얼로그·알림·날짜 고르기 등)는
/// `lib/shared/ui/` 밖에서 부르지 않는다.
///
/// 손잡이·배경·키보드 여백·로케일·시트 위 알림 처리를 한 곳에서 정하기 위해서다.
/// 새 종류가 필요하면 `lib/shared/ui/`에 `showApp…` 함수를 두고 그것을 부른다.
class NoRawFlutterOverlays extends AnalysisRule {
  NoRawFlutterOverlays()
      : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'no_raw_flutter_overlays',
    'Flutter의 {0}을(를) 직접 부르지 마세요. '
        'lib/shared/ui/의 showApp… 함수를 쓰고, 없으면 거기에 만드세요.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(this, _Visitor(this, context));
  }

  /// Flutter와, Material·Cupertino 위젯을 자기 패키지에 선언하는 material_ui·cupertino_ui
  static bool isFrameworkLibrary(String uri) =>
      uri.startsWith('package:flutter/') ||
      uri.startsWith('package:material_ui/') ||
      uri.startsWith('package:cupertino_ui/');

  /// 공용 함수를 구현하는 `lib/shared/ui/`와 테스트는 검사하지 않는다
  static bool isExempt(String path) =>
      path.startsWith('lib/shared/ui/') || path.startsWith('test/');
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (!name.startsWith('show') || name.length == 4) return;
    final uri = node.methodName.element?.library?.uri.toString() ?? '';
    if (!NoRawFlutterOverlays.isFrameworkLibrary(uri)) return;
    if (NoRawFlutterOverlays.isExempt(packageRelativePath(context))) return;
    rule.reportAtNode(node.methodName, arguments: [name]);
  }
}
