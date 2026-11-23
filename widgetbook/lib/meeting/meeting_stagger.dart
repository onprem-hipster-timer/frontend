import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_answer_buttons.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_stagger.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_step_switcher.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_meeting_c.dart';

@widgetbook.UseCase(
  name: '질문 차례로 나타나기',
  type: MeetingStagger,
  path: '[모임]/화면 틀',
)
Widget meetingStagger(BuildContext context) {
  final reduce = context.knobs.boolean(
    label: '애니메이션 줄이기',
    description: meetingReduceMotionDescription,
  );
  final theme = Theme.of(context);
  // 조각은 질문이 넘어갈 때만 움직이므로 같은 질문을 다시 넘겨 보인다
  return meetingMotionSetting(
    context,
    reduce: reduce,
    child: meetingCreateFrame(
      MeetingReplay(
        label: '다시 나타나기',
        builder: (context, count) => MeetingStepSwitcher(
          step: count,
          announcement: meetingGuestQuestion,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MeetingStagger(
                order: 0,
                child: Text(
                  meetingGuestQuestion,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              MeetingStagger(
                order: 1,
                child: Text(
                  meetingGuestExplain,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              MeetingStagger(
                order: 2,
                child: MeetingAnswerButtons(
                  answers: [
                    (label: meetingAllowGuests, onPressed: () {}),
                    (label: meetingRefuseGuests, onPressed: () {}),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
