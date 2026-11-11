import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:momeet_lints/src/no_direct_kratos_client.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoDirectKratosClientTest);
  });
}

const _use = '''
import 'package:momeet/shared/api/kratos/kratos_client.dart';

Future<void> logout(KratosClient client) => client.logout();
''';

@reflectiveTest
class NoDirectKratosClientTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoDirectKratosClient();
    newPackage('momeet').addFile('lib/shared/api/kratos/kratos_client.dart', '''
class KratosClient {
  Future<void> logout() async {}
}
class FakeKratosClient extends KratosClient {}
''');
    newPackage('other').addFile('lib/client.dart', '''
class KratosClient {
  Future<void> logout() async {}
}
''');
    super.setUp();
  }

  Future<void> test_typeAndCall_reported() async {
    await assertDiagnostics(_use, [
      lintAt(this, _use, 'KratosClient'),
      lintAt(this, _use, 'client.logout()'),
    ]);
  }

  Future<void> test_subtypeCall_reported() async {
    const content = '''
import 'package:momeet/shared/api/kratos/kratos_client.dart';

Future<void> logout(FakeKratosClient client) => client.logout();
''';
    await assertDiagnostics(content, [
      lintAt(this, content, 'client.logout()'),
    ]);
  }

  Future<void> test_sameNameOtherPackage_ok() async {
    await assertNoDiagnostics('''
import 'package:other/client.dart';

Future<void> logout(KratosClient client) => client.logout();
''');
  }

  Future<void> test_authProvider_skipped() async {
    final path = '$testPackageLibPath/core/providers/auth_provider.dart';
    newFile(path, _use);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_kratosLayer_skipped() async {
    final path = '$testPackageLibPath/shared/api/kratos/session.dart';
    newFile(path, _use);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_testDir_skipped() async {
    final path = '$testPackageRootPath/test/kratos_test.dart';
    newFile(path, _use);
    await assertNoDiagnosticsInFile(path);
  }
}
