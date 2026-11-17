import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_brush_texts.dart';

/// 모임 만들기 질문의 글: 앞 설명([lead]), 큰 질문([headline]), 아래 안내([guide]). 질문은 스크린 리더에
/// 머리글로 읽힌다. [answered]면 이미 답한 질문이라 질문 글자를 흐리게 한다(크기는 그대로). 줄은 띄어쓰기에서만
/// 바뀐다
class MeetingQuestionPrompt extends StatelessWidget {
  const MeetingQuestionPrompt({
    super.key,
    required this.headline,
    this.lead,
    this.guide,
    this.answered = false,
  });

  final String headline;
  final String? lead;
  final String? guide;
  final bool answered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lead = this.lead;
    final guide = this.guide;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lead != null) ...[
          Text(keepWords(lead), style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
        ],
        Semantics(
          header: true,
          child: Text(
            keepWords(headline),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: answered ? scheme.onSurfaceVariant : scheme.onSurface,
            ),
          ),
        ),
        if (guide != null) ...[
          const SizedBox(height: 6),
          Text(
            keepWords(guide),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
