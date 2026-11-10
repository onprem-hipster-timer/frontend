import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:momeet_lints/src/no_raw_flutter_overlays.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoRawFlutterOverlaysTest);
  });
}

const _flutter = '''
class BuildContext {}
class Widget {}
class SnackBar extends Widget {
  const SnackBar();
}
Future<T?> showDialog<T>({required BuildContext context}) async => null;
Future<DateTime?> showDatePicker({required BuildContext context}) async =>
    null;
class ScaffoldMessengerState {
  void showSnackBar(SnackBar bar) {}
  void show() {}
}
class ScaffoldMessenger {
  static ScaffoldMessengerState of(BuildContext c) => ScaffoldMessengerState();
}
''';

@reflectiveTest
class NoRawFlutterOverlaysTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoRawFlutterOverlays();
    newPackage('flutter').addFile('lib/material.dart', _flutter);
    newPackage('material_ui').addFile('lib/material_ui.dart', '''
import 'package:flutter/material.dart';

Future<DateTime?> showTimePicker({required BuildContext context}) async =>
    null;
''');
    super.setUp();
  }

  Future<void> test_flutterShowCalls_reported() async {
    const content = '''
import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart';

void open(BuildContext context) {
  showDialog<void>(context: context);
  showDatePicker(context: context);
  showTimePicker(context: context);
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar());
  ScaffoldMessenger.of(context).show();
}
''';
    final path = '$testPackageLibPath/features/todo/page.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, [
      lintAt(this, content, 'showDialog', messageContainsAll: ['showDialog']),
      lintAt(this, content, 'showDatePicker'),
      lintAt(this, content, 'showTimePicker'),
      lintAt(this, content, 'showSnackBar'),
    ]);
  }

  Future<void> test_appWrappersAndSharedUi_ok() async {
    final page = '$testPackageLibPath/features/todo/page.dart';
    newFile(page, '''
import 'package:flutter/material.dart';

Future<void> showAppSheet(BuildContext c) async {}
void showAppSnackBar(BuildContext c, String m) {}
void open(BuildContext context) {
  showAppSheet(context);
  showAppSnackBar(context, '저장했습니다');
}
''');
    await assertNoDiagnosticsInFile(page);

    final ui = '$testPackageLibPath/shared/ui/components/app_sheet.dart';
    newFile(ui, '''
import 'package:flutter/material.dart';

Future<void> showAppSheet(BuildContext context) =>
    showDialog<void>(context: context);
''');
    await assertNoDiagnosticsInFile(ui);
  }
}
