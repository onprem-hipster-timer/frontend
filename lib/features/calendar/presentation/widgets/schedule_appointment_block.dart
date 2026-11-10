import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:momeet/core/utils/time_formatters.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/utils/calendar_date_utils.dart';
import 'package:momeet/features/calendar/presentation/widgets/marquee_text.dart';

/// SfCalendar의 appointmentBuilder가 그리는 일정 블록. 보기 종류에 맞는 모양을 고른다.
///
/// 마우스를 올린 블록은 다 들어가지 않는 제목을 흘려 보인다([MarqueeText]).
class ScheduleAppointmentBlock extends StatefulWidget {
  const ScheduleAppointmentBlock({
    super.key,
    required this.details,
    required this.viewType,
  });

  final CalendarAppointmentDetails details;
  final CalendarViewType viewType;

  @override
  State<ScheduleAppointmentBlock> createState() =>
      _ScheduleAppointmentBlockState();
}

class _ScheduleAppointmentBlockState extends State<ScheduleAppointmentBlock> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final appointment = widget.details.appointments.first as Appointment;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: switch (widget.viewType) {
        CalendarViewType.month => _MonthBlock(
          appointment: appointment,
          active: _hovered,
        ),
        CalendarViewType.day || CalendarViewType.week => _TimeSlotBlock(
          appointment: appointment,
          height: widget.details.bounds.height,
          active: _hovered,
        ),
        CalendarViewType.agenda || CalendarViewType.year => _AgendaBlock(
          appointment: appointment,
          active: _hovered,
        ),
      },
    );
  }
}

/// 월 보기: 칸이 좁아 제목 한 줄만 보인다
///
/// 칸 폭은 글자 배율을 따르지 않으므로 글자는 [monthChipMaxTextScale]까지만 키운다.
class _MonthBlock extends StatelessWidget {
  const _MonthBlock({required this.appointment, required this.active});

  final Appointment appointment;

  /// 제목을 흘려 보일지
  final bool active;

  static const _fontSize = 11.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: monthChipMaxTextScale(constraints.maxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 0.5),
          decoration: BoxDecoration(
            color: appointment.color.withValues(alpha: 0.9),
            borderRadius: AppRadius.xsAll,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: MarqueeText(
            appointment.subject,
            active: active,
            style: TextStyle(
              color: _contrastOn(appointment.color),
              fontSize: _fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// 일·주 보기: 블록 [height]에 따라 시간과 설명을 더 보인다
class _TimeSlotBlock extends StatelessWidget {
  const _TimeSlotBlock({
    required this.appointment,
    required this.height,
    required this.active,
  });

  final Appointment appointment;
  final double height;

  /// 제목을 흘려 보일지
  final bool active;

  @override
  Widget build(BuildContext context) {
    final isShortEvent = height < 40;
    final notes = (appointment.notes?.isEmpty ?? true)
        ? null
        : appointment.notes;
    final titleStyle = TextStyle(
      color: _contrastOn(appointment.color),
      fontSize: isShortEvent ? 11 : 12,
      fontWeight: FontWeight.w600,
    );
    final lines = _BlockLines.fit(
      context,
      // 바깥 여백 1씩과 위아래 안쪽 여백을 뺀 높이
      height: height - 2 - (isShortEvent ? 4 : 8),
      titleStyle: titleStyle,
      maxTitleLines: isShortEvent ? 1 : 2,
      hasNotes: notes != null && !isShortEvent,
      showTime: !isShortEvent,
    );

    return _BlockFrame(
      color: appointment.color,
      child: ClipRRect(
        borderRadius: AppRadius.smAll,
        child: Stack(
          children: [
            // 왼쪽 색상 바
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: appointment.color),
            ),
            // 내용
            Padding(
              padding: EdgeInsets.only(
                left: 8,
                right: 4,
                top: isShortEvent ? 2 : 4,
                bottom: isShortEvent ? 2 : 4,
              ),
              // 제목 한 줄도 들어가지 않는 블록은 넘치지 않고 블록 안에서 잘린다
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxHeight: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MarqueeText(
                      appointment.subject,
                      active: active,
                      maxLines: lines.title,
                      style: titleStyle,
                    ),
                    if (lines.time)
                      _SubLine(
                        _timeRange(appointment.startTime, appointment.endTime),
                        on: appointment.color,
                        alpha: 0.8,
                        maxLines: 1,
                      ),
                    if (notes != null && lines.notes > 0)
                      _SubLine(
                        notes,
                        on: appointment.color,
                        alpha: 0.7,
                        maxLines: lines.notes,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 일·주 보기 블록의 바탕: 일정 색 배경, 옅은 테두리와 그림자, 둥근 모서리
class _BlockFrame extends StatelessWidget {
  const _BlockFrame({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: AppRadius.smAll,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// 일·주 보기 블록에 들어가는 줄 수. 글자 배율을 반영한 실제 줄 높이로 센다
class _BlockLines {
  const _BlockLines({
    required this.title,
    required this.time,
    required this.notes,
  });

  /// 제목 줄 수(1 이상), 시간 줄을 둘지, 설명 줄 수(0이면 두지 않음)
  final int title;
  final bool time;
  final int notes;

  factory _BlockLines.fit(
    BuildContext context, {
    required double height,
    required TextStyle titleStyle,
    required int maxTitleLines,
    required bool hasNotes,
    required bool showTime,
  }) {
    final scaler = MediaQuery.textScalerOf(context);
    double lineHeight(TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: '가', style: style),
        textScaler: scaler,
        textDirection: TextDirection.ltr,
      )..layout();
      final h = painter.height;
      painter.dispose();
      return h;
    }

    final titleLine = lineHeight(titleStyle);
    // 작은 줄은 위 여백 2를 함께 센다
    final subLine = lineHeight(_SubLine.style) + 2;
    final title = (height / titleLine).floor().clamp(1, maxTitleLines);
    var left = height - title * titleLine;
    final time = showTime && left >= subLine;
    if (time) left -= subLine;
    final notes = hasNotes
        ? ((left - 2) / (subLine - 2)).floor().clamp(0, 2)
        : 0;
    return _BlockLines(title: title, time: time, notes: notes);
  }
}

/// 블록 제목 아래의 작은 글자 줄(시간·설명)
class _SubLine extends StatelessWidget {
  /// 줄 높이를 잴 때 쓰는 기본 글꼴 크기
  static const style = TextStyle(fontSize: 10);

  const _SubLine(
    this.text, {
    required this.on,
    required this.alpha,
    required this.maxLines,
  });

  final String text;
  final Color on;
  final double alpha;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _contrastOn(on).withValues(alpha: alpha),
          fontSize: 10,
        ),
      ),
    );
  }
}

/// 일정 목록 보기: 시작 시각과 제목 한 줄
class _AgendaBlock extends StatelessWidget {
  const _AgendaBlock({required this.appointment, required this.active});

  final Appointment appointment;

  /// 제목을 흘려 보일지
  final bool active;

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

/// [background] 위에서 읽히는 글자색
Color _contrastOn(Color background) =>
    background.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

String _timeRange(DateTime start, DateTime end) =>
    '${formatTime(start)} - ${formatTime(end)}';
