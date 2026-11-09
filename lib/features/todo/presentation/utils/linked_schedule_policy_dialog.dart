import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 마감일을 지우거나 할 일을 삭제할 때 연결된 캘린더 일정을 어떻게 할지 묻는다.
///
/// 서버는 연결 일정이 있으면 정책 없는 요청을 거부한다(422). 닫으면 null.
Future<LinkedSchedulePolicy?> showLinkedSchedulePolicyDialog(
  BuildContext context, {
  required String todoTitle,
}) {
  return showAppChoiceDialog<LinkedSchedulePolicy>(
    context,
    title: '연결된 일정 처리',
    content: '"$todoTitle"의 마감일은 캘린더 일정과 연결돼 있습니다.\n그 일정을 어떻게 할까요?',
    choices: const [
      AppDialogChoice(
        value: LinkedSchedulePolicy.unlink,
        label: '일정은 남기기',
        description: '연결만 끊고 일반 일정으로 둡니다',
      ),
      AppDialogChoice(
        value: LinkedSchedulePolicy.delete,
        label: '일정도 삭제',
        description: '캘린더에서 함께 지웁니다',
      ),
    ],
  );
}
