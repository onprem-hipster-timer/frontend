import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_group_form_sheet_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet_widgetbook/calendar/samples_plan.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../shared/samples_shared.dart';

@widgetbook.UseCase(
  name: '태그 그룹 입력 시트',
  type: TagGroupFormSheetView,
  path: '[태그 관리]',
)
Widget tagGroupFormSheetView(BuildContext context) {
  final knobs = context.knobs;
  final edit = knobs.boolean(
    label: '태그 그룹 수정',
    description: '끄면 새 태그 그룹 만들기. 수정은 지금 이름·설명·색으로 채워 연다',
  );
  final long = knobs.boolean(label: '긴 이름', description: '태그 그룹 수정에서 채워 둔 이름');
  final busy = knobs.boolean(
    label: '저장 중',
    description: '생성·수정을 누른 뒤 끝날 때까지 버튼에 진행 표시를 둔다',
  );
  final tagGroup = edit
      ? TagGroupReadWithTags(
          id: 'tag-group-life',
          name: long ? '올해 꼭 챙기고 싶은 생활 습관과 취미 모음' : '생활',
          color: '#00897B',
          createdAt: planStamp,
          updatedAt: planStamp,
          description: '운동·가족·가계부처럼 일 밖의 일정',
        )
      : null;
  // 앱에서는 태그 관리 화면의 새 태그 그룹 버튼이나 그룹의 수정을 누르면 아래에서 올라온다.
  // 노브를 바꾸면 입력한 값을 버리고 처음부터 채운다
  return SheetPreview(
    child: TagGroupFormSheetView(
      key: ValueKey((edit, long)),
      tagGroup: tagGroup,
      busy: busy,
      onSubmit: (_, _, _) => Navigator.of(context).pop(),
    ),
  );
}
