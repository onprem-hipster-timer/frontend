import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/features/calendar/presentation/utils/schedule_formatters.dart'
    as fmt;
import 'package:momeet/shared/api/rest/export.dart';

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
      isAllDay: fmt.isAllDay(
        schedule.startTime.toLocal(),
        schedule.endTime.toLocal(),
      ),
      color: _getScheduleColor(schedule),
      recurrenceRule: schedule.recurrenceRule,
      recurrenceExceptionDates: null, // TODO: 반복 예외 날짜 처리 (백엔드 지원 필요)
    );
  }

  /// 일정의 색상 결정
  ///
  /// 태그가 있으면 첫 번째 태그의 색상을 사용, 없으면 기본 색상
  Color _getScheduleColor(ScheduleRead schedule) {
    final tags = schedule.tags.toList();
    if (tags.isNotEmpty) {
      return HexColor.fromHex(tags.first.color);
    }

    // 상태에 따른 기본 색상
    return switch (schedule.state) {
      ScheduleState.confirmed => Colors.blue,
      ScheduleState.cancelled => Colors.grey,
      ScheduleState.planned || ScheduleState.$unknown => Colors.teal,
    };
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
      return appointments?.firstWhere((apt) => (apt as Appointment).id == id)
          as Appointment?;
    } catch (e) {
      return null;
    }
  }

  /// 특정 날짜의 모든 Appointment 가져오기
  ///
  /// 멀티-데이 일정도 포함되도록 [fmt.isIncludeDay]로 날짜 걸침을 판별합니다.
  List<Appointment> getAppointmentsForDate(DateTime date) {
    return appointments
            ?.where((apt) {
              final appointment = apt as Appointment;
              return fmt.isIncludeDay(
                appointment.startTime,
                appointment.endTime,
                date,
              );
            })
            .cast<Appointment>()
            .toList() ??
        [];
  }
}
