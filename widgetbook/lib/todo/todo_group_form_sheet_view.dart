import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_group_form_sheet_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet_widgetbook/calendar/samples_plan.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../shared/samples_shared.dart';

@widgetbook.UseCase(
  name: '해야 할 일 목록 입력 시트',
  type: TodoGroupFormSheetView,
  path: '[할 일]',
)
Widget todoGroupFormSheetView(BuildContext context) {
  final knobs = context.knobs;
  final edit = knobs.boolean(
    label: '목록 수정',
    description: '끄면 새 목록 만들기. 수정은 지금 이름·설명·색으로 채워 연다',
  );
  final long = knobs.boolean(label: '긴 이름', description: '목록 수정에서 채워 둔 이름');
  final busy = knobs.boolean(
    label: '저장 중',
    description: '생성·수정을 누른 뒤 끝날 때까지 버튼에 진행 표시를 둔다',
  );
  final group = edit
      ? TodoGroupRead(
          id: 'todo-group-1',
          name: long ? '4월 중간 발표 전까지 꼭 끝내야 하는 졸업 프로젝트 자료 정리' : '졸업 프로젝트',
          color: '#8E24AA',
          isDefault: false,
          createdAt: planStamp,
          updatedAt: planStamp,
          description: '4월 중간 발표 전까지 끝낼 일',
        )
      : null;
  // 앱에서는 할 일 탭 첫 화면의 새 목록 버튼이나 목록 화면의 수정을 누르면 아래에서 올라온다.
  // 노브를 바꾸면 입력한 값을 버리고 처음부터 채운다
  return SheetPreview(
    child: TodoGroupFormSheetView(
      key: ValueKey((edit, long)),
      group: group,
      busy: busy,
      onSubmit: (_, _, _) => Navigator.of(context).pop(),
    ),
  );
}
