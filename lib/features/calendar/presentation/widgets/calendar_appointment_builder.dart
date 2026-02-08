import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// 캘린더 일정 커스텀 위젯 빌더
///
/// SfCalendar의 appointmentBuilder에서 사용되며,
/// 일정을 커스텀 디자인으로 렌더링합니다.
class ScheduleAppointmentBuilder {
  /// Month 뷰용 일정 빌더
  ///
  /// 월간 뷰에서는 공간이 제한되므로 간결하게 표시
  static Widget buildMonthAppointment(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    final Appointment appointment = details.appointments.first as Appointment;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 0.5),
      decoration: BoxDecoration(
        color: appointment.color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Text(
        appointment.subject,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _getContrastColor(appointment.color),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Day/Week 뷰용 일정 빌더
  ///
  /// 시간대별 뷰에서는 더 자세한 정보를 표시
  static Widget buildTimeSlotAppointment(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    final Appointment appointment = details.appointments.first as Appointment;
    final bool isShortEvent = details.bounds.height < 40;

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: appointment.color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: appointment.color.withValues(alpha: 0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: appointment.color.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 제목
                  Text(
                    appointment.subject,
                    maxLines: isShortEvent ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _getContrastColor(appointment.color),
                      fontSize: isShortEvent ? 11 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // 시간 (공간이 있을 때만)
                  if (!isShortEvent && details.bounds.height >= 50)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _formatTimeRange(
                          appointment.startTime,
                          appointment.endTime,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _getContrastColor(appointment.color)
                              .withValues(alpha: 0.8),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  // 설명 (공간이 더 있을 때)
                  if (!isShortEvent &&
                      details.bounds.height >= 70 &&
                      appointment.notes != null &&
                      appointment.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        appointment.notes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _getContrastColor(appointment.color)
                              .withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Agenda 뷰용 일정 빌더
  static Widget buildAgendaAppointment(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    final Appointment appointment = details.appointments.first as Appointment;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: appointment.color, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 시간 정보
            SizedBox(
              width: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTime(appointment.startTime),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    _formatTime(appointment.endTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (appointment.notes != null && appointment.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        appointment.notes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // 화살표
            Icon(
              Icons.chevron_right,
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  /// 종일 이벤트 빌더
  static Widget buildAllDayAppointment(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    final Appointment appointment = details.appointments.first as Appointment;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: appointment.color,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(
        appointment.subject,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _getContrastColor(appointment.color),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // Helper Methods
  // ============================================================

  /// 배경색 대비 글자색 결정
  static Color _getContrastColor(Color backgroundColor) {
    // 상대 휘도 계산
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  /// 시간 형식 포맷
  static String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// 시간 범위 형식
  static String _formatTimeRange(DateTime start, DateTime end) {
    return '${_formatTime(start)} - ${_formatTime(end)}';
  }
}
