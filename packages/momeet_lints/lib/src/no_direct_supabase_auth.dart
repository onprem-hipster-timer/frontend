// ignore_for_file: deprecated_member_use
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

const _authProviderFile = 'auth_provider.dart';

bool _isTestFile(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.contains('/test/') || normalized.startsWith('test/');
}

const _goTrueChecker = TypeChecker.fromName(
  'GoTrueClient',
  packageName: 'gotrue',
);

/// auth_provider.dart 외부에서 Supabase 인증 API를 직접 호출하거나
/// GoTrueClient 타입을 참조하는 것을 금지합니다.
///
/// 모든 인증 로직은 AuthNotifier를 통해서만 수행되어야 합니다.
class NoDirectSupabaseAuth extends DartLintRule {
  const NoDirectSupabaseAuth() : super(code: _code);

  static const _code = LintCode(
    name: 'no_direct_supabase_auth',
    problemMessage: 'Supabase 인증 API를 직접 호출하지 마세요. '
        'AuthNotifier(authProvider)를 통해서만 인증 로직을 수행해야 합니다.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (resolver.path.endsWith(_authProviderFile)) return;
    if (_isTestFile(resolver.path)) return;

    context.registry.addMethodInvocation((node) {
      final targetType = node.realTarget?.staticType;
      if (targetType != null &&
          _goTrueChecker.isAssignableFromType(targetType)) {
        reporter.atNode(node, _code);
      }
    });

    context.registry.addPropertyAccess((node) {
      final targetType = node.realTarget.staticType;
      if (targetType != null &&
          _goTrueChecker.isAssignableFromType(targetType)) {
        reporter.atNode(node, _code);
      }
    });

    context.registry.addNamedType((node) {
      final type = node.type;
      if (type != null && _goTrueChecker.isExactlyType(type)) {
        reporter.atNode(node, _code);
      }
    });
  }
}
