import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:momeet_lints/src/paths.dart';

/// 인증 계층(lib/shared/api/kratos/, auth_provider.dart) 밖에서 KratosClient를 쓰는 것을 금지합니다.
///
/// 세션 토큰 보관과 인증 상태 전이를 한 곳에서만 하기 위해,
/// 모든 인증 로직은 AuthNotifier(authProvider)를 통해서만 수행되어야 합니다.
class NoDirectKratosClient extends AnalysisRule {
  NoDirectKratosClient()
      : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'no_direct_kratos_client',
    'KratosClient를 직접 쓰지 마세요. '
        'AuthNotifier(authProvider)를 통해서만 인증 로직을 수행해야 합니다.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry
      ..addMethodInvocation(this, visitor)
      ..addNamedType(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  /// 인증 계층과 테스트는 KratosClient를 직접 다룬다.
  bool get _skipped {
    final path = packageRelativePath(context);
    return path.endsWith('auth_provider.dart') ||
        path.startsWith('lib/shared/api/kratos/') ||
        isTestFile(context);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_skipped) return;
    final type = node.realTarget?.staticType;
    if (type is InterfaceType &&
        (_isKratosClient(type) || type.allSupertypes.any(_isKratosClient))) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitNamedType(NamedType node) {
    if (_skipped) return;
    final type = node.type;
    if (type is InterfaceType && _isKratosClient(type)) {
      rule.reportAtNode(node);
    }
  }

  static bool _isKratosClient(InterfaceType type) {
    final element = type.element;
    return element.name == 'KratosClient' &&
        (element.library.uri.toString().startsWith('package:momeet/'));
  }
}
