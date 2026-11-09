import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:momeet_lints/src/no_manual_route_path.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoManualRoutePathTest);
  });
}

const _route = '''
enum AppRoute {
  todo('/todo');
  const AppRoute(this.path);
  final String path;
}
''';

@reflectiveTest
class NoManualRoutePathTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoManualRoutePath();
    super.setUp();
  }

  Future<void> test_interpolation_reported() async {
    const content = "${_route}String a() => '\${AppRoute.todo.path}/x';\n";
    await assertDiagnostics(content, [
      lintAt(this, content, "'\${AppRoute.todo.path}/x'"),
    ]);
  }

  Future<void> test_plus_reported() async {
    const content = "${_route}String a() => AppRoute.todo.path + '/x';\n";
    await assertDiagnostics(content, [
      lintAt(this, content, "AppRoute.todo.path + '/x'"),
    ]);
  }

  Future<void> test_plainPath_ok() async {
    await assertNoDiagnostics('${_route}String a() => AppRoute.todo.path;\n');
  }

  Future<void> test_otherInterpolation_ok() async {
    await assertNoDiagnostics(
      "${_route}String a(String id) => '/todo/\$id';\n",
    );
  }

  Future<void> test_routerFile_skipped() async {
    final path = '$testPackageLibPath/router.dart';
    newFile(path, "${_route}String a() => '\${AppRoute.todo.path}/x';\n");
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_testFile_skipped() async {
    final path = '$testPackageRootPath/test/router_test.dart';
    newFile(path, "${_route}String a() => '\${AppRoute.todo.path}/x';\n");
    await assertNoDiagnosticsInFile(path);
  }
}
