import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_help_icon.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '도움말 물음표', type: MeetingHelpIcon, path: '[모임]/화면 틀')
Widget meetingHelpIcon(BuildContext context) {
  final knobs = context.knobs;
  final title = knobs.string(label: '제목', initialValue: '공개 여부');
  final message = knobs.string(
    label: '도움말',
    description: '물음표를 누르거나 마우스를 올리면 뜨는 말',
    initialValue: '허용하면 링크가 있는 누구나 이 모임을 볼 수 있습니다. 비허용이면 나만 볼 수 있습니다.',
  );
  // 앱에서는 설정 제목이나 상자 제목 바로 뒤에 붙는다
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Flexible(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        MeetingHelpIcon(message),
      ],
    ),
  );
}
