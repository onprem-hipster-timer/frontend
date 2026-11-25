import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_timer_dashboard.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_trial.dart';

@widgetbook.UseCase(name: '체험하기 타이머', type: TrialTimerDashboard, path: '[체험하기]')
Widget trialTimerDashboard(BuildContext context) {
  final minutes = context.knobs.double.slider(
    label: '남은 분',
    initialValue: 12.5,
    max: 25,
    description: '0이면 시간 종료로 보인다',
  );
  // 체험하기 타이머 단계. 눌러도 아무것도 바뀌지 않는다
  return TrialTimerDashboard(
    timer: trialSampleStarted().timer!,
    remaining: Duration(seconds: (minutes * 60).round()),
  );
}
