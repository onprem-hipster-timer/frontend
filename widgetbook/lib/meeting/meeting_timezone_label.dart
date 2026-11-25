import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_timezone_label.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// 모임 시간대 노브의 선택지: 화면 이름과 IANA 이름
const _zones = {
  '서울': 'Asia/Seoul',
  '뉴욕': 'America/New_York',
  '런던': 'Europe/London',
  '로스앤젤레스': 'America/Los_Angeles',
};

@widgetbook.UseCase(
  name: '시간 기준',
  type: MeetingTimezoneLabel,
  path: '[모임]/내 시간 선택하기',
)
Widget meetingTimezoneLabel(BuildContext context) {
  final zone = context.knobs.object.dropdown(
    label: '모임 시간대',
    description: '모임을 만든 사람의 시간대. 서울은 \'한국 시간 기준\', 그 밖은 도시와 UTC 차이로 보인다',
    options: _zones.keys.toList(),
  );
  return Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: MeetingTimezoneLabel(_zones[zone]!),
    ),
  );
}
