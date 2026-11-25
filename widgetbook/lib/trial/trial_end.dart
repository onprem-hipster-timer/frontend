import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/trial/presentation/utils/trial_samples.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_end.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_meeting_preview.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/app_route.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_trial.dart';

@widgetbook.UseCase(name: '체험하기 끝', type: TrialEnd, path: '[체험하기]')
Widget trialEnd(BuildContext context) {
  final flow = trialSampleStarted().openTimer().finishTimer();
  // 체험하기 마지막 단계. 가입하기를 누르면 회원가입 화면으로, 모임 만들기를 누르면 모임 만들기 화면으로 간다.
  // 모임 만들기 줄 밑(넓으면 옆)의 모임 화면 그림은 누르는 것이 없다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: TrialEnd(
      todo: flow.todo!,
      recordedSeconds: flow.recordedSeconds,
      onSignUp: () => context.goNamed(AppRoute.signup.name),
      onCreateMeeting: () => context.pushNamed(AppRoute.meetings.name),
      meetingPreview: TrialMeetingPreview(
        board: trialMeeting(flow),
        email: trialMeetingEmail,
      ),
    ),
  );
}
