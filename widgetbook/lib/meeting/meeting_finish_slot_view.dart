import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_finish_action.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_finish_slot_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _phases = {
  '바꾸기 전': null,
  '자동 저장 중': MeetingFinishPhase.autosaving,
  '자동 저장됨': MeetingFinishPhase.autosaved,
  '누른 뒤 저장하는 중': MeetingFinishPhase.saving,
  '입력을 마침': MeetingFinishPhase.done,
  '저장 실패': MeetingFinishPhase.failed,
};

@widgetbook.UseCase(
  name: '저장하기 자리와 Ctrl+S',
  type: MeetingFinishSlotView,
  path: '[모임]/내 시간 선택하기',
)
Widget meetingFinishSlotView(BuildContext context) {
  final knobs = context.knobs;
  final phase = knobs.object.dropdown(
    label: '상태',
    description: '내 시간을 바꾸기 전에는 비어 있고, 바꾸면 저절로 저장하는 상태와 저장하기를 보인다',
    options: _phases.keys.toList(),
    initialOption: '자동 저장됨',
  );
  final pinned = knobs.boolean(
    label: '화면 아래 띠',
    description: '좁은 화면에서는 화면 아래에 붙고, 넓은 화면에서는 격자 아래 오른쪽에 놓인다',
    initialValue: true,
  );
  // 앱에서는 Ctrl+S(macOS는 Cmd+S)를 받으면 그때 누를 수 있는 저장하기를 누르고, 누를 단추가 없어도 키를
  // 받아 브라우저가 페이지 저장을 열지 않는다
  return _FinishSlotPreview(phase: _phases[phase], pinned: pinned);
}

/// 저장하기 자리와 마지막으로 받은 누르기·키
class _FinishSlotPreview extends StatefulWidget {
  const _FinishSlotPreview({required this.phase, required this.pinned});

  final MeetingFinishPhase? phase;
  final bool pinned;

  @override
  State<_FinishSlotPreview> createState() => _FinishSlotPreviewState();
}

class _FinishSlotPreviewState extends State<_FinishSlotPreview> {
  var _last = '아직 누르지 않았어요';
  var _count = 0;

  void _receive(String label) => setState(() {
    _count++;
    _last = '$label ($_count)';
  });

  @override
  Widget build(BuildContext context) {
    final slot = MeetingFinishSlotView(
      phase: widget.phase,
      pinned: widget.pinned,
      onPressed: () => _receive('저장하기'),
      onSaveKey: () => _receive('Ctrl+S'),
    );
    final readout = Padding(
      padding: const EdgeInsets.all(16),
      child: Text(_last, style: Theme.of(context).textTheme.titleMedium),
    );
    if (widget.pinned) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [readout, const Spacer(), slot],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        readout,
        Padding(padding: const EdgeInsets.all(16), child: slot),
      ],
    );
  }
}
