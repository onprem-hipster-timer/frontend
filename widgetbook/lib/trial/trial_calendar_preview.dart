import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/trial/presentation/utils/trial_samples.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_calendar_preview.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_trial.dart';

@widgetbook.UseCase(
  name: '랜딩 미리보기 달력',
  type: TrialCalendarPreview,
  path: '[체험하기]',
)
Widget trialCalendarPreview(BuildContext context) {
  final now = context.knobs.object
      .dropdown(
        label: '체험을 연 날',
        options: [
          (trialSampleNow, '3월 4일: 토익 11일, 저녁 8일'),
          (
            DateTime(2026, 3, 25, 14),
            '3월 25일: 토익 4월 1일, 저녁 4월 4일(앞 달 끝에서 시작하는 주)',
          ),
          (
            DateTime(2026, 11, 25, 14),
            '11월 25일: 토익 12월 2일, 저녁 12월 5일(사흘 전이 앞 달)',
          ),
        ],
        labelBuilder: (option) => option.$2,
        description: '시험은 일주일 뒤, 약속은 그 사흘 전(앞 달이면 사흘 뒤). 두 일정이 든 두 주만 보인다',
      )
      .$1;
  final flow = trialStart(now);
  // 랜딩의 캘린더 소개에 찍어 두는 그림. 누르는 것은 아무것도 하지 않는다
  return Padding(
    padding: const EdgeInsets.all(8),
    child: SizedBox(
      height: 230,
      child: TrialCalendarPreview(
        exam: flow.exam,
        dinner: flow.dinner,
        today: flow.now,
      ),
    ),
  );
}
