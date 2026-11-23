import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_edit.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_edit_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_field_refusal.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _parts = {
  '공개 범위': MeetingEditPart.visibility,
  '제목': MeetingEditPart.title,
  '날짜': MeetingEditPart.dates,
  '받는 방식': MeetingEditPart.mode,
  '시간 범위': MeetingEditPart.time,
  '게스트 로그인': MeetingEditPart.guests,
};

@widgetbook.UseCase(
  name: '저장하지 못한 까닭',
  type: MeetingFieldRefusal,
  path: '[모임]/모임 만들기',
)
Widget meetingFieldRefusal(BuildContext context) {
  final part = context.knobs.object.dropdown(
    label: '거절된 칸',
    description: '모임 설정에서 저장하기를 눌렀는데 서버가 받지 않은 칸. 그 칸 바로 아래에 뜬다',
    options: _parts.keys.toList(),
  );
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: MeetingFieldRefusal(meetingEditRefusalText(_parts[part]!)),
  );
}
