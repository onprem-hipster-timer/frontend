import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_not_found.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '모임을 찾을 수 없음',
  type: MeetingNotFound,
  path: '[모임]/화면 틀',
)
Widget meetingNotFound(BuildContext context) {
  final visitor = context.knobs.boolean(
    label: '로그인하지 않은 방문자',
    description: '로그인하지 않았으면 로그인하면 볼 수 있는 모임일 수 있다고 적고 로그인 버튼을 둔다',
    initialValue: true,
  );
  return MeetingNotFound(onLogin: visitor ? () {} : null);
}
