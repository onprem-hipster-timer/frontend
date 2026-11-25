import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_prompt.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../meeting/samples_meeting_c.dart';

@widgetbook.UseCase(name: '앞 줄과 한 줄', type: TrialPrompt, path: '[체험하기]')
Widget trialPrompt(BuildContext context) {
  final reward = context.knobs.boolean(
    label: '보상 줄',
    description: '방금 누른 것으로 얻은 것을 말하는 앞 줄이면 낱말마다 먼저 나타나고, 큰 한 줄이 뒤따른다',
    initialValue: true,
  );
  final reduce = context.knobs.boolean(
    label: '애니메이션 줄이기',
    description: meetingReduceMotionDescription,
  );
  return meetingMotionSetting(
    context,
    reduce: reduce,
    child: meetingCreateFrame(
      MeetingReplay(
        label: '다시 나타나기',
        // 체험하기에서 할 일로 바꾼 뒤와 바꾸기 전의 글
        builder: (context, count) => TrialPrompt(
          key: ValueKey(count),
          lead: reward ? trialConvertedLead : trialScheduleLead,
          headline: reward ? trialConvertedHeadline : trialScheduleHeadline,
          reward: reward,
        ),
      ),
    ),
  );
}
