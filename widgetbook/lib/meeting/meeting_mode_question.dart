import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_mode_question.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_meeting_c.dart';

@widgetbook.UseCase(
  name: '받는 방식 질문',
  type: MeetingModeQuestion,
  path: '[모임]/모임 만들기',
)
Widget meetingModeQuestion(BuildContext context) {
  final knobs = context.knobs;
  final hourly = knobs.boolean(
    label: '시간별 고를 수 있음',
    description: '고른 날짜가 $hourlyMaxDays일을 넘으면 시간별을 흐리게 두고 까닭을 적는다. 누르면 떤다',
    initialValue: true,
  );
  final chosenLabel = knobs.object.dropdown(
    label: '지금 방식',
    description: '이미 답한 질문을 다시 열면 지금 방식을 채워 둔다',
    options: [
      '없음',
      for (final mode in MeetingMode.$valuesDefined) meetingModeLabel(mode),
    ],
  );
  final chosen = MeetingMode.$valuesDefined
      .where((mode) => meetingModeLabel(mode) == chosenLabel)
      .firstOrNull;
  return meetingCreateFrame(
    MeetingModeQuestion(
      // 노브를 바꾸면 방금 누른 방식을 잊는다
      key: ValueKey((hourly, chosen)),
      hourlyAvailable: hourly,
      chosen: chosen,
      onChoose: (_) {},
    ),
  );
}
