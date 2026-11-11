import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:momeet_lints/src/shared_ui_import_boundary.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SharedUiImportBoundaryTest);
  });

  group('forbidden', () {
    test('기능 코드·상태 관리·라우팅 패키지를 막는다', () {
      expect(
        SharedUiImportBoundary.forbidden('package:momeet/features/todo/a.dart'),
        'features',
      );
      expect(
        SharedUiImportBoundary.forbidden('../../features/a.dart'),
        'features',
      );
      expect(
        SharedUiImportBoundary.forbidden(
          'package:flutter_riverpod/flutter_riverpod.dart',
        ),
        'flutter_riverpod',
      );
      expect(
        SharedUiImportBoundary.forbidden('package:go_router/go_router.dart'),
        'go_router',
      );
    });

    test('나머지는 허용한다', () {
      expect(
        SharedUiImportBoundary.forbidden('package:momeet/shared/ui/ui.dart'),
        isNull,
      );
      expect(
        SharedUiImportBoundary.forbidden(
          'package:material_ui/material_ui.dart',
        ),
        isNull,
      );
      expect(SharedUiImportBoundary.forbidden('dart:async'), isNull);
    });
  });
}

@reflectiveTest
class SharedUiImportBoundaryTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = SharedUiImportBoundary();
    newPackage('go_router').addFile('lib/go_router.dart', 'class GoRouter {}');
    super.setUp();
  }

  String get _uiPath => '$testPackageLibPath/shared/ui/form/sheet.dart';

  Future<void> test_featureImportInSharedUi_reported() async {
    newFile('$testPackageLibPath/features/todo/todo.dart', 'class Todo {}');
    const content = '''
import 'package:test/features/todo/todo.dart';
import 'package:go_router/go_router.dart';
export 'package:go_router/go_router.dart';

Todo? a;
GoRouter? b;
''';
    newFile(_uiPath, content);
    await assertDiagnosticsInFile(_uiPath, [
      lintAt(this, content, "'package:test/features/todo/todo.dart'"),
      lintAt(this, content, "'package:go_router/go_router.dart'"),
      lintAt(
        this,
        content,
        "'package:go_router/go_router.dart'",
        occurrence: 1,
      ),
    ]);
  }

  Future<void> test_relativeFeatureImport_reported() async {
    newFile('$testPackageLibPath/features/todo/todo.dart', 'class Todo {}');
    const content = '''
import '../../../features/todo/todo.dart';

Todo? a;
''';
    newFile(_uiPath, content);
    await assertDiagnosticsInFile(_uiPath, [
      lintAt(this, content, "'../../../features/todo/todo.dart'"),
    ]);
  }

  Future<void> test_outsideSharedUi_ok() async {
    final path = '$testPackageLibPath/features/todo/page.dart';
    newFile(path, '''
import 'package:go_router/go_router.dart';

GoRouter? b;
''');
    await assertNoDiagnosticsInFile(path);
  }
}
