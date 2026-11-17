import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_brush_texts.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_adjustment_notice.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_answer_summary.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_calendar.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_create_layout.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_current_question.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_exclusion_question.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_question_prompt.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_reveal_step.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 모임 만들기를 한 번에 한 질문씩 묻는 화면([MeetingFlow]). 위에 답한 질문의 요약과 묻지 않고 맞춘 것의 알림,
/// 그 아래 지금 질문 하나를 둔다. 새 질문은 답한 뒤에만 나타나며 펼쳐진다([animate]).
///
/// 날짜(기간·제외)를 묻는 동안은 '언제 모일까요?'와 달력을 둔다. 좁으면 질문 글 → 달력 → 지금 질문 차례로
/// 쌓고, 넓으면 왼쪽에 글과 질문, 오른쪽에 달력을 둔다. 어느 쪽이든 기간을 고른 뒤 제외를 물을 때 달력 위의 것은
/// 높이가 같아(안내 줄이 기간 답으로 바뀐다) 달력이 누르던 자리에서 움직이지 않는다. 날짜를 다 물으면 달력 없이
/// 한 칸으로 좁힌다. 맨 아래 오른쪽의 '전체 설정 펼치기'로 모든 설정을 한 폼으로 펼친다([onExpand]).
///
/// 테스트: test/features/meeting/presentation/pages/meeting_create_page_test.dart
class MeetingCreateQuestions extends StatelessWidget {
  const MeetingCreateQuestions({
    super.key,
    required this.flow,
    required this.today,
    required this.animate,
    required this.timezone,
    required this.titleField,
    required this.onChanged,
    required this.onExpand,
  });

  final MeetingFlow flow;
  final DateTime today;

  /// 새로 나타나는 질문을 펼치며 보일지(처음 질문과 되살린 폼은 그대로 보인다)
  final bool animate;

  /// 아직 모르면 null
  final String? timezone;

  /// 제목 칸과 만들기 화살표
  final Widget titleField;

  final ValueChanged<MeetingFlow> onChanged;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final flow = this.flow;
    final current = flow.current;
    final datesAsked =
        current == MeetingQuestion.range ||
        current == MeetingQuestion.exclusions;
    final above = _Above(flow: flow, onChanged: onChanged);
    final keep = flow.editing == null
        ? null
        : _KeepButton(onPressed: () => onChanged(flow.keep()));
    return MeetingCreateLayout(
      maxWidth: datesAsked ? 880 : 640,
      footer: _ExpandLink(onPressed: onExpand),
      builder: (context, wide) {
        if (!datesAsked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              above,
              _Asked(
                key: ValueKey(current),
                question: current,
                animate: animate,
                child: MeetingCurrentQuestion(
                  flow: flow,
                  timezone: timezone,
                  titleField: titleField,
                  onChanged: onChanged,
                ),
              ),
              ?keep,
            ],
          );
        }
        return _DatesStep(
          flow: flow,
          today: today,
          wide: wide,
          above: above,
          keep: keep,
          animate: animate,
          onChanged: onChanged,
        );
      },
    );
  }
}

/// 날짜(기간·제외)를 묻는 동안: '언제 모일까요?', 달력, 지금 질문. 좁으면 글 → 달력 → 질문으로 쌓고, 넓으면
/// 왼쪽에 글과 질문, 오른쪽에 달력을 둔다
class _DatesStep extends StatelessWidget {
  const _DatesStep({
    required this.flow,
    required this.today,
    required this.wide,
    required this.above,
    required this.keep,
    required this.animate,
    required this.onChanged,
  });

  final MeetingFlow flow;
  final DateTime today;
  final bool wide;
  final Widget above;
  final Widget? keep;
  final bool animate;
  final ValueChanged<MeetingFlow> onChanged;

  static const _calendarWidth = 380.0;

  @override
  Widget build(BuildContext context) {
    final flow = this.flow;
    final ranging = flow.current == MeetingQuestion.range;
    final calendar = MeetingCalendar(
      firstDay: today,
      shownDay:
          flow.rangeStart ??
          (flow.draft.dates.isEmpty ? null : flow.draft.dates.first),
      stateOf: (day) => flow.dayState(day, today: today),
      onDayTap: (day) => _tapDay(context, day),
    );
    final prompt = MeetingQuestionPrompt(
      headline: meetingRangeQuestion,
      guide: ranging ? meetingRangeGuide : meetingRangeAnswer(flow.draft.dates),
      answered: !ranging,
    );
    final below = _Asked(
      key: ValueKey(flow.current),
      question: flow.current,
      animate: animate,
      child: ranging
          ? _RangeHint(start: flow.rangeStart)
          : MeetingExclusionQuestion(flow: flow, onChanged: onChanged),
    );
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          above,
          prompt,
          const SizedBox(height: 16),
          calendar,
          const SizedBox(height: 20),
          below,
          ?keep,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [above, prompt, const SizedBox(height: 24), below, ?keep],
          ),
        ),
        const SizedBox(width: 40),
        SizedBox(width: _calendarWidth, child: calendar),
      ],
    );
  }

  /// 제외를 묻는 동안 첫날·마지막 날을 누르면 뺄 수 없다고 알린다
  void _tapDay(BuildContext context, DateTime day) {
    final dates = flow.draft.dates;
    if (flow.current == MeetingQuestion.exclusions &&
        dates.inPeriod(day) &&
        !dates.canExclude(day)) {
      showAppSnackBar(context, meetingEndsNotExcludable);
      return;
    }
    onChanged(flow.tapDay(day));
  }
}

/// 지금 질문 위: 답한 질문의 요약(날짜를 묻는 동안은 날짜 줄 없이)과 묻지 않고 맞춘 것의 알림
class _Above extends StatelessWidget {
  const _Above({required this.flow, required this.onChanged});

  final MeetingFlow flow;
  final ValueChanged<MeetingFlow> onChanged;

  @override
  Widget build(BuildContext context) {
    final flow = this.flow;
    final datesAsked =
        flow.current == MeetingQuestion.range ||
        flow.current == MeetingQuestion.exclusions;
    final summarized = flow.summarized.any(
      (question) =>
          !datesAsked ||
          (question != MeetingQuestion.range &&
              question != MeetingQuestion.exclusions),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summarized) ...[
          MeetingAnswerSummary(
            flow: flow,
            onEdit: (question) => onChanged(flow.edit(question)),
          ),
          const SizedBox(height: 16),
        ],
        if (flow.adjusted.isNotEmpty) ...[
          MeetingAdjustmentNotice(adjusted: flow.adjusted, draft: flow.draft),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

/// 지금 질문. 답한 뒤 새로 나타나면 요약이 바뀐 것을 본 뒤 펼쳐지고 스크린 리더에 질문을 알린다
class _Asked extends StatelessWidget {
  const _Asked({
    super.key,
    required this.question,
    required this.animate,
    required this.child,
  });

  final MeetingQuestion question;
  final bool animate;
  final Widget child;

  @override
  Widget build(BuildContext context) => MeetingRevealStep(
    animate: animate,
    delay: const Duration(milliseconds: 120),
    announcement: switch (question) {
      MeetingQuestion.range => meetingRangeQuestion,
      MeetingQuestion.exclusions => meetingExclusionQuestion,
      MeetingQuestion.mode => meetingModeQuestion,
      MeetingQuestion.time => meetingHoursQuestion,
      MeetingQuestion.visibility => meetingVisibilityQuestion,
      MeetingQuestion.guests => meetingGuestQuestion,
      MeetingQuestion.title => meetingTitleQuestion,
    },
    child: child,
  );
}

/// 기간을 고르는 동안 달력 아래의 안내: 하루만 고르는 법, 시작일을 눌렀으면 끝나는 날을 누르라는 말
class _RangeHint extends StatelessWidget {
  const _RangeHint({required this.start});

  final DateTime? start;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = this.start;
    final color = start == null
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          start == null ? Icons.touch_app_outlined : Icons.east,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            keepWords(
              start == null
                  ? meetingRangeOneDayHint
                  : meetingRangeStartedHint(start),
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: start == null ? null : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// 다시 묻는 질문을 바꾸지 않고 닫는 '그대로 둘게요'
class _KeepButton extends StatelessWidget {
  const _KeepButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        child: const Text(meetingKeepAnswer),
      ),
    ),
  );
}

/// '전체 설정 펼치기 →': 모든 설정을 한 폼으로 펼친다
class _ExpandLink extends StatelessWidget {
  const _ExpandLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      iconAlignment: IconAlignment.end,
      icon: const Icon(Icons.arrow_forward, size: 18),
      label: const Text(meetingExpandAll),
    );
  }
}
