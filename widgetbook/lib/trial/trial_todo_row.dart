import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_todo_row.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_trial.dart';

@widgetbook.UseCase(name: '체험하기 할 일 줄', type: TrialTodoRow, path: '[체험하기]')
Widget trialTodoRow(BuildContext context) {
  final state = context.knobs.object.dropdown(
    label: '상태',
    options: const ['시작 전', '타이머 도는 중'],
    description: '시작 전에는 타이머 시작 버튼을, 시작한 뒤에는 남은 시간과 누적 시간을 보인다',
  );
  final flow = trialSampleStarted();
  // 체험하기 할 일 단계. 시작 버튼과 남은 시간만 누를 수 있다
  return Card.outlined(
    margin: const EdgeInsets.all(16),
    child: TrialTodoRow(
      todo: flow.todo!,
      timer: state == '시작 전' ? null : flow.timer,
      onStartTimer: () {},
      onOpenTimer: () {},
    ),
  );
}
