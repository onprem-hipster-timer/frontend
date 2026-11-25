import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_edit_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_create_layout.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_meeting_a.dart';

@widgetbook.UseCase(
  name: '모임 만들기 화면 틀',
  type: MeetingCreateLayout,
  path: '[모임]/화면 틀',
)
Widget meetingCreateLayout(BuildContext context) {
  final knobs = context.knobs;
  final maxWidth = knobs.object.dropdown(
    label: '내용 최대 폭',
    description: '날짜를 묻는 동안 880, 그 밖의 질문은 640. 바꾸면 폭이 부드럽게 바뀐다',
    options: const [880.0, 640.0],
    labelBuilder: (width) => '${width.round()}',
  );
  final header = knobs.boolean(
    label: '맨 위 오른쪽 링크',
    initialValue: true,
    description: "질문 화면의 '전체 설정 펼치기'",
  );
  final footer = knobs.boolean(
    label: '맨 아래 오른쪽 단추',
    description: "모임 설정 화면의 '모임 삭제'",
  );
  final width = knobs.object.dropdown(
    label: '화면 폭',
    description: '720부터 내용을 카드에 담고 여백이 넓어진다',
    options: meetingWidthOptions.keys.toList(),
  );
  final scheme = Theme.of(context).colorScheme;
  return MeetingWidthFrame(
    width: meetingWidthOptions[width],
    child: MeetingCreateLayout(
      maxWidth: maxWidth,
      header: header
          ? TextButton.icon(
              onPressed: () {},
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: scheme.onSurfaceVariant,
              ),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text(meetingExpandAll),
            )
          : null,
      footer: footer
          ? TextButton.icon(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: scheme.error,
                minimumSize: const Size(48, 48),
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text(meetingDelete),
            )
          : null,
      // 틀이 넘기는 좁음·넓음에 따라 내용 자리를 쌓거나 나란히 둔다
      builder: (context, wide) {
        const first = _Slot(text: '질문과 답', height: 220);
        const second = _Slot(text: '달력', height: 320);
        return wide
            ? const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: first),
                  SizedBox(width: 40),
                  Expanded(child: second),
                ],
              )
            : const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [first, SizedBox(height: 16), second],
              );
      },
    ),
  );
}

/// 내용이 놓이는 자리 표시
class _Slot extends StatelessWidget {
  const _Slot({required this.text, required this.height});

  final String text;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
