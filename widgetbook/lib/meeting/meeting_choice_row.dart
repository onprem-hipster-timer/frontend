import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_choice_row.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_section_title.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '허용·비허용 고르기',
  type: MeetingChoiceRow,
  path: '[모임]/모임 만들기',
)
Widget meetingChoiceRow(BuildContext context) {
  final knobs = context.knobs;
  final label = knobs.object.dropdown(
    label: '항목',
    options: const ['공개 여부', '게스트 로그인'],
  );
  final disabled = knobs.boolean(
    label: '고를 수 없음',
    description: '공개 여부를 비허용으로 두면 게스트 로그인은 비허용으로 고정된다',
  );
  // 앱에서는 전체 설정 폼의 항목 제목 바로 아래에 놓인다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MeetingSectionTitle(label),
        _ChoiceHost(key: ValueKey(label), label: label, disabled: disabled),
      ],
    ),
  );
}

/// 누르면 고른 것이 바뀌도록 값을 쥔다
class _ChoiceHost extends StatefulWidget {
  const _ChoiceHost({super.key, required this.label, required this.disabled});

  final String label;
  final bool disabled;

  @override
  State<_ChoiceHost> createState() => _ChoiceHostState();
}

class _ChoiceHostState extends State<_ChoiceHost> {
  var _value = true;

  @override
  Widget build(BuildContext context) => MeetingChoiceRow(
    label: widget.label,
    value: widget.disabled ? false : _value,
    onChanged: widget.disabled
        ? null
        : (value) => setState(() => _value = value),
  );
}
