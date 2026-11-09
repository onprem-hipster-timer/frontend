import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:momeet_lints/src/paths.dart';

/// `AppRoute.xxx.path`를 문자열 보간/결합으로 경로를 조립하는 것을 금지합니다.
///
/// `AppRoute.calendar.path`가 `'/'`인 경우
/// `'${AppRoute.calendar.path}/child'` → `'//child'`처럼 이중 슬래시가 발생합니다.
///
/// 대신 `context.goNamed()` / `context.pushNamed()`을 사용하세요.
///
/// ```dart
/// // BAD
/// context.go('${AppRoute.todo.path}/$id');
///
/// // GOOD
/// context.goNamed(AppRoute.todoGroupDetail.name, pathParameters: {'groupId': id});
/// ```
class NoManualRoutePath extends AnalysisRule {
  NoManualRoutePath()
      : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'no_manual_route_path',
    'AppRoute.path를 직접 결합하지 마세요. '
        'context.goNamed() / pushNamed()를 사용하세요. '
        '경로 직접 결합은 이중 슬래시(//) 버그의 원인이 됩니다.',
    severity: DiagnosticSeverity.WARNING,
  );

  /// router.dart 자체(리다이렉트 로직)는 예외 처리
  static final _routerFilePattern = RegExp(r'/router\.dart$');

  /// 테스트 파일은 예외 처리
  ///
  /// `*_test.dart`는 리다이렉트 로직 검증을 위해 `AppRoute.xxx.path`를
  /// 함수 입력값·expected value로 참조할 뿐, 실제 네비게이션을 하지 않습니다.
  static final _testFilePattern = RegExp(r'_test\.dart$');

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry
      ..addStringInterpolation(this, visitor)
      ..addBinaryExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  bool get _skipped {
    final path = currentPath(context);
    return NoManualRoutePath._routerFilePattern.hasMatch(path) ||
        NoManualRoutePath._testFilePattern.hasMatch(path);
  }

  /// 문자열 보간 내 AppRoute.xxx.path 사용. 예: '${AppRoute.todo.path}/something'
  @override
  void visitStringInterpolation(StringInterpolation node) {
    if (_skipped) return;
    for (final element in node.elements) {
      if (element is InterpolationExpression &&
          _isAppRoutePathAccess(element.expression)) {
        rule.reportAtNode(node);
        return;
      }
    }
  }

  /// + 연산자 결합. 예: AppRoute.todo.path + '/something'
  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (_skipped) return;
    if (node.operator.lexeme != '+') return;
    if (_isAppRoutePathAccess(node.leftOperand) ||
        _isAppRoutePathAccess(node.rightOperand)) {
      rule.reportAtNode(node);
    }
  }

  /// 표현식이 `AppRoute.xxx.path` 패턴인지 확인
  bool _isAppRoutePathAccess(Expression expr) {
    if (expr is PropertyAccess &&
        expr.propertyName.name == 'path' &&
        expr.target != null) {
      final target = expr.target!;
      if (target is PrefixedIdentifier && target.prefix.name == 'AppRoute') {
        return true;
      }
      if (target is PropertyAccess) {
        final deepTarget = target.target;
        if (deepTarget is SimpleIdentifier && deepTarget.name == 'AppRoute') {
          return true;
        }
      }
    }
    if (expr is PrefixedIdentifier && expr.identifier.name == 'path') {
      return expr.prefix.name == 'AppRoute';
    }
    return false;
  }
}
