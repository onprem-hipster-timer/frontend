import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:momeet_lints/src/paths.dart';
import 'package:momeet_lints/src/require_widgetbook_use_case.dart';

/// Provider를 읽는 앱 위젯은 값만 받는 `<위젯>View`를 옆 파일에 둔다.
///
/// 대상 폴더는 `require_widgetbook_use_case`와 같고, 그 안의 공개·비추상
/// Riverpod Consumer 위젯을 본다. 같은 폴더의 `<파일 이름>_view.dart`에
/// `<위젯>View` 클래스가 없으면 알린다.
class RequireWidgetbookView extends AnalysisRule {
  RequireWidgetbookView()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'require_widgetbook_view',
    'Provider를 읽는 {0}의 그리는 부분을 {2}의 {1}로 나누고 '
        'use case는 {1}에 두세요.',
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

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final path = packageRelativePath(context);
    final file = context.currentUnit?.file;
    if (widgetbookGroup(path) == null || file == null) return;
    final stem = file.shortName.replaceFirst(RegExp(r'\.dart$'), '');
    final viewFile = file.parent.getFile('${stem}_view.dart');
    final viewPath =
        '${path.substring(0, path.lastIndexOf('/'))}/'
        '${viewFile.shortName}';
    Set<String>? classes;
    for (final declaration in node.declarations) {
      if (declaration is! ClassDeclaration) continue;
      if (declaration.abstractKeyword != null) continue;
      final name = declaration.namePart.typeName;
      if (name.lexeme.startsWith('_')) continue;
      final element = declaration.declaredFragment?.element;
      if (element == null || !isConsumerWidget(element)) continue;
      final viewName = '${name.lexeme}View';
      classes ??= _classNames(viewFile);
      if (classes.contains(viewName)) continue;
      rule.reportAtToken(name, arguments: [name.lexeme, viewName, viewPath]);
    }
  }

  /// [file]에 선언된 클래스 이름들. 파일이 없거나 읽지 못하면 빈 집합.
  static Set<String> _classNames(File file) {
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
    return {
      for (final d in unit.declarations)
        if (d is ClassDeclaration) d.namePart.typeName.lexeme,
    };
  }
}
