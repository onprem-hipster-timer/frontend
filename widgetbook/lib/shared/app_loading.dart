import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '불러오는 중 표시', type: AppLoading, path: '[공통]/상태 안내')
Widget appLoading(BuildContext context) {
  return AppLoading(
    message: context.knobs.stringOrNull(
      label: '안내 문장',
      description: '비우면 도는 표시만 둔다(대부분의 화면)',
      initialValue: '태그를 불러오는 중...',
    ),
  );
}
