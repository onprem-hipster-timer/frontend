import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_timezone_label.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '시간 기준',
  type: MeetingTimezoneLabel,
  path: '[모임]/내 시간 선택하기',
)
Widget meetingTimezoneLabel(BuildContext context) {
  // 카탈로그에는 시간대 DB가 없어 한국 시간만 앱과 같은 글로 보인다
  return const Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: MeetingTimezoneLabel('Asia/Seoul'),
    ),
  );
}
