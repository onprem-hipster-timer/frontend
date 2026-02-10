import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_data_source.dart';
import 'package:momeet/features/calendar/presentation/providers/holiday_provider.dart';
import 'package:momeet/shared/api/export.dart';
export 'schedule_mutations.dart';

part 'calendar_providers.g.dart';

// ============================================================
// 캘린더 설정 Provider (UI 상태)
// ============================================================

/// 캘린더 UI 설정 상태 관리
///
/// 뷰 타입, 선택된 날짜, 표시 설정 등을 관리합니다.
@riverpod
class CalendarSettings extends _$CalendarSettings {
  @override
  CalendarSettingsState build() => CalendarSettingsState.initial();

  /// 캘린더 뷰 타입 변경
  void setViewType(CalendarViewType viewType) {
    state = state.copyWith(viewType: viewType);
  }

  /// 선택된 날짜 변경
  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  /// 표시 날짜 변경 (현재 보이는 월/주의 기준일)
  void setDisplayDate(DateTime date) {
    state = state.copyWith(displayDate: date);
  }

  /// 오늘 날짜로 이동
  void goToToday() {
    final now = DateTime.now();
    state = state.copyWith(
      selectedDate: now,
      displayDate: DateTime(now.year, now.month, 1),
    );
  }

  /// 이전 기간으로 이동
  void goToPrevious() {
    final current = state.displayDate;
    late DateTime newDate;

    switch (state.viewType) {
      case CalendarViewType.day:
        newDate = current.subtract(const Duration(days: 1));
      case CalendarViewType.week:
        newDate = current.subtract(const Duration(days: 7));
      case CalendarViewType.month:
      case CalendarViewType.year:
      case CalendarViewType.agenda:
        newDate = DateTime(current.year, current.month - 1, 1);
    }

    state = state.copyWith(displayDate: newDate, selectedDate: newDate);
  }

  /// 다음 기간으로 이동
  void goToNext() {
    final current = state.displayDate;
    late DateTime newDate;

    switch (state.viewType) {
      case CalendarViewType.day:
        newDate = current.add(const Duration(days: 1));
      case CalendarViewType.week:
        newDate = current.add(const Duration(days: 7));
      case CalendarViewType.month:
      case CalendarViewType.year:
      case CalendarViewType.agenda:
        newDate = DateTime(current.year, current.month + 1, 1);
    }

    state = state.copyWith(displayDate: newDate, selectedDate: newDate);
  }

  /// 24시간 형식 토글
  void toggle24HourFormat() {
    state = state.copyWith(use24HourFormat: !state.use24HourFormat);
  }

  /// 공휴일 표시 토글
  void toggleShowHolidays() {
    state = state.copyWith(showHolidays: !state.showHolidays);
  }
}

// ============================================================
// 캘린더 필터 Provider
// ============================================================

/// 캘린더 필터 상태 관리
///
/// 태그 필터, 사용자 필터 등을 관리합니다.
@riverpod
class CalendarFilter extends _$CalendarFilter {
  @override
  CalendarFilterState build() => const CalendarFilterState();

  /// 태그 필터 설정
  void setTagFilter(List<String> tagIds) {
    state = state.copyWith(tagIds: tagIds);
  }

  /// 태그 추가
  void addTagFilter(String tagId) {
    if (!state.tagIds.contains(tagId)) {
      state = state.copyWith(tagIds: [...state.tagIds, tagId]);
    }
  }

  /// 태그 제거
  void removeTagFilter(String tagId) {
    state = state.copyWith(
      tagIds: state.tagIds.where((id) => id != tagId).toList(),
    );
  }

  /// 태그 토글
  void toggleTagFilter(String tagId) {
    if (state.tagIds.contains(tagId)) {
      removeTagFilter(tagId);
    } else {
      addTagFilter(tagId);
    }
  }

  /// 필터 초기화
  void clearFilters() {
    state = const CalendarFilterState();
  }

  /// 취소된 일정 표시 토글
  void toggleShowCancelled() {
    state = state.copyWith(showCancelled: !state.showCancelled);
  }
}

// ============================================================
// 일정 데이터 Provider
// ============================================================

/// 현재 표시 범위의 일정 조회
///
/// CalendarSettings의 displayDate를 기반으로 적절한 범위의 일정을 조회합니다.
@riverpod
Future<List<ScheduleRead>> currentSchedules(Ref ref) async {
  final settings = ref.watch(calendarSettingsProvider);
  final displayDate = settings.displayDate;
  final api = ref.watch(schedulesApiProvider);

  // 뷰 타입에 따라 조회 범위 결정
  late DateTime startDate;
  late DateTime endDate;

  switch (settings.viewType) {
    case CalendarViewType.day:
      startDate = DateTime(displayDate.year, displayDate.month, displayDate.day);
      endDate = startDate.add(const Duration(days: 1));
    case CalendarViewType.week:
      // 주의 시작일 계산 (월요일 기준)
      final weekday = displayDate.weekday;
      final start = displayDate.subtract(Duration(days: weekday - 1));
      startDate = DateTime(start.year, start.month, start.day);
      endDate = startDate.add(const Duration(days: 7));
    case CalendarViewType.month:
    case CalendarViewType.agenda:
      // 월 시작 전 주부터 월 끝 후 주까지 (캘린더 표시 영역)
      final firstOfMonth = DateTime(displayDate.year, displayDate.month, 1);
      final firstWeekday = firstOfMonth.weekday;
      startDate = firstOfMonth.subtract(Duration(days: firstWeekday - 1));

      final lastOfMonth = DateTime(displayDate.year, displayDate.month + 1, 0);
      final lastWeekday = lastOfMonth.weekday;
      endDate = lastOfMonth.add(Duration(days: 7 - lastWeekday + 1));
    case CalendarViewType.year:
      startDate = DateTime(displayDate.year, 1, 1);
      endDate = DateTime(displayDate.year + 1, 1, 1);
  }

  final response = await api.readSchedulesV1SchedulesGet(
    startDate: startDate.toUtc(),
    endDate: endDate.toUtc(),
  );

  return response;
}

/// 필터링된 일정 목록
///
/// 현재 일정에 필터를 적용한 결과를 반환합니다.
@riverpod
Future<List<ScheduleRead>> filteredSchedules(Ref ref) async {
  final schedules = await ref.watch(currentSchedulesProvider.future);
  final filter = ref.watch(calendarFilterProvider);

  return schedules.where((schedule) {
    // 태그 필터
    if (filter.tagIds.isNotEmpty) {
      final scheduleTags = schedule.tags.toList();
      final hasMatchingTag = scheduleTags.any(
        (tag) => filter.tagIds.contains(tag.id),
      );
      if (!hasMatchingTag) return false;
    }

    // 취소된 일정 필터
    if (!filter.showCancelled && schedule.state.name == 'CANCELLED') {
      return false;
    }

    return true;
  }).toList();
}

/// 현재 표시 중인 캘린더 범위의 휴일 조회
///
/// CalendarSettings의 displayDate를 기반으로 필요한 연도의 휴일을 조회합니다.
/// 월간/주간 뷰에서 여러 연도에 걸칠 수 있는 경우를 고려합니다.
@riverpod
Future<List<HolidayItem>> currentHolidays(Ref ref) async {
  final settings = ref.watch(calendarSettingsProvider);
  final displayDate = settings.displayDate;

  // 뷰 타입에 따라 필요한 연도 범위 결정
  late DateTime startDate;
  late DateTime endDate;

  switch (settings.viewType) {
    case CalendarViewType.day:
      startDate = DateTime(displayDate.year, displayDate.month, displayDate.day);
      endDate = startDate.add(const Duration(days: 1));
    case CalendarViewType.week:
      final weekday = displayDate.weekday;
      final start = displayDate.subtract(Duration(days: weekday - 1));
      startDate = DateTime(start.year, start.month, start.day);
      endDate = startDate.add(const Duration(days: 7));
    case CalendarViewType.month:
    case CalendarViewType.agenda:
      final firstOfMonth = DateTime(displayDate.year, displayDate.month, 1);
      final firstWeekday = firstOfMonth.weekday;
      startDate = firstOfMonth.subtract(Duration(days: firstWeekday - 1));

      final lastOfMonth = DateTime(displayDate.year, displayDate.month + 1, 0);
      final lastWeekday = lastOfMonth.weekday;
      endDate = lastOfMonth.add(Duration(days: 7 - lastWeekday + 1));
    case CalendarViewType.year:
      startDate = DateTime(displayDate.year, 1, 1);
      endDate = DateTime(displayDate.year + 1, 1, 1);
  }

  // 필요한 연도들 추출
  final years = <int>{};
  var currentYear = startDate.year;
  while (currentYear <= endDate.year) {
    years.add(currentYear);
    currentYear++;
  }

  // 모든 연도의 휴일 병합
  final allHolidays = <HolidayItem>[];
  for (final year in years) {
    final yearHolidays = await ref.watch(holidaysProvider(year).future);
    allHolidays.addAll(yearHolidays);
  }

  // 표시 범위 내의 휴일만 필터링
  return allHolidays.where((holiday) {
    final holidayDate = parseHolidayDate(holiday.locdate);
    return holidayDate != null &&
           holidayDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
           holidayDate.isBefore(endDate);
  }).toList();
}

/// 캘린더 데이터 소스 Provider
///
/// 필터링된 일정을 Syncfusion CalendarDataSource로 변환합니다.
@riverpod
Future<ScheduleCalendarDataSource> calendarDataSource(Ref ref) async {
  final schedules = await ref.watch(filteredSchedulesProvider.future);
  return ScheduleCalendarDataSource(schedules);
}

// ============================================================
// 일정 전용 Appointments Provider (휴일 제외)
// ============================================================

/// 사용자 일정만을 포함한 Appointments 목록
///
/// 휴일은 제외하고 오직 사용자의 일정(ScheduleRead)만 Appointment로 변환합니다.
/// 휴일은 별도로 Cell Builder와 Special Regions에서 처리됩니다.
@riverpod
Future<List<Appointment>> calendarAppointments(Ref ref) async {
  try {
    // 사용자 일정만 가져오기 (필터링 적용)
    final schedules = await ref.watch(filteredSchedulesProvider.future);

    // 일정을 Appointment로 변환 (휴일 제외)
    return schedules.map(_scheduleToAppointment).toList();
  } catch (error) {
    debugPrint('캘린더 일정 로드 실패: $error');
    return []; // 에러 발생 시 빈 리스트 반환
  }
}

/// 일정 전용 캘린더 데이터 소스 Provider
///
/// 휴일을 제외한 사용자 일정만으로 DataSource를 생성합니다.
/// 휴일은 UI에서 별도로 표시됩니다.
@riverpod
Future<ScheduleOnlyDataSource> scheduleOnlyDataSource(Ref ref) async {
  final appointments = await ref.watch(calendarAppointmentsProvider.future);
  return ScheduleOnlyDataSource(appointments);
}

/// ScheduleRead를 Appointment로 변환하는 헬퍼 함수
Appointment _scheduleToAppointment(ScheduleRead schedule) {
  return Appointment(
    id: schedule.id,
    subject: schedule.title,
    notes: schedule.description,
    startTime: schedule.startTime.toLocal(),
    endTime: schedule.endTime.toLocal(),
    isAllDay: _isAllDayEvent(schedule),
    color: _getScheduleColor(schedule),
    recurrenceRule: schedule.recurrenceRule,
  );
}

/// HolidayItem을 Appointment로 변환하는 헬퍼 함수
Appointment _holidayToAppointment(HolidayItem holiday) {
  final date = parseHolidayDate(holiday.locdate);
  if (date == null) {
    // 파싱 실패 시 현재 날짜 사용 (오류 방지)
    final now = DateTime.now();
    return Appointment(
      id: 'holiday_${holiday.seq}',
      subject: holiday.dateName,
      startTime: now,
      endTime: now.add(const Duration(hours: 1)),
      color: Colors.red.withValues(alpha: 0.8),
      isAllDay: true,
    );
  }

  return Appointment(
    id: 'holiday_${holiday.locdate}_${holiday.seq}',
    subject: holiday.dateName,
    startTime: date,
    endTime: date.add(const Duration(days: 1)),
    color: Colors.red.withValues(alpha: 0.8),
    isAllDay: true,
    notes: '휴일',
  );
}

/// 종일 이벤트 여부 판단 헬퍼 함수
bool _isAllDayEvent(ScheduleRead schedule) {
  final start = schedule.startTime.toLocal();
  final end = schedule.endTime.toLocal();

  // 시작이 자정이고 끝도 자정이며 최소 하루 이상 차이나면 종일 이벤트
  final isStartMidnight = start.hour == 0 && start.minute == 0;
  final isEndMidnight = end.hour == 0 && end.minute == 0;
  final duration = end.difference(start);

  return isStartMidnight && isEndMidnight && duration.inHours >= 24;
}

/// 일정의 색상 결정 헬퍼 함수
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

/// Hex 색상 문자열을 Color로 변환 헬퍼 함수
Color _parseColor(String colorString) {
  try {
    String hex = colorString.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  } catch (e) {
    return Colors.blue;
  }
}


/// 혼합 데이터(일정 + 휴일)를 위한 CalendarDataSource
class MixedCalendarDataSource extends CalendarDataSource {
  MixedCalendarDataSource(List<Appointment> appointments) {
    this.appointments = appointments;
  }
}

