import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:momeet/core/utils/time_formatters.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/utils/calendar_date_utils.dart';
import 'package:momeet/features/calendar/presentation/widgets/marquee_text.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_block_paint.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_time_slot_block.dart';
import 'package:momeet/features/calendar/presentation/widgets/shared_schedule_mark.dart';

/// SfCalendar의 appointmentBuilder가 그리는 일정 블록. 보기 종류에 맞는 모양을 고른다.
///
/// 마우스를 올린 블록은 다 들어가지 않는 제목을 흘려 보인다([MarqueeText]).
/// 칸에 다 들어가지 않아 숨긴 일정들의 자리는 숨긴 수를 +N으로 보인다.
/// 공유받은 일정([shared])은 옅은 바탕에 테두리를 두고 제목 앞에 [SharedScheduleMark]를 둔다.
class ScheduleAppointmentBlock extends StatefulWidget {
  const ScheduleAppointmentBlock({
    super.key,
    required this.details,
    required this.viewType,
    this.shared = false,
  });

  final CalendarAppointmentDetails details;
  final CalendarViewType viewType;
  final bool shared;

  @override
  State<ScheduleAppointmentBlock> createState() =>
      _ScheduleAppointmentBlockState();
}

class _ScheduleAppointmentBlockState extends State<ScheduleAppointmentBlock> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.details.isMoreAppointmentRegion) {
      return _MoreBlock(count: widget.details.appointments.length);
    }
    final appointment = widget.details.appointments.first as Appointment;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: switch (widget.viewType) {
        CalendarViewType.month => _MonthBlock(
          appointment: appointment,
          active: _hovered,
          shared: widget.shared,
        ),
        CalendarViewType.day || CalendarViewType.week => ScheduleTimeSlotBlock(
          appointment: appointment,
          height: widget.details.bounds.height,
          active: _hovered,
          shared: widget.shared,
        ),
        CalendarViewType.agenda || CalendarViewType.year => _AgendaBlock(
          appointment: appointment,
          active: _hovered,
          shared: widget.shared,
        ),
      },
    );
  }
}

/// 칸에 다 들어가지 않아 숨긴 일정 [count]개를 +N으로 보인다. 누르면 그날 일정 목록이 열린다
///
/// 칸 폭은 글자 배율을 따르지 않으므로 일정 칩과 같이 [monthChipMaxTextScale]까지만 키운다.
class _MoreBlock extends StatelessWidget {
  const _MoreBlock({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: monthChipMaxTextScale(constraints.maxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.centerLeft,
          child: Text(
            '+$count',
            semanticsLabel: '일정 $count개 더',
            maxLines: 1,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// 월 보기: 칸이 좁아 제목 한 줄만 보인다
///
/// 칸 폭은 글자 배율을 따르지 않으므로 글자는 [monthChipMaxTextScale]까지만 키운다.
class _MonthBlock extends StatelessWidget {
  const _MonthBlock({
    required this.appointment,
    required this.active,
    required this.shared,
  });

  final Appointment appointment;

  /// 제목을 흘려 보일지
  final bool active;
  final bool shared;

  static const _fontSize = 11.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: monthChipMaxTextScale(constraints.maxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 0.5),
          decoration: scheduleBlockDecoration(
            context,
            appointment.color,
            alpha: 0.9,
            shared: shared,
            radius: AppRadius.xsAll,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: Row(
            children: [
              if (shared)
                SharedScheduleMark(
                  color: scheduleBlockTextColor(
                    context,
                    appointment.color,
                    shared,
                  ),
                  size: _fontSize,
                ),
              Expanded(
                child: MarqueeText(
                  appointment.subject,
                  active: active,
                  style: TextStyle(
                    color: scheduleBlockTextColor(
                      context,
                      appointment.color,
                      shared,
                    ),
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 일정 목록 보기: 시작 시각과 제목 한 줄
class _AgendaBlock extends StatelessWidget {
  const _AgendaBlock({
    required this.appointment,
    required this.active,
    required this.shared,
  });

  final Appointment appointment;

  /// 제목을 흘려 보일지
  final bool active;
  final bool shared;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppRadius.smAll,
        border: Border(left: BorderSide(color: appointment.color, width: 3)),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            formatTime(appointment.startTime),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 10,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          if (shared)
            SharedScheduleMark(color: theme.colorScheme.onSurface, size: 11),
          Expanded(
            child: MarqueeText(
              appointment.subject,
              active: active,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
