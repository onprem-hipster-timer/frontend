import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 할 일의 마감일에서 만들어진 일정을 삭제할 때 원본 할 일의 마감일을 어떻게 할지 묻는다.
///
/// 서버는 연결 일정에 정책이 없으면 삭제를 거부한다(422). 닫으면 null.
Future<SourceTodoPolicy?> showSourceTodoPolicyDialog(
  BuildContext context, {
  required String scheduleTitle,
}) {
  return showAppChoiceDialog<SourceTodoPolicy>(
    context,
    title: '원본 ${Terms.todo} 처리',
    content:
        '"$scheduleTitle"은(는) ${Terms.todo}의 마감일에서 만들어진 일정입니다.\n${Terms.todo}의 마감일을 어떻게 할까요?',
    choices: [
      AppDialogChoice(
        value: SourceTodoPolicy.keepDeadline,
        label: '마감일 유지',
        description: '${Terms.todo.withJosa('은', '는')} 그대로 두고 일정만 삭제합니다',
      ),
      const AppDialogChoice(
        value: SourceTodoPolicy.clearDeadline,
        label: '마감일도 지우기',
        description: '${Terms.todo}에서 마감일을 함께 없앱니다',
      ),
    ],
  );
}
