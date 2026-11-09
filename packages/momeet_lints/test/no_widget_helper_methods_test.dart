import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:momeet_lints/src/no_widget_helper_methods.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoWidgetHelperMethodsTest);
  });
}

@reflectiveTest
class NoWidgetHelperMethodsTest extends AnalysisRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = NoWidgetHelperMethods();
    super.setUp();
  }

  Future<void> test_helperMethod_reported() async {
    const content = '''
import 'package:flutter/widgets.dart';

class Foo extends StatelessWidget {
  const Foo({super.key});

  @override
  Widget build(BuildContext context) => _row();

  Widget _row() => const SizedBox();
}
''';
    await assertDiagnostics(
        content, [lintAt(this, content, '_row', occurrence: 1)]);
  }

  Future<void> test_overrideAndBuild_ok() async {
    await assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

abstract class Base {
  Widget page();
}

class Impl extends Base {
  @override
  Widget page() => const SizedBox();
}

class Foo extends StatelessWidget {
  const Foo({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
  }

  Future<void> test_getterAndSubtype_reported() async {
    const content = '''
import 'package:flutter/widgets.dart';

class Foo {
  Widget get icon => const SizedBox();
  SizedBox gap() => const SizedBox();
  int count() => 0;
}
''';
    await assertDiagnostics(content, [
      lintAt(this, content, 'icon', messageContainsAll: ['Foo.icon']),
      lintAt(this, content, 'gap'),
    ]);
  }

  Future<void> test_inferredReturnType_reported() async {
    const content = '''
import 'package:flutter/widgets.dart';

class Foo {
  static gap() => const SizedBox();
}
''';
    // 반환 타입을 적지 않으면 dynamic이라 잡지 않는다
    await assertNoDiagnostics(content);
  }

  Future<void> test_topLevelFunction_reported_localFunction_ok() async {
    const content = '''
import 'package:flutter/widgets.dart';

Widget gap() => const SizedBox();

void f() {
  Widget local() => const SizedBox();
  local();
}
''';
    await assertDiagnostics(content, [lintAt(this, content, 'gap')]);
  }

  Future<void> test_baseline_allowsListed_staleWhenGone() async {
    newFile(
      '$testPackageRootPath/lint_baseline.txt',
      '''
no_widget_helper_methods lib/test.dart Foo._row -
no_widget_helper_methods lib/test.dart Foo._gone -
''',
    );
    const content = '''
import 'package:flutter/widgets.dart';

class Foo {
  Widget _row() => const SizedBox();
  Widget _new() => _row();
}
''';
    await assertDiagnostics(content, [
      lintAt(
        this,
        content,
        'import',
        name: 'no_widget_helper_methods_baseline_stale',
        messageContainsAll: ['Foo._gone'],
      ),
      lintAt(this, content, '_new'),
    ]);
  }
}
