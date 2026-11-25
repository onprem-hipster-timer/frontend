import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_name_sheet_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../shared/samples_shared.dart';

@widgetbook.UseCase(
  name: '내 닉네임 시트',
  type: MeetingNameSheetView,
  path: '[모임]/참여자',
)
Widget meetingNameSheetView(BuildContext context) {
  final knobs = context.knobs;
  final long = knobs.boolean(label: '긴 닉네임', description: '지금 닉네임으로 채워 연다');
  final busy = knobs.boolean(
    label: '저장 중',
    description: '저장을 누른 뒤 끝날 때까지 버튼에 진행 표시를 둔다',
  );
  // 앱에서는 회원이 '일정 참여자'의 편집을 누르면 아래에서 올라온다. 저장하면 닫고 알린다.
  // 노브를 바꾸면 입력한 값을 버리고 처음부터 채운다
  return SheetPreview(
    child: MeetingNameSheetView(
      key: ValueKey(long),
      currentName: long ? '주말마다 산에 가는 이름이 아주 긴 다람쥐' : '다람쥐',
      busy: busy,
      onSubmit: (_) => Navigator.of(context).pop(),
    ),
  );
}
