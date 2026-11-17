import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_brush_texts.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_access_entries.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_access_note.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_section_title.dart';

/// 펼친 폼에서 공개를 끄면 보이는 '참여할 사람': 이메일·도메인 칸과 '지금은 나만 볼게요'. 대신 정해 주지 않으므로
/// 둘 다 없이 화살표를 눌렀으면([asked]) 그 아래에 정해야 만들 수 있다고 알린다
class MeetingFormAccess extends StatelessWidget {
  const MeetingFormAccess({
    super.key,
    required this.draft,
    required this.asked,
    required this.onChanged,
  });

  final MeetingDraft draft;
  final bool asked;
  final ValueChanged<MeetingDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = this.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MeetingSectionTitle(meetingFormAccessTitle),
        const SizedBox(height: 8),
        const MeetingAccessNote(),
        const SizedBox(height: 12),
        MeetingAccessEntries(
          emails: draft.emails,
          domains: draft.domains,
          enabled: !draft.onlyMe,
          onAdd: (entry) => onChanged(draft.withAccessEntry(entry)),
          onRemove: (value) => onChanged(draft.withoutAccessEntry(value)),
        ),
        CheckboxListTile(
          value: draft.onlyMe,
          onChanged: (value) => onChanged(draft.withOnlyMe(value ?? false)),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(meetingOnlyMe),
          subtitle: const Text(meetingOnlyMeExplain),
        ),
        if (asked && !draft.accessReady)
          Semantics(
            liveRegion: true,
            child: Text(
              keepWords(meetingFormAccessRequired),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
