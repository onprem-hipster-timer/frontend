// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

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
class NoManualRoutePath extends DartLintRule {
  const NoManualRoutePath() : super(code: _code);

  static const _code = LintCode(
    name: 'no_manual_route_path',
    problemMessage: 'AppRoute.path를 직접 결합하지 마세요. '
        'context.goNamed() / pushNamed()를 사용하세요. '
        '경로 직접 결합은 이중 슬래시(//) 버그의 원인이 됩니다.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  /// router.dart 자체(리다이렉트 로직)는 예외 처리
  static final _routerFilePattern = RegExp(r'[/\\]router\.dart$');

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    // router.dart 내부의 리다이렉트 로직은 허용
    if (_routerFilePattern.hasMatch(resolver.path)) return;

    // 문자열 보간 내 AppRoute.xxx.path 사용 감지
    // 예: '${AppRoute.todo.path}/something'
    context.registry.addStringInterpolation((node) {
      for (final element in node.elements) {
        if (element is InterpolationExpression) {
          if (_isAppRoutePathAccess(element.expression)) {
            reporter.atNode(node, _code);
            return;
          }
        }
      }
    });

    // 문자열 + 연산자로 결합하는 경우 감지
    // 예: AppRoute.todo.path + '/something'
    context.registry.addBinaryExpression((node) {
      if (node.operator.lexeme != '+') return;

      if (_isAppRoutePathAccess(node.leftOperand) ||
          _isAppRoutePathAccess(node.rightOperand)) {
        reporter.atNode(node, _code);
      }
    });
  }

  /// 표현식이 `AppRoute.xxx.path` 패턴인지 확인
  bool _isAppRoutePathAccess(Expression expr) {
    // PropertyAccess: AppRoute.todo.path
    if (expr is PropertyAccess &&
        expr.propertyName.name == 'path' &&
        expr.target != null) {
      final target = expr.target!;
      // PrefixedIdentifier: AppRoute.todo
      if (target is PrefixedIdentifier && target.prefix.name == 'AppRoute') {
        return true;
      }
      // PropertyAccess chain
      if (target is PropertyAccess) {
        final deepTarget = target.target;
        if (deepTarget is SimpleIdentifier && deepTarget.name == 'AppRoute') {
          return true;
        }
      }
    }

    // PrefixedIdentifier 직접 케이스 (드물지만)
    if (expr is PrefixedIdentifier && expr.identifier.name == 'path') {
      final prefix = expr.prefix;
      if (prefix.name == 'AppRoute') return true;
    }

    return false;
  }
}
