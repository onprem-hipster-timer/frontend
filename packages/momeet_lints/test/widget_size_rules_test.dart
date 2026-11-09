import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:momeet_lints/src/widget_size_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MaxWidgetClassLinesTest);
    defineReflectiveTests(MaxBuildLinesTest);
    defineReflectiveTests(MaxFileLinesTest);
  });
}

/// 몸통이 [bodyLines]줄인 StatelessWidget. 클래스 전체는 bodyLines + 5줄.
String _widget(String name, int bodyLines) => '''
class $name extends StatelessWidget {
  const $name({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox();
${List.filled(bodyLines, '  // .').join('\n')}
}
''';

/// build가 [lines]줄인 위젯.
String _buildOf(String name, int lines) => '''
class $name extends StatelessWidget {
  const $name({super.key});
  @override
  Widget build(BuildContext context) {
${List.filled(lines - 3, '    // .').join('\n')}
    return const SizedBox();
  }
}
''';

const _import = "import 'package:flutter/widgets.dart';\n\n";

@reflectiveTest
class MaxWidgetClassLinesTest extends AnalysisRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = MaxWidgetClassLines();
    super.setUp();
  }

  void _baseline(String text) =>
      newFile('$testPackageRootPath/lint_baseline.txt', text);

  Future<void> test_atLimit_ok() async {
    await assertNoDiagnostics(_import + _widget('Foo', 195));
  }

  Future<void> test_overLimit_reported() async {
    final content = _import + _widget('Foo', 196);
    await assertDiagnostics(content, [
      lintAt(this, content, 'Foo', messageContainsAll: ['201', '200']),
    ]);
  }

  Future<void> test_stateClass_counted() async {
    final content = '''${_import}class Foo extends StatefulWidget {
  const Foo({super.key});
  @override
  State<Foo> createState() => _FooState();
}

class _FooState extends State<Foo> {
  @override
  Widget build(BuildContext context) => const SizedBox();
${List.filled(198, '  // .').join('\n')}
}
''';
    await assertDiagnostics(
        content, [lintAt(this, content, '_FooState', occurrence: 1)]);
  }

  Future<void> test_plainClass_ignored() async {
    await assertNoDiagnostics('''class Plain {
${List.filled(300, '  // .').join('\n')}
}
''');
  }

  Future<void> test_outsideLib_ignored() async {
    final path = '$testPackageRootPath/test/foo_test.dart';
    newFile(path, _import + _widget('Foo', 300));
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_baseline_allowsUpToRecorded() async {
    _baseline('max_widget_class_lines lib/test.dart Foo 305\n');
    await assertNoDiagnostics(_import + _widget('Foo', 300));
  }

  Future<void> test_baseline_growthReported() async {
    _baseline('max_widget_class_lines lib/test.dart Foo 305\n');
    final content = _import + _widget('Foo', 301);
    await assertDiagnostics(content, [
      lintAt(this, content, 'Foo', messageContainsAll: ['306', '305']),
    ]);
  }

  Future<void> test_baseline_otherClassNotCovered() async {
    _baseline('max_widget_class_lines lib/test.dart Bar 305\n');
    final content = _import + _widget('Foo', 300);
    await assertDiagnostics(content, [
      lintAt(
        this,
        content,
        'import',
        name: 'max_widget_class_lines_baseline_stale',
      ),
      lintAt(this, content, 'Foo'),
    ]);
  }

  Future<void> test_baseline_staleWhenFixed() async {
    _baseline('max_widget_class_lines lib/test.dart Foo 305\n');
    final content = _import + _widget('Foo', 10);
    await assertDiagnostics(content, [
      lintAt(
        this,
        content,
        'import',
        name: 'max_widget_class_lines_baseline_stale',
        messageContainsAll: ['Foo'],
      ),
    ]);
  }

  Future<void> test_baseline_commentsAndBlankLinesIgnored() async {
    _baseline(
        '# 규칙 경로 대상 줄수\n\nmax_widget_class_lines lib/test.dart Foo 305\n');
    await assertNoDiagnostics(_import + _widget('Foo', 300));
  }
}

@reflectiveTest
class MaxBuildLinesTest extends AnalysisRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = MaxBuildLines();
    super.setUp();
  }

  Future<void> test_atLimit_ok() async {
    await assertNoDiagnostics(_import + _buildOf('Foo', 80));
  }

  Future<void> test_overLimit_reported() async {
    final content = _import + _buildOf('Foo', 81);
    await assertDiagnostics(content, [
      lintAt(this, content, 'build', messageContainsAll: ['Foo.build', '81']),
    ]);
  }

  Future<void> test_baseline_bySymbol() async {
    newFile(
      '$testPackageRootPath/lint_baseline.txt',
      'max_build_lines lib/test.dart Foo.build 90\n',
    );
    await assertNoDiagnostics(_import + _buildOf('Foo', 90));
  }
}

@reflectiveTest
class MaxFileLinesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = MaxFileLines();
    super.setUp();
  }

  String _lines(int n) =>
      '${List.filled(n - 1, '// .').join('\n')}\nint a = 0;\n';

  Future<void> test_atLimit_ok() async {
    await assertNoDiagnostics(_lines(400));
  }

  Future<void> test_overLimit_reported() async {
    final content = _lines(401);
    await assertDiagnostics(content, [
      lintAt(this, content, 'int', messageContainsAll: ['401', '400']),
    ]);
  }

  Future<void> test_noTrailingNewline_counted() async {
    final content = _lines(401).trimRight();
    await assertDiagnostics(content, [lintAt(this, content, 'int')]);
  }

  Future<void> test_baseline_allows() async {
    newFile(
      '$testPackageRootPath/lint_baseline.txt',
      'max_file_lines lib/test.dart - 420\n',
    );
    await assertNoDiagnostics(_lines(420));
  }
}
