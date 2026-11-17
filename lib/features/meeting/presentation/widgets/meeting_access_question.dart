import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_access_entries.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_access_note.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_question_prompt.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 비공개를 고른 뒤의 질문: 참여할 사람의 이메일·도메인을 하나씩 넣고 '다 넣었어요'로 답한다(하나 이상).
/// 초대 메일은 보내지 않는다고 알리고, 아직 넣을 이메일이 없으면 '지금은 나만 볼게요'로 나만 보는 비공개로 답한다
class MeetingAccessQuestion extends StatelessWidget {
  const MeetingAccessQuestion({
    super.key,
    required this.flow,
    required this.onChanged,
  });

  final MeetingFlow flow;
  final ValueChanged<MeetingFlow> onChanged;

  @override
  Widget build(BuildContext context) {
    final flow = this.flow;
    final draft = flow.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MeetingQuestionPrompt(
          headline: meetingAccessQuestion,
          guide: meetingAccessGuide,
        ),
        const SizedBox(height: 12),
        const MeetingAccessNote(),
        const SizedBox(height: 16),
        MeetingAccessEntries(
          emails: draft.emails,
          domains: draft.domains,
          onAdd: (entry) => onChanged(flow.addAccessEntry(entry)),
          onRemove: (value) => onChanged(flow.removeAccessEntry(value)),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: draft.accessEntryCount == 0
              ? null
              : () => onChanged(flow.confirmAccess()),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          ),
          child: const Text(meetingAccessDone),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: () => onChanged(flow.keepPrivate()),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: const Text(meetingOnlyMe),
          ),
        ),
      ],
    );
  }
}
