import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:momeet_lints/src/prefer_when_or_null.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferWhenOrNullTest);
  });
}

const _stub = '''
class AsyncValue<T> {
  const AsyncValue(this.value);
  final T value;
  R when<R>({
    required R Function(T data) data,
    required R Function() loading,
    required R Function(Object error, StackTrace stackTrace) error,
  }) => data(value);
  R? whenOrNull<R>({R Function(T data)? data}) => data?.call(value);
}
''';

@reflectiveTest
class PreferWhenOrNullTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferWhenOrNull();
    newPackage('flutter_riverpod').addFile('lib/flutter_riverpod.dart', _stub);
    super.setUp();
  }

  Future<void> test_nullBranches_reported() async {
    const content = '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

int? a(AsyncValue<int> v) =>
    v.when(data: (x) => x, loading: () => null, error: (_, _) => null);
''';
    await assertDiagnostics(content, [lintAt(this, content, 'when')]);
  }

  Future<void> test_meaningfulBranches_ok() async {
    await assertNoDiagnostics('''
import 'package:flutter_riverpod/flutter_riverpod.dart';

int a(AsyncValue<int> v) =>
    v.when(data: (x) => x, loading: () => 0, error: (_, _) => -1);
int? b(AsyncValue<int> v) =>
    v.when(data: (x) => x, loading: () => null, error: (_, _) => -1);
int? c(AsyncValue<int> v) => v.whenOrNull(data: (x) => x);
''');
  }
}
