import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 답한 질문의 한 줄 요약: 날짜(기간 · 제외), 방식(방식 · 시간), 공개(공개 여부 · 게스트). 답마다 누르면 그 질문을
/// 다시 묻는다([onEdit]). 날짜를 묻는 동안에는 날짜 줄을 두지 않는다(달력 위에 보인다)
class MeetingAnswerSummary extends StatelessWidget {
  const MeetingAnswerSummary({
    super.key,
    required this.flow,
    required this.onEdit,
  });

  final MeetingFlow flow;
  final ValueChanged<MeetingQuestion> onEdit;

  static const _groups = [
    (
      icon: Icons.event_outlined,
      questions: [MeetingQuestion.range, MeetingQuestion.exclusions],
    ),
    (
      icon: Icons.schedule_outlined,
      questions: [MeetingQuestion.mode, MeetingQuestion.time],
    ),
    (
      icon: Icons.public_outlined,
      questions: [MeetingQuestion.visibility, MeetingQuestion.guests],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final shown = flow.summarized.toSet();
    final datesAsked =
        flow.current == MeetingQuestion.range ||
        flow.current == MeetingQuestion.exclusions;
    if (datesAsked) {
      shown
        ..remove(MeetingQuestion.range)
        ..remove(MeetingQuestion.exclusions);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in _groups)
          if (group.questions.any(shown.contains))
            _SummaryRow(
              icon: group.icon,
              answers: [
                for (final question in group.questions)
                  if (shown.contains(question))
                    _SummaryChip(
                      label: _labelOf(question),
                      text: _textOf(question),
                      onTap: () => onEdit(question),
                    ),
              ],
            ),
      ],
    );
  }

  String _labelOf(MeetingQuestion question) => switch (question) {
    MeetingQuestion.range => '기간',
    MeetingQuestion.exclusions => '제외',
    MeetingQuestion.mode => '받는 방식',
    MeetingQuestion.time => '시간',
    MeetingQuestion.visibility => '공개 여부',
    MeetingQuestion.guests => '게스트',
    MeetingQuestion.title => '제목',
  };

  String _textOf(MeetingQuestion question) {
    final draft = flow.draft;
    return switch (question) {
      MeetingQuestion.range => meetingRangeText(draft.dates),
      MeetingQuestion.exclusions => meetingExclusionSummary(draft.dates),
      MeetingQuestion.mode => meetingModeLabel(draft.mode),
      MeetingQuestion.time => meetingHoursSummary(draft),
      MeetingQuestion.visibility =>
        draft.isPublic ? meetingPublic : meetingPrivate,
      MeetingQuestion.guests => meetingGuestSummary(draft.allowGuests),
      MeetingQuestion.title => '',
    };
  }
}

/// 요약 한 줄: 아이콘과 답들
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.answers});

  final IconData icon;
  final List<Widget> answers;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            child: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(child: Wrap(spacing: 4, children: answers)),
        ],
      ),
    );
  }
}

/// 답 하나. 누르면 그 질문을 다시 묻는다
class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.text,
    required this.onTap,
  });

  /// 스크린 리더가 앞에 읽는 질문 이름
  final String label;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: '$label: $text',
      hint: '눌러서 바꾸기',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
