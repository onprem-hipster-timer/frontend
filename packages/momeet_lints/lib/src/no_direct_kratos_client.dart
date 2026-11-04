// ignore_for_file: deprecated_member_use
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

const _authProviderFile = 'auth_provider.dart';

bool _isTestFile(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.contains('/test/') || normalized.startsWith('test/');
}

bool _isAuthLayer(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.endsWith(_authProviderFile) ||
      normalized.contains('/lib/shared/api/kratos/');
}

const _kratosClientChecker = TypeChecker.fromName(
  'KratosClient',
  packageName: 'momeet',
);

/// 인증 계층(lib/shared/api/kratos/, auth_provider.dart) 밖에서 KratosClient를 쓰는 것을 금지합니다.
///
/// 세션 토큰 보관과 인증 상태 전이를 한 곳에서만 하기 위해,
/// 모든 인증 로직은 AuthNotifier(authProvider)를 통해서만 수행되어야 합니다.
class NoDirectKratosClient extends DartLintRule {
  const NoDirectKratosClient() : super(code: _code);

  static const _code = LintCode(
    name: 'no_direct_kratos_client',
    problemMessage: 'KratosClient를 직접 쓰지 마세요. '
        'AuthNotifier(authProvider)를 통해서만 인증 로직을 수행해야 합니다.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (_isAuthLayer(resolver.path)) return;
    if (_isTestFile(resolver.path)) return;

    context.registry.addMethodInvocation((node) {
      final targetType = node.realTarget?.staticType;
      if (targetType != null &&
          _kratosClientChecker.isAssignableFromType(targetType)) {
        reporter.atNode(node, _code);
      }
    });

    context.registry.addNamedType((node) {
      final type = node.type;
      if (type != null && _kratosClientChecker.isExactlyType(type)) {
        reporter.atNode(node, _code);
      }
    });
  }
}
