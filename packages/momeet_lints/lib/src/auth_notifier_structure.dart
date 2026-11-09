import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:momeet_lints/src/paths.dart';

const _authProviderFile = 'auth_provider.dart';

const _actionMethodNames = {
  'signInWithEmail',
  'signUpWithEmail',
  'sendVerificationCode',
  'verifyEmail',
  'signOut',
  'sendRecoveryCode',
  'verifyRecoveryCode',
  'completeRecovery',
  'startGoogleSignIn',
  'completeGoogleSignIn',
  'googleAccountLinkEmail',
  'completeGoogleAccountLink',
};

// ============================================================
// 액션 메서드에서 AuthStatus.loading() 금지
// ============================================================

/// AuthNotifier의 액션 메서드에서 AuthStatus.loading()을 사용하는 것을 금지합니다.
class AuthActionNoLoadingState extends AnalysisRule {
  AuthActionNoLoadingState()
      : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'auth_action_no_loading_state',
    '액션 메서드에서 AuthStatus.loading()을 사용하면 안 됩니다. '
        'loading 상태는 앱 초기화(build) 전용이며, '
        '사용 시 라우터가 /loading으로 리다이렉트하여 무한 로딩 버그가 발생합니다.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _LoadingVisitor(this, context));
  }
}

class _LoadingVisitor extends SimpleAstVisitor<void> {
  _LoadingVisitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    for (final body in _actionBodies(node, context)) {
      final loadingChecker = _LoadingUsageChecker();
      body.block.accept(loadingChecker);
      loadingChecker.violations.forEach(rule.reportAtNode);
    }
  }
}

// ============================================================
// 예외 처리 블록에서 AuthErrorType.classify 강제
// ============================================================

/// AuthNotifier 액션 메서드의 모든 예외 처리 블록(catch / on-only)에서
/// AuthErrorType.classify를 사용하도록 강제합니다.
class AuthCatchRequireClassify extends AnalysisRule {
  AuthCatchRequireClassify()
      : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'auth_catch_require_classify',
    '예외 처리 블록에서 AuthErrorType.classify를 사용해야 합니다. '
        '직접 에러 메시지를 파싱하는 것은 금지됩니다.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _ClassifyVisitor(this, context));
  }
}

class _ClassifyVisitor extends SimpleAstVisitor<void> {
  _ClassifyVisitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    for (final body in _actionBodies(node, context)) {
      final catchFinder = _CatchBlockFinder();
      body.block.accept(catchFinder);
      for (final catchClause in catchFinder.catchClauses) {
        final classifyChecker = _ClassifyUsageChecker();
        catchClause.accept(classifyChecker);
        if (!classifyChecker.hasClassify) rule.reportAtNode(catchClause);
      }
    }
  }
}

/// AuthNotifier 액션 메서드들의 블록 본문
Iterable<BlockFunctionBody> _actionBodies(
  ClassDeclaration node,
  RuleContext context,
) sync* {
  if (!currentPath(context).endsWith(_authProviderFile)) return;
  if (node.namePart.typeName.lexeme != 'AuthNotifier') return;
  for (final member in node.body.members) {
    if (member is! MethodDeclaration) continue;
    if (!_actionMethodNames.contains(member.name.lexeme)) continue;
    final body = member.body;
    if (body is BlockFunctionBody) yield body;
  }
}

// ============================================================
// AST Visitor 헬퍼
// ============================================================

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
