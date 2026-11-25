import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/calendar.dart'
    show ScheduleAppointmentBlock;
import 'package:momeet/features/todo/todo.dart' show TodoTimerStartButtonView;
import 'package:momeet/features/trial/domain/trial_flow.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_spotlight.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' show Appointment;

/// [flow]에서 다음에 누를 컨트롤: 달력의 시험, '할 일로 변환'(바꾼 뒤에는 '연결된 할 일 보기'), 타이머 시작
/// 단추(시작한 뒤에는 남은 시간). 타이머와 끝에는 없다
TrialSpotlightTarget? trialSpotlightOf(TrialFlow flow) => switch (flow.step) {
  TrialStep.calendar => TrialSpotlightTarget.ofType<ScheduleAppointmentBlock>(
    id: TrialStep.calendar,
    radius: AppRadius.xs,
    where: (block) =>
        !block.details.isMoreAppointmentRegion &&
        (block.details.appointments.first as Appointment).id == flow.exam.id,
  ),
  TrialStep.schedule => TrialSpotlightTarget.button(
    flow.todo == null
        ? '${Terms.todo.withJosa('으로', '로')} 변환'
        : '연결된 ${Terms.todo} 보기',
    radius: AppRadius.lg,
  ),
  TrialStep.todo =>
    flow.timer == null
        ? TrialSpotlightTarget.ofType<TodoTimerStartButtonView>(
            id: TodoTimerStartButtonView,
            radius: AppRadius.pill,
          )
        : TrialSpotlightTarget.ofType<ActionChip>(
            id: ActionChip,
            radius: AppRadius.md,
          ),
  TrialStep.timer || TrialStep.end => null,
};
