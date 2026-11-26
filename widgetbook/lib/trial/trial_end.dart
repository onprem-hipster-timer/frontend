import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/trial/presentation/utils/trial_samples.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_end.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_meeting_preview.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/app_route.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_trial.dart';

@widgetbook.UseCase(name: '체험하기 끝', type: TrialEnd, path: '[체험하기]')
Widget trialEnd(BuildContext context) {
  final flow = trialSampleStarted().openTimer().finishTimer();
  final expanded = context.knobs.boolean(
    label: '물음을 펼침',
    description:
        '가입하기 아래의 물음을 누르면 답 한 줄, 모임 만들기, 모임 화면 그림이 펼쳐진다. 다시 누르면 접힌다. '
        '체험하기에서는 끝에 올 때마다 접혀 있다',
  );
  // 체험하기 마지막 단계. 가입하기를 누르면 회원가입 화면으로, 모임 만들기를 누르면 모임 만들기 화면으로 간다.
  // 가입하기 아래 링크는 앱에서 개인정보 보호 조치 안내를 새 탭으로 연다(카탈로그에서는 열지 않는다).
  // 답 한 줄 밑(넓으면 옆)의 모임 화면 그림은 누르는 것이 없다
  return SingleChildScrollView(
    key: ValueKey(expanded),
    padding: const EdgeInsets.all(16),
    child: TrialEnd(
      todo: flow.todo!,
      recordedSeconds: flow.recordedSeconds,
      onSignUp: () => context.goNamed(AppRoute.signup.name),
      onOpenTrust: () {},
      onCreateMeeting: () => context.pushNamed(AppRoute.meetings.name),
      meetingPreview: TrialMeetingPreview(
        board: trialMeeting(flow),
        email: trialMeetingEmail,
      ),
      initiallyExpanded: expanded,
    ),
  );
}
