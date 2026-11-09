import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:momeet_lints/src/paths.dart';

/// `lib/shared/ui/`(디자인 시스템)는 기능 코드·상태 관리·라우팅에 기대지 않는다.
class SharedUiImportBoundary extends AnalysisRule {
  SharedUiImportBoundary()
      : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'shared_ui_import_boundary',
    'lib/shared/ui/는 {0}을(를) 가져오지 않습니다. '
        '필요한 값은 생성자 인자로 받으세요.',
    severity: DiagnosticSeverity.WARNING,
  );

  static const _forbiddenPackages = {
    'flutter_riverpod',
    'hooks_riverpod',
    'riverpod',
    'riverpod_annotation',
    'go_router',
  };

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry
      ..addImportDirective(this, visitor)
      ..addExportDirective(this, visitor);
  }

  /// [uri]가 금지 대상이면 그 이름, 아니면 null.
  static String? forbidden(String uri) {
    final match = RegExp(r'^package:([^/]+)/(.*)$').firstMatch(uri);
    if (match == null) return uri.contains('features/') ? 'features' : null;
    final package = match.group(1)!;
    if (_forbiddenPackages.contains(package)) return package;
    if (match.group(2)!.startsWith('features/')) return 'features';
    return null;
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) => _check(
        node,
        node.libraryImport?.importedLibrary?.uri.toString(),
      );

  @override
  void visitExportDirective(ExportDirective node) => _check(
        node,
        node.libraryExport?.exportedLibrary?.uri.toString(),
      );

  void _check(NamespaceDirective node, String? resolved) {
    if (!packageRelativePath(context).startsWith('lib/shared/ui/')) return;
    final name = SharedUiImportBoundary.forbidden(
      resolved ?? node.uri.stringValue ?? '',
    );
    if (name != null) rule.reportAtNode(node.uri, arguments: [name]);
  }
}
