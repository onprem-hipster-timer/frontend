import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/utils/time_formatters.dart';
import 'package:momeet/features/calendar/presentation/widgets/marquee_text.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_block_paint.dart';
import 'package:momeet/features/calendar/presentation/widgets/shared_schedule_mark.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// 일·주 보기: 블록 [height]에 따라 시간과 설명을 더 보인다
class ScheduleTimeSlotBlock extends StatelessWidget {
  const ScheduleTimeSlotBlock({
    super.key,
    required this.appointment,
    required this.height,
    required this.active,
    required this.shared,
  });

  final Appointment appointment;
  final double height;

  /// 제목을 흘려 보일지
  final bool active;
  final bool shared;

  @override
  Widget build(BuildContext context) {
    final isShortEvent = height < 40;
    final notes = (appointment.notes?.isEmpty ?? true)
        ? null
        : appointment.notes;
    final textColor = scheduleBlockTextColor(
      context,
      appointment.color,
      shared,
    );
    final titleStyle = TextStyle(
      color: textColor,
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
      shared: shared,
      child: Padding(
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
              _Title(
                appointment.subject,
                active: active,
                shared: shared,
                maxLines: lines.title,
                style: titleStyle,
              ),
              if (lines.time)
                _SubLine(
                  _timeRange(appointment.startTime, appointment.endTime),
                  color: textColor,
                  alpha: 0.8,
                  maxLines: 1,
                ),
              if (notes != null && lines.notes > 0)
                _SubLine(
                  notes,
                  color: textColor,
                  alpha: 0.7,
                  maxLines: lines.notes,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 일·주 보기 블록의 제목. 공유받은 일정이면 앞에 [SharedScheduleMark]를 둔다
class _Title extends StatelessWidget {
  const _Title(
    this.text, {
    required this.active,
    required this.shared,
    required this.maxLines,
    required this.style,
  });

  final String text;
  final bool active;
  final bool shared;
  final int maxLines;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shared)
          SharedScheduleMark(color: style.color!, size: style.fontSize!),
        Expanded(
          child: MarqueeText(
            text,
            active: active,
            maxLines: maxLines,
            style: style,
          ),
        ),
      ],
    );
  }
}

/// 일·주 보기 블록의 바탕: 일정 색 배경과 왼쪽 색 막대, 옅은 테두리와 그림자, 둥근 모서리
class _BlockFrame extends StatelessWidget {
  const _BlockFrame({
    required this.color,
    required this.shared,
    required this.child,
  });

  final Color color;
  final bool shared;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final decoration = scheduleBlockDecoration(
      context,
      color,
      alpha: 0.85,
      shared: shared,
      radius: AppRadius.smAll,
    );
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: decoration.copyWith(
        border:
            decoration.border ??
            Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
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
              child: ColoredBox(color: color),
            ),
            child,
          ],
        ),
      ),
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
    required this.color,
    required this.alpha,
    required this.maxLines,
  });

  final String text;

  /// 글자색. [alpha]만큼 옅게 쓴다
  final Color color;
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
        style: TextStyle(color: color.withValues(alpha: alpha), fontSize: 10),
      ),
    );
  }
}

String _timeRange(DateTime start, DateTime end) =>
    '${formatTime(start)} - ${formatTime(end)}';
