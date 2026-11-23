import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:momeet_lints/src/paths.dart';
import 'package:momeet_lints/src/widget_types.dart';

/// 값만 받는 앱 위젯에는 Widgetbook use case를 둔다.
///
/// 대상은 `lib/shared/ui/`, `lib/shared/widgets/`, `lib/features/<기능>/presentation/widgets/`
/// 아래의 공개·비추상 위젯이다. InheritedWidget과 Riverpod Consumer 위젯은 빼고 본다.
/// use case는 `widgetbook/lib/<shared 또는 기능>/<같은 파일 이름>`에
/// `@widgetbook.UseCase(type: 위젯)`으로 둔다(하위 폴더는 펼친다).
class RequireWidgetbookUseCase extends AnalysisRule {
  RequireWidgetbookUseCase()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'require_widgetbook_use_case',
    '{0}의 use case가 없습니다. '
        '{1}에 @widgetbook.UseCase(type: {0})를 단 함수를 두세요.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addCompilationUnit(this, _Visitor(this, context));
  }
}

/// [path](패키지 상대 경로)의 use case가 있을 `widgetbook/lib/` 아래 묶음 이름.
/// 대상 폴더 밖이면 null.
String? _group(String path) {
  final parts = path.split('/');
  if (parts.length > 3 &&
      parts[0] == 'lib' &&
      parts[1] == 'shared' &&
      (parts[2] == 'ui' || parts[2] == 'widgets')) {
    return 'shared';
  }
  if (parts.length > 5 &&
      parts[0] == 'lib' &&
      parts[1] == 'features' &&
      parts[3] == 'presentation' &&
      parts[4] == 'widgets') {
    return parts[2];
  }
  return null;
}

bool _isConsumerWidget(InterfaceElement element) => element.allSupertypes.any(
  (t) =>
      t.element.name == 'ConsumerWidget' ||
      t.element.name == 'ConsumerStatefulWidget',
);

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final path = packageRelativePath(context);
    final group = _group(path);
    final root = context.package?.root;
    if (group == null || root == null) return;
    final fileName = path.split('/').last;
    final useCasePath = 'widgetbook/lib/$group/$fileName';
    Set<String>? types;
    for (final declaration in node.declarations) {
      if (declaration is! ClassDeclaration) continue;
      if (declaration.abstractKeyword != null) continue;
      final name = declaration.namePart.typeName;
      if (name.lexeme.startsWith('_')) continue;
      final element = declaration.declaredFragment?.element;
      if (element == null || !isBuiltWidgetType(element.thisType)) continue;
      if (_isConsumerWidget(element)) continue;
      types ??= _useCaseTypes(root.getFile(useCasePath));
      if (types.contains(name.lexeme)) continue;
      rule.reportAtToken(name, arguments: [name.lexeme, useCasePath]);
    }
  }

  /// [file]의 `@UseCase(type: X)`에 적힌 X들. 파일이 없거나 읽지 못하면 빈 집합.
  static Set<String> _useCaseTypes(File file) {
    if (!file.exists) return const {};
    final CompilationUnit unit;
    try {
      unit = parseString(
        content: file.readAsStringSync(),
        throwIfDiagnostics: false,
      ).unit;
    } on Object {
      return const {};
    }
    final finder = _UseCaseFinder();
    unit.accept(finder);
    return finder.types;
  }
}

class _UseCaseFinder extends RecursiveAstVisitor<void> {
  final types = <String>{};

  @override
  void visitAnnotation(Annotation node) {
    final name = node.name;
    final simple = name is PrefixedIdentifier ? name.identifier : name;
    if (simple is SimpleIdentifier && simple.name == 'UseCase') {
      for (final arg in node.arguments?.arguments ?? const <Argument>[]) {
        if (arg is! NamedArgument || arg.name.lexeme != 'type') continue;
        final value = arg.argumentExpression;
        if (value is Identifier) types.add(value.name.split('.').last);
      }
    }
    super.visitAnnotation(node);
  }
}
