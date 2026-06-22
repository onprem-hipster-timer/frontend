import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_data_source.dart';
import 'package:momeet/features/calendar/presentation/providers/holiday_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';
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
  final (startDate, endDate) = _visibleDateRange(settings, displayDate);

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
    if (!filter.showCancelled && schedule.state == ScheduleState.cancelled) {
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
  final (startDate, endDate) = _visibleDateRange(settings, displayDate);

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

/// 일정 전용 캘린더 데이터 소스 Provider
///
/// 휴일을 제외한 사용자 일정만으로 DataSource를 생성합니다.
/// 휴일은 UI에서 별도로 표시됩니다.
@riverpod
Future<ScheduleCalendarDataSource> scheduleOnlyDataSource(Ref ref) async {
  final schedules = await ref.watch(filteredSchedulesProvider.future);
  return ScheduleCalendarDataSource(schedules);
}

(DateTime, DateTime) _visibleDateRange(
  CalendarSettingsState settings,
  DateTime displayDate,
) {
  switch (settings.viewType) {
    case CalendarViewType.day:
      final startDate = DateTime(
        displayDate.year,
        displayDate.month,
        displayDate.day,
      );
      return (startDate, startDate.add(const Duration(days: 1)));
    case CalendarViewType.week:
      final startDate = _startOfWeek(displayDate, settings.firstDayOfWeek);
      return (startDate, startDate.add(const Duration(days: 7)));
    case CalendarViewType.month:
    case CalendarViewType.agenda:
      final firstOfMonth = DateTime(displayDate.year, displayDate.month, 1);
      final lastOfMonth = DateTime(displayDate.year, displayDate.month + 1, 0);
      final startDate = _startOfWeek(firstOfMonth, settings.firstDayOfWeek);
      final lastWeekStart = _startOfWeek(lastOfMonth, settings.firstDayOfWeek);
      final endDate = lastWeekStart.add(const Duration(days: 7));
      return (startDate, endDate);
    case CalendarViewType.year:
      return (
        DateTime(displayDate.year, 1, 1),
        DateTime(displayDate.year + 1, 1, 1),
      );
  }
}

DateTime _startOfWeek(DateTime date, int firstDayOfWeek) {
  final delta = (date.weekday - firstDayOfWeek) % DateTime.daysPerWeek;
  final start = date.subtract(Duration(days: delta));
  return DateTime(start.year, start.month, start.day);
}
