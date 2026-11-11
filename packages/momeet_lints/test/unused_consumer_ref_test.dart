import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:momeet_lints/src/unused_consumer_ref.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedConsumerRefTest);
  });
}

const _riverpod = '''
import 'package:flutter/widgets.dart';

class WidgetRef {
  T watch<T>(Object provider) => throw UnimplementedError();
}
abstract class ConsumerWidget extends Widget {
  const ConsumerWidget({super.key});
  Widget build(BuildContext context, WidgetRef ref);
  @override
  Element createElement() => throw UnimplementedError();
}
abstract class ConsumerStatefulWidget extends StatefulWidget {
  const ConsumerStatefulWidget({super.key});
}
abstract class ConsumerState<T extends ConsumerStatefulWidget>
    extends State<T> {
  WidgetRef get ref => WidgetRef();
}
''';

@reflectiveTest
class UnusedConsumerRefTest extends AnalysisRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = UnusedConsumerRef();
    newPackage(
      'flutter_riverpod',
    ).addFile('lib/flutter_riverpod.dart', _riverpod);
    super.setUp();
  }

  Future<void> test_unusedRef_reported() async {
    const content = '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Title extends ConsumerWidget {
  const Title({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox();
}

class Page extends ConsumerStatefulWidget {
  const Page({super.key});

  @override
  ConsumerState<Page> createState() => _PageState();
}

class _PageState extends ConsumerState<Page> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
    await assertDiagnostics(content, [
      lintAt(this, content, 'Title', messageContainsAll: ['StatelessWidget']),
      lintAt(
        this,
        content,
        '_PageState',
        occurrence: 1,
        messageContainsAll: ['State'],
      ),
    ]);
  }

  Future<void> test_usedRef_ok() async {
    await assertNoDiagnostics('''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final provider = Object();

class Title extends ConsumerWidget {
  const Title({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(provider);
    return const SizedBox();
  }
}

class Page extends ConsumerStatefulWidget {
  const Page({super.key});

  @override
  ConsumerState<Page> createState() => _PageState();
}

class _PageState extends ConsumerState<Page> {
  @override
  void initState() {
    super.initState();
    ref.watch(provider);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
  }
}
