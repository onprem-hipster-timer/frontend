import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/trial/presentation/utils/trial_samples.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_meeting_preview.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_trial.dart';

@widgetbook.UseCase(name: '모임 화면 그림', type: TrialMeetingPreview, path: '[체험하기]')
Widget trialMeetingPreview(BuildContext context) {
  final size = context.knobs.object.dropdown(
    label: '그림 크기',
    options: const [Size(180, 450), Size(360, 900), Size(240, 300)],
    labelBuilder: (size) => switch (size) {
      Size(width: 180) => '180×450 (체험하기 끝)',
      Size(width: 360) => '360×900 (줄이지 않음)',
      _ => '240×300 (낮은 칸: 위쪽만)',
    },
    description: '폭 360 휴대폰의 모임 화면을 칸의 폭에 맞게 줄인다. 칸이 낮으면 화면의 위쪽만 보인다',
  );
  // 약속 일정으로 만든 모임에 넷이 시간을 넣었고, 첫 추천 시간을 펼쳐 둔다. 누르는 것은 아무것도 하지 않는다
  return Center(
    child: SizedBox.fromSize(
      size: size,
      child: TrialMeetingPreview(
        board: trialMeeting(trialStart(trialSampleNow)),
        email: trialMeetingEmail,
      ),
    ),
  );
}
