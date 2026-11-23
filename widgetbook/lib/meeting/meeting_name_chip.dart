import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_name_chip.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '참여자 이름 칩', type: MeetingNameChip, path: '[모임]/참여자')
Widget meetingNameChip(BuildContext context) {
  final knobs = context.knobs;
  final name = knobs.string(label: '이름', initialValue: '모모');
  final owner = knobs.boolean(label: '주인', initialValue: true);
  final guest = knobs.boolean(label: '게스트');
  final self = knobs.boolean(label: '나');
  final dense = knobs.boolean(label: '작게', description: '추천 시간 카드 안처럼 좁은 곳');
  final action = knobs.object.dropdown(
    label: '버튼',
    description: '일정 참여자를 고칠 때 이름 뒤에 두는 버튼',
    options: const ['없음', '빼기', '내 닉네임 바꾸기'],
  );
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: MeetingNameChip(
        name: name,
        owner: owner,
        guest: guest,
        self: self,
        dense: dense,
        onRemove: action == '빼기' ? () {} : null,
        onRename: action == '내 닉네임 바꾸기' ? () {} : null,
      ),
    ),
  );
}
