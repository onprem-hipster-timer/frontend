import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_data_source.dart';
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

/// 캘린더 데이터 소스 Provider
///
/// 필터링된 일정을 Syncfusion CalendarDataSource로 변환합니다.
@riverpod
Future<ScheduleCalendarDataSource> calendarDataSource(Ref ref) async {
  final schedules = await ref.watch(filteredSchedulesProvider.future);
  return ScheduleCalendarDataSource(schedules);
}

