import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:momeet_lints/src/duplicate_widget_tree.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateWidgetTreeTest);
  });
}

/// 인자 셋을 받는 위젯. 세 겹을 겹치면 비교 기준(40 노드)을 넘고, 두 겹은 넘지 않는다
const _box = '''
import 'package:flutter/widgets.dart';

class Box extends StatelessWidget {
  const Box({super.key, this.label, this.size, this.child});
  final String? label;
  final int? size;
  final Widget? child;
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

String _tree(String label, int size) =>
    'Box(label: \'$label\', size: $size, child: '
    'Box(label: \'$label\', size: $size, child: '
    'Box(label: \'$label\', size: $size, child: const SizedBox())))';

@reflectiveTest
class DuplicateWidgetTreeTest extends AnalysisRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = DuplicateWidgetTree();
    super.setUp();
  }

  Future<void> test_sameShapeTwice_reported() async {
    final content =
        '''
$_box
class A extends StatelessWidget {
  const A({super.key});
  @override
  Widget build(BuildContext context) => ${_tree('a', 1)};
}

class B extends StatelessWidget {
  const B({super.key});
  @override
  Widget build(BuildContext context) => ${_tree('b', 2)};
}
''';
    final path = '$testPackageLibPath/features/todo/boxes.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, [
      lintAt(
        this,
        content,
        "Box(label: 'a'",
        length: 3,
        messageContainsAll: ['줄에도'],
      ),
      lintAt(this, content, "Box(label: 'b'", length: 3),
    ]);
  }

  Future<void> test_smallOrDifferentShape_ok() async {
    final path = '$testPackageLibPath/features/todo/boxes.dart';
    newFile(path, '''
$_box
class A extends StatelessWidget {
  const A({super.key});
  @override
  Widget build(BuildContext context) =>
      Box(label: 'a', size: 1, child: Box(label: 'a', size: 1));
}

class B extends StatelessWidget {
  const B({super.key});
  @override
  Widget build(BuildContext context) =>
      Box(label: 'b', size: 2, child: Box(label: 'b', size: 2));
}

class C extends StatelessWidget {
  const C({super.key});
  @override
  Widget build(BuildContext context) => ${_tree('c', 3)};
}

class D extends StatelessWidget {
  const D({super.key});
  @override
  Widget build(BuildContext context) => Box(
    label: 'd',
    child: Box(size: 4, child: Box(label: 'd', size: 4, child: const SizedBox())),
  );
}
''');
    await assertNoDiagnosticsInFile(path);
  }
}
