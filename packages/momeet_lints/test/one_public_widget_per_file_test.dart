import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:momeet_lints/src/one_public_widget_per_file.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OnePublicWidgetPerFileTest);
  });
}

@reflectiveTest
class OnePublicWidgetPerFileTest extends AnalysisRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = OnePublicWidgetPerFile();
    super.setUp();
  }

  Future<void> test_secondPublicWidget_reported() async {
    const content = '''
import 'package:flutter/widgets.dart';

class Card extends StatelessWidget {
  const Card({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class Badge extends StatelessWidget {
  const Badge({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class Chip extends StatefulWidget {
  const Chip({super.key});
  @override
  State<Chip> createState() => _ChipState();
}

class _ChipState extends State<Chip> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
    final path = '$testPackageLibPath/features/todo/card.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, [
      lintAt(this, content, 'Badge', messageContainsAll: ['Card', 'Badge']),
      lintAt(this, content, 'Chip', messageContainsAll: ['Chip']),
    ]);
  }

  Future<void> test_privateHelpersAndNonWidgets_ok() async {
    final path = '$testPackageLibPath/features/todo/card.dart';
    newFile(path, '''
import 'package:flutter/widgets.dart';

class CardModel {}

class Card extends StatelessWidget {
  const Card({super.key});
  @override
  Widget build(BuildContext context) => const _Badge();
}

class _Badge extends StatelessWidget {
  const _Badge();
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
    await assertNoDiagnosticsInFile(path);
  }
}
