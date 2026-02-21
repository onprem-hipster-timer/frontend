import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
// ignore_for_file: deprecated_member_use
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

const _authProviderFile = 'auth_provider.dart';

const _buildRequiredMethods = ['build'];

const _actionMethodNames = {
  'signInWithEmail',
  'signUpWithEmail',
  'signOut',
  'resetPassword',
  'updatePassword',
};

const _classifyRequiredMethodNames = _actionMethodNames;

/// 수동 토큰 갱신 메서드 금지 패턴.
/// Supabase가 토큰 갱신을 자동 처리하므로 수동 구현은 불필요하고 위험합니다.
const _forbiddenTokenRefreshPatterns = {
  'refreshAccessToken',
  'refreshToken',
  'refreshSession',
  'renewToken',
  'renewAccessToken',
};

// ============================================================
// Rule 2: AuthNotifier.build() 필수 구조 검증
// ============================================================

/// AuthNotifier.build() 메서드가 합의된 아키텍처를 따르는지 검증합니다.
///
/// 필수 조건:
///   1. onAuthStateChange 스트림을 .listen()으로 구독
///   2. ref.onDispose 콜백 내에서 .cancel() 호출
///   3. .currentSession 동기 체크
class AuthNotifierBuildStructure extends DartLintRule {
  const AuthNotifierBuildStructure() : super(code: _code);

  static const _code = LintCode(
    name: 'auth_notifier_build_structure',
    problemMessage: 'AuthNotifier.build()에 필수 아키텍처 요소가 누락되었습니다. '
        'onAuthStateChange.listen(), ref.onDispose(..cancel()), '
        'currentSession 체크가 모두 필요합니다.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!resolver.path.endsWith(_authProviderFile)) return;

    context.registry.addClassDeclaration((node) {
      if (node.name.lexeme != 'AuthNotifier') return;

      final buildMethod = _findMethod(node, 'build');
      if (buildMethod == null) return;

      final body = buildMethod.body;
      if (body is! BlockFunctionBody) return;

      final checker = _BuildStructureChecker();
      body.block.accept(checker);

      final missing = <String>[];
      if (!checker.hasOnAuthStateChange) {
        missing.add('onAuthStateChange 구독');
      }
      if (!checker.hasListen) {
        missing.add('.listen() 호출');
      }
      if (!checker.hasOnDispose) {
        missing.add('ref.onDispose() 호출');
      }
      if (!checker.hasCancelInDispose && checker.hasOnDispose) {
        missing.add('onDispose 내 .cancel() 호출');
      }
      if (!checker.hasCurrentSession) {
        missing.add('.currentSession 체크');
      }

      if (missing.isNotEmpty) {
        reporter.atToken(
          node.name,
          LintCode(
            name: 'auth_notifier_build_structure',
            problemMessage:
                'AuthNotifier.build()에 누락된 요소: ${missing.join(", ")}',
            errorSeverity: ErrorSeverity.ERROR,
          ),
        );
      }
    });
  }
}

// ============================================================
// Rule 3: 액션 메서드에서 state 직접 변경 금지
// ============================================================

/// AuthNotifier의 액션 메서드에서 state를 직접 변경하거나
/// AuthStatus.loading()을 사용하는 것을 금지합니다.
class AuthActionNoStateMutation extends DartLintRule {
  const AuthActionNoStateMutation() : super(code: _stateCode);

  static const _stateCode = LintCode(
    name: 'auth_action_no_state_mutation',
    problemMessage: '액션 메서드에서 state를 직접 변경하면 안 됩니다. '
        '인증 상태 전이는 오직 onAuthStateChange 스트림 리스너에서만 수행됩니다.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  static const _loadingCode = LintCode(
    name: 'auth_action_no_loading_state',
    problemMessage: '액션 메서드에서 AuthStatus.loading()을 사용하면 안 됩니다. '
        'loading 상태는 앱 초기화(build) 전용이며, '
        '사용 시 라우터가 /loading으로 리다이렉트하여 무한 로딩 버그가 발생합니다.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!resolver.path.endsWith(_authProviderFile)) return;

    context.registry.addClassDeclaration((node) {
      if (node.name.lexeme != 'AuthNotifier') return;

      for (final member in node.members) {
        if (member is! MethodDeclaration) continue;
        final name = member.name.lexeme;
        if (_buildRequiredMethods.contains(name)) continue;
        if (!_actionMethodNames.contains(name)) continue;

        final body = member.body;
        if (body is! BlockFunctionBody) continue;

        // state 직접 변경 감지
        final stateChecker = _StateAssignmentChecker();
        body.block.accept(stateChecker);
        for (final assignment in stateChecker.violations) {
          reporter.atNode(assignment, _stateCode);
        }

        // AuthStatus.loading() 사용 감지
        final loadingChecker = _LoadingUsageChecker();
        body.block.accept(loadingChecker);
        for (final usage in loadingChecker.violations) {
          reporter.atNode(usage, _loadingCode);
        }
      }
    });
  }
}

// ============================================================
// Rule 4: 예외 처리 블록에서 AuthErrorType.classify 강제
// ============================================================

/// AuthNotifier 액션 메서드의 모든 예외 처리 블록(catch / on-only)에서
/// AuthErrorType.classify를 사용하도록 강제합니다.
class AuthCatchRequireClassify extends DartLintRule {
  const AuthCatchRequireClassify() : super(code: _code);

  static const _code = LintCode(
    name: 'auth_catch_require_classify',
    problemMessage: '예외 처리 블록에서 AuthErrorType.classify를 사용해야 합니다. '
        '직접 에러 메시지를 파싱하는 것은 금지됩니다.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!resolver.path.endsWith(_authProviderFile)) return;

    context.registry.addClassDeclaration((node) {
      if (node.name.lexeme != 'AuthNotifier') return;

      for (final member in node.members) {
        if (member is! MethodDeclaration) continue;
        final name = member.name.lexeme;
        if (_buildRequiredMethods.contains(name)) continue;
        if (!_classifyRequiredMethodNames.contains(name)) continue;

        final body = member.body;
        if (body is! BlockFunctionBody) continue;

        final catchFinder = _CatchBlockFinder();
        body.block.accept(catchFinder);

        for (final catchClause in catchFinder.catchClauses) {
          final classifyChecker = _ClassifyUsageChecker();
          catchClause.accept(classifyChecker);

          if (!classifyChecker.hasClassify) {
            reporter.atNode(catchClause, _code);
          }
        }
      }
    });
  }
}

// ============================================================
// Rule 5: 수동 토큰 갱신 메서드 금지
// ============================================================

/// AuthNotifier에 수동 토큰 갱신 메서드를 추가하는 것을 금지합니다.
///
/// Supabase GoTrueClient가 토큰 갱신을 자동 처리하며,
/// onAuthStateChange 스트림의 tokenRefreshed 이벤트로 상태가 갱신됩니다.
/// 수동 구현은 불필요하고, 이중 실패(갱신 실패 + signOut 실패) 같은
/// 복잡한 에러 시나리오를 유발합니다.
class NoManualTokenRefresh extends DartLintRule {
  const NoManualTokenRefresh() : super(code: _code);

  static const _code = LintCode(
    name: 'no_manual_token_refresh',
    problemMessage: 'AuthNotifier에 수동 토큰 갱신 메서드를 추가하지 마세요. '
        'Supabase가 토큰 갱신을 자동 처리하며, '
        'onAuthStateChange의 tokenRefreshed 이벤트로 상태가 갱신됩니다.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!resolver.path.endsWith(_authProviderFile)) return;

    context.registry.addClassDeclaration((node) {
      if (node.name.lexeme != 'AuthNotifier') return;

      for (final member in node.members) {
        if (member is! MethodDeclaration) continue;
        final name = member.name.lexeme.toLowerCase();
        for (final pattern in _forbiddenTokenRefreshPatterns) {
          if (name == pattern.toLowerCase()) {
            reporter.atToken(member.name, _code);
            break;
          }
        }
      }
    });
  }
}

// ============================================================
// AST Visitor 헬퍼
// ============================================================

MethodDeclaration? _findMethod(ClassDeclaration cls, String name) {
  for (final member in cls.members) {
    if (member is MethodDeclaration && member.name.lexeme == name) {
      return member;
    }
  }
  return null;
}

/// build() 메서드의 필수 구조를 확인하는 방문자
class _BuildStructureChecker extends RecursiveAstVisitor<void> {
  bool hasOnAuthStateChange = false;
  bool hasListen = false;
  bool hasOnDispose = false;
  bool hasCancelInDispose = false;
  bool hasCurrentSession = false;

  bool _insideOnDispose = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;

    if (name == 'listen') hasListen = true;
    if (name == 'onDispose') {
      hasOnDispose = true;
      _insideOnDispose = true;
      super.visitMethodInvocation(node);
      _insideOnDispose = false;
      return;
    }
    if (name == 'cancel' && _insideOnDispose) {
      hasCancelInDispose = true;
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final name = node.propertyName.name;
    if (name == 'onAuthStateChange') hasOnAuthStateChange = true;
    if (name == 'currentSession') hasCurrentSession = true;
    super.visitPropertyAccess(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    final name = node.identifier.name;
    if (name == 'onAuthStateChange') hasOnAuthStateChange = true;
    if (name == 'currentSession') hasCurrentSession = true;
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // ref.onDispose(sub.cancel) tear-off 패턴 지원
    if (node.name == 'cancel' && _insideOnDispose) {
      hasCancelInDispose = true;
    }
    super.visitSimpleIdentifier(node);
  }
}

/// 액션 메서드 내 state 직접 할당을 찾는 방문자
class _StateAssignmentChecker extends RecursiveAstVisitor<void> {
  final List<AstNode> violations = [];

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final lhs = node.leftHandSide;
    if (lhs is SimpleIdentifier && lhs.name == 'state') {
      violations.add(node);
    }
    super.visitAssignmentExpression(node);
  }
}

/// AuthStatus.loading() 사용을 찾는 방문자
class _LoadingUsageChecker extends RecursiveAstVisitor<void> {
  final List<AstNode> violations = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'loading') {
      final target = node.target;
      if (target is SimpleIdentifier && target.name == 'AuthStatus') {
        violations.add(node);
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final name = node.constructorName.toString();
    if (name.contains('AuthStatus.loading')) {
      violations.add(node);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name == 'AuthStatus' && node.identifier.name == 'loading') {
      violations.add(node);
    }
    super.visitPrefixedIdentifier(node);
  }
}

/// try-catch 문의 모든 catch 절을 수집하는 방문자
class _CatchBlockFinder extends RecursiveAstVisitor<void> {
  final List<CatchClause> catchClauses = [];

  @override
  void visitTryStatement(TryStatement node) {
    catchClauses.addAll(node.catchClauses);
    super.visitTryStatement(node);
  }
}

/// catch 블록 내 AuthErrorType.classify 호출 여부를 확인하는 방문자
class _ClassifyUsageChecker extends RecursiveAstVisitor<void> {
  bool hasClassify = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'classify') {
      final target = node.target;
      if (target is SimpleIdentifier && target.name == 'AuthErrorType') {
        hasClassify = true;
      }
    }
    super.visitMethodInvocation(node);
  }
}
