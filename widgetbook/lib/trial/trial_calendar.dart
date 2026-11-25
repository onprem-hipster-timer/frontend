import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/trial/presentation/utils/trial_samples.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_calendar.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_trial.dart';

@widgetbook.UseCase(name: '체험하기 달력', type: TrialCalendar, path: '[체험하기]')
Widget trialCalendar(BuildContext context) {
  final flow = trialStart(trialSampleNow);
  // 체험하기 첫 단계. 일주일 뒤 '어학 시험'과 같은 달 '길동이랑 저녁'이 있는 달을 연다.
  // 시험 날짜를 누르면 그날 일정 목록이 열린다
  return TrialCalendar(
    exam: flow.exam,
    dinner: flow.dinner,
    today: flow.now,
    onOpenExam: () {},
  );
}
