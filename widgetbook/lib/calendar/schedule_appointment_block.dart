import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_appointment_block.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_plan.dart';

const _views = {
  '월간': CalendarViewType.month,
  '주간': CalendarViewType.week,
  '일간': CalendarViewType.day,
  '목록': CalendarViewType.agenda,
};

@widgetbook.UseCase(
  name: '달력 일정 블록',
  type: ScheduleAppointmentBlock,
  path: '[달력]',
)
Widget scheduleAppointmentBlock(BuildContext context) {
  final knobs = context.knobs;
  final view =
      _views[knobs.object.dropdown(
        label: '보기',
        description:
            '보기마다 모양이 다르다. 월간은 제목 한 줄, 주간·일간은 높이에 따라 시간과 설명까지, 목록은 시작 시각과 제목',
        options: _views.keys.toList(),
      )]!;
  final title = knobs.string(label: '제목', initialValue: '분기 계획 회의');
  final notes = knobs.string(
    label: '설명',
    description: '주간·일간에서 블록이 충분히 높을 때만 보인다. 비우면 설명이 없는 일정',
    initialValue: '지난 분기 회고 자료 같이 보기',
  );
  final minutes = knobs.int.slider(
    label: '일정 길이(분)',
    description: '주간·일간에서 블록 높이가 된다(한 시간에 60). 40보다 낮으면 제목만 작게 보인다',
    initialValue: 90,
    min: 15,
    max: 240,
    divisions: 15,
  );
  final tag = knobs.object.dropdown(
    label: '태그',
    description: '블록은 첫 태그의 색이다. 밝은 색 위에서는 글자가 검다',
    options: planTags,
    labelBuilder: (tag) => tag.name,
  );
  final more = knobs.boolean(
    label: '+N 자리',
    description: '월간 칸에 다 들어가지 않은 일정들 대신 숨긴 수를 보이는 자리. 누르면 그날 일정 목록이 열린다',
  );

  final scaler = MediaQuery.textScalerOf(context);
  final start = DateTime(2026, 3, 2, 10);
  final appointment = Appointment(
    subject: title,
    notes: notes.isEmpty ? null : notes,
    startTime: start,
    endTime: start.add(Duration(minutes: minutes)),
    color: HexColor.fromHex(tag.color),
  );
  // 폭 360 화면의 칸 크기: 월간은 7칸, 주간·일간은 시간 눈금(60)을 뺀 나머지, 목록은 날짜 머리(70)를 뺀 나머지
  final size = switch (view) {
    CalendarViewType.month => Size(360 / 7, scaler.scale(18)),
    CalendarViewType.week => Size(300 / 7, scaler.scale(60) * minutes / 60),
    CalendarViewType.day => Size(300, scaler.scale(60) * minutes / 60),
    CalendarViewType.agenda || CalendarViewType.year => const Size(290, 50),
  };
  return ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: Center(
      child: SizedBox.fromSize(
        size: size,
        child: ScheduleAppointmentBlock(
          viewType: view,
          details: CalendarAppointmentDetails(
            start,
            more ? List.filled(3, appointment) : [appointment],
            Offset.zero & size,
            isMoreAppointmentRegion: more,
          ),
        ),
      ),
    ),
  );
}
