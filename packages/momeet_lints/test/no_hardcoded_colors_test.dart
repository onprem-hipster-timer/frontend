import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:momeet_lints/src/no_hardcoded_colors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoHardcodedColorsTest);
  });
}

const _stub = '''
class Color {
  const Color(int value);
}
class Colors {
  static const Color blue = Color(1);
  static const Color grey = Color(2);
  static const Color teal = Color(5);
  static const Color transparent = Color(0);
  static const Color white = Color(3);
  static const Color black87 = Color(4);
}
''';

@reflectiveTest
class NoHardcodedColorsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoHardcodedColors();
    newPackage('material_ui').addFile('lib/material_ui.dart', _stub);
    super.setUp();
  }

  Future<void> test_namedColor_reported() async {
    const content = '''
import 'package:material_ui/material_ui.dart';

const a = Colors.blue;
const b = Colors.teal;
''';
    final path = '$testPackageLibPath/features/calendar/source.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, [
      lintAt(this, content, 'Colors.blue', messageContainsAll: ['blue']),
      lintAt(this, content, 'Colors.teal'),
    ]);
  }

  Future<void> test_neutralColors_ok() async {
    final path = '$testPackageLibPath/features/calendar/source.dart';
    newFile(path, '''
import 'package:material_ui/material_ui.dart';

const a = Colors.transparent;
const b = Colors.white;
const c = Colors.black87;
const d = Colors.grey;
''');
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_themeFolderAndLocalName_ok() async {
    final theme = '$testPackageLibPath/shared/ui/theme/app_colors.dart';
    newFile(theme, '''
import 'package:material_ui/material_ui.dart';

const base = Colors.blue;
''');
    await assertNoDiagnosticsInFile(theme);

    final page = '$testPackageLibPath/features/calendar/page.dart';
    newFile(page, '''
class Colors {
  final int blue = 1;
}
int pick(Colors c) => c.blue;
''');
    await assertNoDiagnosticsInFile(page);
  }
}
