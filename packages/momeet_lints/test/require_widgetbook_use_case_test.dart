import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:momeet_lints/src/require_widgetbook_use_case.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RequireWidgetbookUseCaseTest);
  });
}

const _riverpod = '''
import 'package:flutter/widgets.dart';

class WidgetRef {}
abstract class ConsumerWidget extends StatelessWidget {
  const ConsumerWidget({super.key});
  @override
  Widget build(BuildContext context) => throw UnimplementedError();
}
abstract class ConsumerStatefulWidget extends StatefulWidget {
  const ConsumerStatefulWidget({super.key});
}
''';

const _card = '''
import 'package:flutter/widgets.dart';

class Card extends StatelessWidget {
  const Card({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

String _useCase(String type) =>
    '''
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '기본', type: $type, path: '[공용]')
Widget card(BuildContext context) => const Card();
''';

@reflectiveTest
class RequireWidgetbookUseCaseTest extends AnalysisRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = RequireWidgetbookUseCase();
    newPackage(
      'flutter_riverpod',
    ).addFile('lib/flutter_riverpod.dart', _riverpod);
    super.setUp();
  }

  String get _widgetbook => '$testPackageRootPath/widgetbook/lib';

  Future<void> test_missingUseCaseFile_reported() async {
    final path = '$testPackageLibPath/shared/ui/card.dart';
    newFile(path, _card);
    await assertDiagnosticsInFile(path, [
      lintAt(
        this,
        _card,
        'Card',
        messageContainsAll: ['Card', 'widgetbook/lib/shared/card.dart'],
      ),
    ]);
  }

  Future<void> test_sharedUseCase_ok() async {
    final path = '$testPackageLibPath/shared/ui/card.dart';
    newFile(path, _card);
    newFile('$_widgetbook/shared/card.dart', _useCase('Card'));
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_sharedWidgetsUseCase_ok() async {
    final path = '$testPackageLibPath/shared/widgets/card.dart';
    newFile(path, _card);
    newFile('$_widgetbook/shared/card.dart', _useCase('Card'));
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_bareAnnotation_ok() async {
    final path = '$testPackageLibPath/shared/ui/card.dart';
    newFile(path, _card);
    newFile('$_widgetbook/shared/card.dart', '''
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: '기본', type: Card)
Widget card(BuildContext context) => const Card();
''');
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_featureUseCase_ok() async {
    final path =
        '$testPackageLibPath/features/todo/presentation/widgets/card.dart';
    newFile(path, _card);
    newFile('$_widgetbook/todo/card.dart', _useCase('Card'));
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_subfolderFlattened_ok() async {
    final path =
        '$testPackageLibPath/features/todo/presentation/widgets/tree/card.dart';
    newFile(path, _card);
    newFile('$_widgetbook/todo/card.dart', _useCase('Card'));
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_subfolderNotFlattened_reported() async {
    final path =
        '$testPackageLibPath/features/todo/presentation/widgets/tree/card.dart';
    newFile(path, _card);
    newFile('$_widgetbook/todo/tree/card.dart', _useCase('Card'));
    await assertDiagnosticsInFile(path, [
      lintAt(
        this,
        _card,
        'Card',
        messageContainsAll: ['widgetbook/lib/todo/card.dart'],
      ),
    ]);
  }

  Future<void> test_wrongGroup_reported() async {
    final path =
        '$testPackageLibPath/features/todo/presentation/widgets/card.dart';
    newFile(path, _card);
    newFile('$_widgetbook/shared/card.dart', _useCase('Card'));
    await assertDiagnosticsInFile(path, [lintAt(this, _card, 'Card')]);
  }

  Future<void> test_otherType_reported() async {
    final path = '$testPackageLibPath/shared/ui/card.dart';
    newFile(path, _card);
    newFile('$_widgetbook/shared/card.dart', _useCase('Badge'));
    await assertDiagnosticsInFile(path, [lintAt(this, _card, 'Card')]);
  }

  Future<void> test_prefixedType_ok() async {
    final path = '$testPackageLibPath/shared/ui/card.dart';
    newFile(path, _card);
    newFile('$_widgetbook/shared/card.dart', _useCase('ui.Card'));
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_typeOfOtherAnnotation_reported() async {
    final path = '$testPackageLibPath/shared/ui/card.dart';
    newFile(path, _card);
    newFile('$_widgetbook/shared/card.dart', '''
@Preview(name: '기본', type: Card)
Widget card(BuildContext context) => const Card();
''');
    await assertDiagnosticsInFile(path, [lintAt(this, _card, 'Card')]);
  }

  Future<void> test_statefulAndIndirectWidgets_reported() async {
    const content = '''
import 'package:flutter/widgets.dart';

class Card extends StatefulWidget {
  const Card({super.key});
  @override
  State<Card> createState() => _CardState();
}

class _CardState extends State<Card> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

abstract class BaseTile extends StatelessWidget {
  const BaseTile({super.key});
}

class Tile extends BaseTile {
  const Tile({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
    final path =
        '$testPackageLibPath/features/todo/presentation/widgets/c.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, [
      lintAt(this, content, 'Card', messageContainsAll: ['todo/c.dart']),
      lintAt(this, content, 'Tile extends BaseTile', length: 4),
    ]);
  }

  Future<void> test_onlyMissingTypeReported() async {
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
''';
    final path = '$testPackageLibPath/shared/ui/card.dart';
    newFile(path, content);
    newFile('$_widgetbook/shared/card.dart', _useCase('Card'));
    await assertDiagnosticsInFile(path, [
      lintAt(this, content, 'Badge', messageContainsAll: ['Badge']),
    ]);
  }

  Future<void> test_commentedOutAnnotation_reported() async {
    final path = '$testPackageLibPath/shared/ui/card.dart';
    newFile(path, _card);
    newFile('$_widgetbook/shared/card.dart', '''
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

// @widgetbook.UseCase(name: '기본', type: Card)
/* @widgetbook.UseCase(name: '기본', type: Card) */
Widget card(BuildContext context) => const Card();
''');
    await assertDiagnosticsInFile(path, [lintAt(this, _card, 'Card')]);
  }

  Future<void> test_brokenUseCaseFile_reportedWithoutThrowing() async {
    final path = '$testPackageLibPath/shared/ui/card.dart';
    newFile(path, _card);
    newFile('$_widgetbook/shared/card.dart', '''
@widgetbook.UseCase(name: '기본', type: Badge
Widget card(BuildContext context) => {{{
''');
    await assertDiagnosticsInFile(path, [lintAt(this, _card, 'Card')]);
  }

  Future<void> test_nonTargetWidgets_ok() async {
    final path = '$testPackageLibPath/shared/ui/card.dart';
    newFile(path, '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CardModel {}

class _Badge extends StatelessWidget {
  const _Badge();
  @override
  Widget build(BuildContext context) => const SizedBox();
}

abstract class BaseCard extends StatelessWidget {
  const BaseCard({super.key});
}

class CardScope extends InheritedWidget {}

class Title extends ConsumerWidget {
  const Title({super.key});
}

class Page extends ConsumerStatefulWidget {
  const Page({super.key});
  @override
  State<Page> createState() => _PageState();
}

class _PageState extends State<Page> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

abstract class AppConsumerWidget extends ConsumerWidget {
  const AppConsumerWidget({super.key});
}

class Header extends AppConsumerWidget {
  const Header({super.key});
}
''');
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_pagesFolder_ok() async {
    final path =
        '$testPackageLibPath/features/todo/presentation/pages/card.dart';
    newFile(path, _card);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_coreFolder_ok() async {
    final path = '$testPackageLibPath/core/widgets/card.dart';
    newFile(path, _card);
    await assertNoDiagnosticsInFile(path);
  }
}
