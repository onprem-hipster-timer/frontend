import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:momeet_lints/src/auth_notifier_structure.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AuthActionNoLoadingStateTest);
    defineReflectiveTests(AuthCatchRequireClassifyTest);
  });
}

const _types = '''
class AuthStatus {
  const AuthStatus.loading();
  const AuthStatus.idle();
}
class AuthErrorType {
  static Object classify(Object e) => e;
}
''';

@reflectiveTest
class AuthActionNoLoadingStateTest extends AnalysisRuleTest {
  String get _path => '$testPackageLibPath/core/providers/auth_provider.dart';

  @override
  void setUp() {
    rule = AuthActionNoLoadingState();
    super.setUp();
  }

  Future<void> test_actionLoading_reported() async {
    const content = '''${_types}class AuthNotifier {
  Object state = const AuthStatus.idle();
  Future<void> signOut() async {
    state = AuthStatus.loading();
  }
}
''';
    newFile(_path, content);
    await assertDiagnosticsInFile(_path, [
      lintAt(this, content, 'AuthStatus.loading()', occurrence: 1),
    ]);
  }

  Future<void> test_buildLoading_ok() async {
    newFile(_path, '''${_types}class AuthNotifier {
  Object build() => AuthStatus.loading();
}
''');
    await assertNoDiagnosticsInFile(_path);
  }

  Future<void> test_otherFile_skipped() async {
    await assertNoDiagnostics('''${_types}class AuthNotifier {
  Object state = const AuthStatus.idle();
  Future<void> signOut() async {
    state = AuthStatus.loading();
  }
}
''');
  }
}

@reflectiveTest
class AuthCatchRequireClassifyTest extends AnalysisRuleTest {
  String get _path => '$testPackageLibPath/core/providers/auth_provider.dart';

  @override
  void setUp() {
    rule = AuthCatchRequireClassify();
    super.setUp();
  }

  Future<void> test_catchWithoutClassify_reported() async {
    const content = '''${_types}class AuthNotifier {
  Future<void> signOut() async {
    try {} catch (e) {
      print(e);
    }
  }
}
''';
    newFile(_path, content);
    await assertDiagnosticsInFile(_path, [
      lintAt(this, content, 'catch (e) {\n      print(e);\n    }'),
    ]);
  }

  Future<void> test_catchWithClassify_ok() async {
    newFile(_path, '''${_types}class AuthNotifier {
  Future<void> signOut() async {
    try {} catch (e) {
      AuthErrorType.classify(e);
    }
  }
}
''');
    await assertNoDiagnosticsInFile(_path);
  }

  Future<void> test_nonActionMethod_ok() async {
    newFile(_path, '''${_types}class AuthNotifier {
  Future<void> helper() async {
    try {} catch (e) {
      print(e);
    }
  }
}
''');
    await assertNoDiagnosticsInFile(_path);
  }
}
