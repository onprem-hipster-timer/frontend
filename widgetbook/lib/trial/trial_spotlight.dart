import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/trial/presentation/utils/trial_spotlights.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_spotlight.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_todo_row.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_trial.dart';

@widgetbook.UseCase(name: '누를 것 강조', type: TrialSpotlight, path: '[체험하기]')
Widget trialSpotlight(BuildContext context) {
  final started = context.knobs.boolean(
    label: '타이머 시작함',
    description: '시작 전에는 재생 버튼을, 시작한 뒤에는 남은 시간을 강조한다. 애니메이션을 줄이면 테두리만 남는다',
  );
  final shown = started ? trialSampleStarted() : trialSampleConverted();
  // 체험하기 할 일 단계. 강조한 컨트롤은 그대로 누를 수 있다
  return Padding(
    padding: const EdgeInsets.all(16),
    child: TrialSpotlight(
      target: trialSpotlightOf(shown),
      child: Card.outlined(
        margin: EdgeInsets.zero,
        child: TrialTodoRow(
          todo: shown.todo!,
          timer: shown.timer,
          onStartTimer: () {},
          onOpenTimer: () {},
        ),
      ),
    ),
  );
}
