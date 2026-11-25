import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_home_button.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '홈으로 가는 배지',
  type: MeetingHomeButton,
  path: '[모임]/화면 틀',
)
Widget meetingHomeButton(BuildContext context) {
  // 앱에서는 모임 화면 상단 바 왼쪽 끝에 놓인다. 누르면 캘린더 화면 안내가 뜬다
  return const Align(
    alignment: AlignmentDirectional.topStart,
    child: Padding(
      padding: EdgeInsetsDirectional.only(start: 8, top: 4),
      child: SizedBox(height: kToolbarHeight, child: MeetingHomeButton()),
    ),
  );
}
