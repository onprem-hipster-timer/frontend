import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_brush_texts.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_question_prompt.dart';
import 'package:momeet/shared/ui/ui.dart';

/// '이 범위에서 제외하고 싶은 날짜가 있나요?': 달력에서 뺀 날을 적고, 뺀 날이 없으면 '없어요', 있으면
/// '다 골랐어요'로 답한다. 뺄 수 있는 주말이 남았으면 '주말 제외'를, 늘 '기간 다시 고르기'를 둔다
class MeetingExclusionQuestion extends StatelessWidget {
  const MeetingExclusionQuestion({
    super.key,
    required this.flow,
    required this.onChanged,
  });

  final MeetingFlow flow;
  final ValueChanged<MeetingFlow> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flow = this.flow;
    final dates = flow.draft.dates;
    final excluded = dates.excluded;
    final weekends = dates.weekendsInside.any(dates.contains);
    final shape = const RoundedRectangleBorder(borderRadius: AppRadius.lgAll);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MeetingQuestionPrompt(
          headline: meetingExclusionQuestion,
          guide: meetingExclusionGuide,
        ),
        if (excluded.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            keepWords(meetingExcludedList(excluded)),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (weekends) ...[
          OutlinedButton.icon(
            onPressed: () => onChanged(flow.excludeWeekends()),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              shape: shape,
            ),
            icon: const Icon(Icons.weekend_outlined),
            label: const Text(meetingExcludeWeekends),
          ),
          const SizedBox(height: 8),
        ],
        FilledButton(
          onPressed: () => onChanged(
            excluded.isEmpty ? flow.skipExclusions() : flow.confirmExclusions(),
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            shape: shape,
          ),
          child: Text(
            excluded.isEmpty ? meetingExclusionNone : meetingExclusionDone,
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: () => onChanged(flow.edit(MeetingQuestion.range)),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: const Text(meetingRepickRange),
          ),
        ),
      ],
    );
  }
}
