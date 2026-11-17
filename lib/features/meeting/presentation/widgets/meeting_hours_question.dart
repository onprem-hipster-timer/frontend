import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_answer_buttons.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_question_prompt.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_time_range.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_timezone_label.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 시간별의 하루 범위 질문: '6시부터 18시까지로 할까요?'에 예/아니요. '아니요'면 '몇 시부터 몇 시까지로
/// 할까요?'로 바꿔 시작·끝 시각을 고르고 '이 시간으로 할게요'로 답한다
class MeetingHoursQuestion extends StatelessWidget {
  const MeetingHoursQuestion({
    super.key,
    required this.flow,
    required this.timezone,
    required this.onChanged,
  });

  final MeetingFlow flow;

  /// 아직 모르면 null
  final String? timezone;

  final ValueChanged<MeetingFlow> onChanged;

  @override
  Widget build(BuildContext context) {
    final flow = this.flow;
    final draft = flow.draft;
    final timezone = this.timezone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MeetingQuestionPrompt(
          headline: flow.pickingHours
              ? meetingHoursPickQuestion
              : meetingHoursQuestion,
          guide: meetingHoursGuide,
        ),
        if (timezone != null) ...[
          const SizedBox(height: 8),
          MeetingTimezoneLabel(timezone),
        ],
        const SizedBox(height: 20),
        if (flow.pickingHours) ...[
          MeetingTimeRange(
            startHour: draft.startHour,
            endHour: draft.endHour,
            onStartChanged: (hour) => onChanged(flow.withStartHour(hour)),
            onEndChanged: (hour) => onChanged(flow.withEndHour(hour)),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => onChanged(flow.confirmHours()),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 52),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.lgAll,
              ),
            ),
            child: const Text(meetingHoursConfirm),
          ),
        ] else
          MeetingAnswerButtons(
            answers: [
              (
                label: meetingYes,
                onPressed: () => onChanged(flow.acceptDefaultHours()),
              ),
              (label: meetingNo, onPressed: () => onChanged(flow.pickHours())),
            ],
          ),
      ],
    );
  }
}
