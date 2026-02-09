import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:momeet/shared/api/export.dart';

/// ScheduleRead를 Syncfusion Calendar의 Appointment로 매핑하는 DataSource
///
/// Syncfusion Calendar는 CalendarDataSource를 상속받아 데이터를 제공합니다.
/// 이 클래스는 OpenAPI에서 생성된 ScheduleRead 모델을 캘린더 Appointment로 변환합니다.
class ScheduleCalendarDataSource extends CalendarDataSource {
  /// ScheduleRead 리스트로 DataSource 생성
  ScheduleCalendarDataSource(List<ScheduleRead> schedules) {
    appointments = schedules.map(_mapToAppointment).toList();
  }

  /// 빈 DataSource 생성
  ScheduleCalendarDataSource.empty() {
    appointments = <Appointment>[];
  }

  /// ScheduleRead를 Appointment로 변환
  Appointment _mapToAppointment(ScheduleRead schedule) {
    return Appointment(
      id: schedule.id,
      subject: schedule.title,
      notes: schedule.description,
      startTime: schedule.startTime.toLocal(),
      endTime: schedule.endTime.toLocal(),
      isAllDay: _isAllDayEvent(schedule),
      color: _getScheduleColor(schedule),
      recurrenceRule: schedule.recurrenceRule,
      recurrenceExceptionDates:
          null, // TODO: 반복 예외 날짜 처리 (백엔드 지원 필요)
    );
  }

  /// 종일 이벤트 여부 판단
  ///
  /// 시작 시간이 자정이고 끝 시간도 자정이면 종일 이벤트로 간주
  bool _isAllDayEvent(ScheduleRead schedule) {
    final start = schedule.startTime.toLocal();
    final end = schedule.endTime.toLocal();

    // 시작이 자정이고 끝도 자정이며 최소 하루 이상 차이나면 종일 이벤트
    final isStartMidnight = start.hour == 0 && start.minute == 0;
    final isEndMidnight = end.hour == 0 && end.minute == 0;
    final duration = end.difference(start);

    return isStartMidnight && isEndMidnight && duration.inHours >= 24;
  }

  /// 일정의 색상 결정
  ///
  /// 태그가 있으면 첫 번째 태그의 색상을 사용, 없으면 기본 색상
  Color _getScheduleColor(ScheduleRead schedule) {
    final tags = schedule.tags.toList();
    if (tags.isNotEmpty) {
      return _parseColor(tags.first.color);
    }

    // 상태에 따른 기본 색상
    switch (schedule.state.name) {
      case 'CONFIRMED':
        return Colors.blue;
      case 'CANCELLED':
        return Colors.grey;
      case 'PLANNED':
      default:
        return Colors.teal;
    }
  }

  /// Hex 색상 문자열을 Color로 변환
  ///
  /// 지원 형식: '#RRGGBB', '#AARRGGBB', 'RRGGBB'
  Color _parseColor(String colorString) {
    try {
      String hex = colorString.replaceAll('#', '');

      // 6자리면 FF (불투명) 추가
      if (hex.length == 6) {
        hex = 'FF$hex';
      }

      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.blue; // 파싱 실패시 기본 색상
    }
  }

  // ============================================================
  // CalendarDataSource Override Methods
  // ============================================================

  @override
  DateTime getStartTime(int index) {
    return (appointments![index] as Appointment).startTime;
  }

  @override
  DateTime getEndTime(int index) {
    return (appointments![index] as Appointment).endTime;
  }

  @override
  String getSubject(int index) {
    return (appointments![index] as Appointment).subject;
  }

  @override
  Color getColor(int index) {
    return (appointments![index] as Appointment).color;
  }

  @override
  bool isAllDay(int index) {
    return (appointments![index] as Appointment).isAllDay;
  }

  @override
  String? getNotes(int index) {
    return (appointments![index] as Appointment).notes;
  }

  @override
  String? getRecurrenceRule(int index) {
    return (appointments![index] as Appointment).recurrenceRule;
  }

  @override
  Object? getId(int index) {
    return (appointments![index] as Appointment).id;
  }

  // ============================================================
  // Helper Methods
  // ============================================================

  /// ID로 ScheduleRead의 원본 Appointment 찾기
  Appointment? getAppointmentById(String id) {
    try {
      return appointments?.firstWhere(
        (apt) => (apt as Appointment).id == id,
      ) as Appointment?;
    } catch (e) {
      return null;
    }
  }

  /// 특정 날짜의 모든 Appointment 가져오기
  List<Appointment> getAppointmentsForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return appointments
            ?.where((apt) {
              final appointment = apt as Appointment;
              final startDate = DateTime(
                appointment.startTime.year,
                appointment.startTime.month,
                appointment.startTime.day,
              );
              final endDate = DateTime(
                appointment.endTime.year,
                appointment.endTime.month,
                appointment.endTime.day,
              );
              return !targetDate.isBefore(startDate) &&
                  !targetDate.isAfter(endDate);
            })
            .cast<Appointment>()
            .toList() ??
        [];
  }
}
