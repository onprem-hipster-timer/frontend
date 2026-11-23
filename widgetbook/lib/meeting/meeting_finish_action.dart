import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_finish_action.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _phases = {
  '자동 저장됨': MeetingFinishPhase.autosaved,
  '자동 저장 중': MeetingFinishPhase.autosaving,
  '누른 뒤 저장하는 중': MeetingFinishPhase.saving,
  '입력을 마침': MeetingFinishPhase.done,
  '저장 실패': MeetingFinishPhase.failed,
};

@widgetbook.UseCase(
  name: '저장하기 버튼과 저장 상태',
  type: MeetingFinishAction,
  path: '[모임]/되는 시간 칠하기',
)
Widget meetingFinishAction(BuildContext context) {
  final knobs = context.knobs;
  final phase = knobs.object.dropdown(
    label: '상태',
    description: '내 시간을 칠하면 저절로 저장하고, 저장하기를 누르면 입력을 마친다',
    options: _phases.keys.toList(),
  );
  final pinned = knobs.boolean(
    label: '화면 아래 띠',
    description: '좁은 화면에서는 화면 아래에 붙고, 넓은 화면에서는 격자 아래 오른쪽에 놓인다',
    initialValue: true,
  );
  final action = MeetingFinishAction(
    phase: _phases[phase]!,
    pinned: pinned,
    onPressed: () {},
  );
  if (pinned) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [const Spacer(), action],
    );
  }
  return Padding(padding: const EdgeInsets.all(16), child: action);
}
