import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_brush_texts.dart';

/// 모임 설정에서 저장하지 못한 까닭을 그 칸 아래에 알리는 한 줄. 나타나면 스크린 리더가 읽는다
class MeetingFieldRefusal extends StatelessWidget {
  const MeetingFieldRefusal(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        liveRegion: true,
        child: Text(
          keepWords(text),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}
