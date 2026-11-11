import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// `MediaQuery.of(context).size`처럼 값 하나만 읽을 때는 `MediaQuery.sizeOf(context)`를 쓴다.
///
/// `of`는 MediaQueryData 전체를 구독해 키보드가 뜨는 것만으로도 위젯을 다시 그린다.
class PreferMediaQueryAspect extends AnalysisRule {
  PreferMediaQueryAspect()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'prefer_media_query_aspect',
    'MediaQuery.{0}(context).{1} 대신 MediaQuery.{2}(context)를 쓰세요. '
        '그 값이 바뀔 때만 다시 그립니다.',
    severity: DiagnosticSeverity.WARNING,
  );

  /// 전용 접근자가 있는 MediaQueryData 속성
  static const aspects = {
    'size',
    'orientation',
    'devicePixelRatio',
    'textScaler',
    'platformBrightness',
    'padding',
    'viewInsets',
    'systemGestureInsets',
    'viewPadding',
    'alwaysUse24HourFormat',
    'accessibleNavigation',
    'invertColors',
    'highContrast',
    'onOffSwitchLabels',
    'disableAnimations',
    'boldText',
    'navigationMode',
    'gestureSettings',
    'displayFeatures',
    'supportsShowingSystemContextMenu',
  };

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addPropertyAccess(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final target = node.target;
    if (target is! MethodInvocation) return;
    final receiver = target.target;
    if (receiver is! SimpleIdentifier || receiver.name != 'MediaQuery') return;
    final method = target.methodName.name;
    if (method != 'of' && method != 'maybeOf') return;
    final property = node.propertyName.name;
    if (!PreferMediaQueryAspect.aspects.contains(property)) return;
    final capitalized = property[0].toUpperCase() + property.substring(1);
    final aspect = method == 'of' ? '${property}Of' : 'maybe${capitalized}Of';
    rule.reportAtNode(node, arguments: [method, property, aspect]);
  }
}
