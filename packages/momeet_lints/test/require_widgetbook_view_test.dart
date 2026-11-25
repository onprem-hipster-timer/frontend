import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:momeet_lints/src/require_widgetbook_view.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RequireWidgetbookViewTest);
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
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Card extends ConsumerWidget {
  const Card({super.key});
}
''';

const _cardView = '''
import 'package:flutter/widgets.dart';

class CardView extends StatelessWidget {
  const CardView({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

@reflectiveTest
class RequireWidgetbookViewTest extends AnalysisRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = RequireWidgetbookView();
    newPackage(
      'flutter_riverpod',
    ).addFile('lib/flutter_riverpod.dart', _riverpod);
    super.setUp();
  }

  String get _widgets =>
      '$testPackageLibPath/features/todo/presentation/widgets';

  Future<void> test_noViewFile_reported() async {
    final path = '$_widgets/card.dart';
    newFile(path, _card);
    await assertDiagnosticsInFile(path, [
      lintAt(
        this,
        _card,
        'Card',
        messageContainsAll: [
          'Card',
          'CardView',
          'lib/features/todo/presentation/widgets/card_view.dart',
        ],
      ),
    ]);
  }

  Future<void> test_viewFileWithoutViewClass_reported() async {
    final path = '$testPackageLibPath/shared/ui/card.dart';
    newFile(path, _card);
    newFile('$testPackageLibPath/shared/ui/card_view.dart', '''
import 'package:flutter/widgets.dart';

class CardBody extends StatelessWidget {
  const CardBody({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
    await assertDiagnosticsInFile(path, [
      lintAt(
        this,
        _card,
        'Card',
        messageContainsAll: ['lib/shared/ui/card_view.dart'],
      ),
    ]);
  }

  Future<void> test_viewClass_ok() async {
    final path = '$_widgets/card.dart';
    newFile(path, _card);
    newFile('$_widgets/card_view.dart', _cardView);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_sharedWidgetsViewClass_ok() async {
    final path = '$testPackageLibPath/shared/widgets/card.dart';
    newFile(path, _card);
    newFile('$testPackageLibPath/shared/widgets/card_view.dart', _cardView);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_viewInOtherFolder_reported() async {
    final path = '$_widgets/card.dart';
    newFile(path, _card);
    newFile('$testPackageLibPath/shared/ui/card_view.dart', _cardView);
    await assertDiagnosticsInFile(path, [lintAt(this, _card, 'Card')]);
  }

  Future<void> test_viewInOtherFileName_reported() async {
    final path = '$_widgets/card.dart';
    newFile(path, _card);
    newFile('$_widgets/card_body.dart', _cardView);
    await assertDiagnosticsInFile(path, [lintAt(this, _card, 'Card')]);
  }

  Future<void> test_commentedOutViewClass_reported() async {
    final path = '$_widgets/card.dart';
    newFile(path, _card);
    newFile('$_widgets/card_view.dart', '''
// class CardView extends StatelessWidget {}
/* class CardView {} */
''');
    await assertDiagnosticsInFile(path, [lintAt(this, _card, 'Card')]);
  }

  Future<void> test_brokenViewFile_reportedWithoutThrowing() async {
    final path = '$_widgets/card.dart';
    newFile(path, _card);
    newFile('$_widgets/card_view.dart', '''
class Broken extends {{{
''');
    await assertDiagnosticsInFile(path, [lintAt(this, _card, 'Card')]);
  }

  Future<void> test_consumerStatefulWidget_reported() async {
    const content = '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Panel extends ConsumerStatefulWidget {
  const Panel({super.key});
  @override
  State<Panel> createState() => _PanelState();
}

class _PanelState extends State<Panel> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
    final path = '$_widgets/panel.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, [
      lintAt(
        this,
        content,
        'Panel',
        messageContainsAll: ['PanelView', 'widgets/panel_view.dart'],
      ),
    ]);
  }

  Future<void> test_consumerStatefulWidgetWithView_ok() async {
    final path = '$_widgets/panel.dart';
    newFile(path, '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Panel extends ConsumerStatefulWidget {
  const Panel({super.key});
  @override
  State<Panel> createState() => _PanelState();
}

class _PanelState extends State<Panel> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
    newFile('$_widgets/panel_view.dart', '''
class PanelView {}
''');
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_indirectConsumer_reported() async {
    const content = '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class AppConsumerWidget extends ConsumerWidget {
  const AppConsumerWidget({super.key});
}

class Header extends AppConsumerWidget {
  const Header({super.key});
}
''';
    final path = '$_widgets/header.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, [
      lintAt(this, content, 'Header extends', length: 6),
    ]);
  }

  Future<void> test_nonTargetClasses_ok() async {
    final path = '$_widgets/card.dart';
    newFile(path, '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CardModel {}

class Badge extends StatelessWidget {
  const Badge({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class Panel extends StatefulWidget {
  const Panel({super.key});
  @override
  State<Panel> createState() => _PanelState();
}

class _PanelState extends State<Panel> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _Title extends ConsumerWidget {
  const _Title();
}

abstract class BaseCard extends ConsumerWidget {
  const BaseCard({super.key});
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

  Future<void> test_subfolder_reported() async {
    final path = '$_widgets/tree/card.dart';
    newFile(path, _card);
    newFile('$_widgets/card_view.dart', _cardView);
    await assertDiagnosticsInFile(path, [
      lintAt(
        this,
        _card,
        'Card',
        messageContainsAll: [
          'lib/features/todo/presentation/widgets/tree/card_view.dart',
        ],
      ),
    ]);
  }

  Future<void> test_subfolderViewClass_ok() async {
    final path = '$_widgets/tree/card.dart';
    newFile(path, _card);
    newFile('$_widgets/tree/card_view.dart', _cardView);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_onlyConsumerWithoutViewReported() async {
    const content = '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Card extends ConsumerWidget {
  const Card({super.key});
}

class Badge extends ConsumerWidget {
  const Badge({super.key});
}
''';
    final path = '$_widgets/card.dart';
    newFile(path, content);
    newFile('$_widgets/card_view.dart', _cardView);
    await assertDiagnosticsInFile(path, [
      lintAt(
        this,
        content,
        'Badge',
        messageContainsAll: ['BadgeView', 'widgets/card_view.dart'],
      ),
    ]);
  }

  Future<void> test_consumerView_reportedAgain() async {
    const content = '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CardView extends ConsumerWidget {
  const CardView({super.key});
}
''';
    final path = '$_widgets/card_view.dart';
    newFile(path, content);
    await assertDiagnosticsInFile(path, [
      lintAt(
        this,
        content,
        'CardView',
        messageContainsAll: ['CardViewView', 'widgets/card_view_view.dart'],
      ),
    ]);
  }
}
