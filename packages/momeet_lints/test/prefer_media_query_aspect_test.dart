import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:momeet_lints/src/prefer_media_query_aspect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferMediaQueryAspectTest);
  });
}

const _stub = '''
class BuildContext {}
class Size {
  const Size(this.width, this.height);
  final double width;
  final double height;
}
class EdgeInsets {
  const EdgeInsets.all(this.bottom);
  final double bottom;
}
class MediaQueryData {
  const MediaQueryData({this.size = const Size(0, 0)});
  final Size size;
  EdgeInsets get padding => const EdgeInsets.all(0);
  MediaQueryData copyWith({bool? alwaysUse24HourFormat}) => this;
}
class MediaQuery {
  static MediaQueryData of(BuildContext c) => const MediaQueryData();
  static MediaQueryData? maybeOf(BuildContext c) => null;
  static Size sizeOf(BuildContext c) => const Size(0, 0);
  static EdgeInsets paddingOf(BuildContext c) => const EdgeInsets.all(0);
}
''';

@reflectiveTest
class PreferMediaQueryAspectTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferMediaQueryAspect();
    newPackage('material_ui').addFile('lib/material_ui.dart', _stub);
    super.setUp();
  }

  Future<void> test_propertyOfData_reported() async {
    const content = '''
import 'package:material_ui/material_ui.dart';

double a(BuildContext c) => MediaQuery.of(c).size.height;
double b(BuildContext c) => MediaQuery.of(c).padding.bottom;
Size? d(BuildContext c) => MediaQuery.maybeOf(c)?.size;
''';
    await assertDiagnostics(content, [
      lintAt(
        this,
        content,
        'MediaQuery.of(c).size',
        messageContainsAll: ['sizeOf'],
      ),
      lintAt(
        this,
        content,
        'MediaQuery.of(c).padding',
        messageContainsAll: ['paddingOf'],
      ),
      lintAt(
        this,
        content,
        'MediaQuery.maybeOf(c)?.size',
        messageContainsAll: ['maybeSizeOf'],
      ),
    ]);
  }

  Future<void> test_aspectAccessorsAndWholeData_ok() async {
    await assertNoDiagnostics('''
import 'package:material_ui/material_ui.dart';

double a(BuildContext c) => MediaQuery.sizeOf(c).height;
MediaQueryData b(BuildContext c) =>
    MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true);
double d(BuildContext c) {
  final media = MediaQuery.of(c);
  return media.padding.bottom;
}
''');
  }
}
