import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_question_prompt.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_title_field.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_meeting_c.dart';

@widgetbook.UseCase(
  name: '모임 제목 칸',
  type: MeetingTitleField,
  path: '[모임]/모임 만들기',
)
Widget meetingTitleField(BuildContext context) {
  final knobs = context.knobs;
  final name = knobs.stringOrNull(
    label: '내 이름',
    description: '비워 둔 제목 대신 쓰는 제목(칸의 흐린 글)에 들어간다',
    initialValue: '모모',
  );
  final text = knobs.string(label: '입력한 제목');
  final submitting = knobs.boolean(
    label: '만드는 중',
    description: '화살표 대신 진행 표시를 두고 누를 수 없다',
  );
  // 앱에서는 마지막 질문('제목을 지어 주세요') 아래에 놓인다
  return meetingCreateFrame(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MeetingQuestionPrompt(
          headline: meetingTitleQuestion,
          guide: meetingTitleGuide,
        ),
        const SizedBox(height: 16),
        _Field(
          key: ValueKey(text),
          text: text,
          placeholder: meetingTitlePlaceholder(name),
          submitting: submitting,
        ),
      ],
    ),
  );
}

/// 입력한 글을 들고 있는 제목 칸
class _Field extends StatefulWidget {
  const _Field({
    super.key,
    required this.text,
    required this.placeholder,
    required this.submitting,
  });

  final String text;
  final String placeholder;
  final bool submitting;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final _controller = TextEditingController(text: widget.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MeetingTitleField(
      controller: _controller,
      placeholder: widget.placeholder,
      submitting: widget.submitting,
      onSubmit: () {},
    );
  }
}
