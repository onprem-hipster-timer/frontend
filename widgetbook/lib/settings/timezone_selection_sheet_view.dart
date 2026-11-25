import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/settings/presentation/widgets/timezone_selection_sheet_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../shared/samples_shared.dart';

@widgetbook.UseCase(
  name: '타임존 선택 시트',
  type: TimezoneSelectionSheetView,
  path: '[마이페이지]',
)
Widget timezoneSelectionSheetView(BuildContext context) {
  final current = context.knobs.object.dropdown(
    label: '지금 타임존',
    options: const ['Asia/Seoul', 'America/New_York', 'Europe/London'],
    description: '목록에서 굵게 강조하고 체크를 둔다. 목록은 UTC 차이 순이라 서울은 아래쪽에 있다',
  );
  // 앱에서는 마이페이지 설정 목록의 타임존 설정을 누르면 화면 높이의 70%로 올라온다.
  // 타임존을 고르면 저장하고 닫는다. 노브를 바꾸면 검색어를 버린다
  return SheetPreview(
    child: TimezoneSelectionSheetView(
      key: ValueKey(current),
      currentTimezone: current,
      onSelected: (_) => Navigator.of(context).pop(),
    ),
  );
}
