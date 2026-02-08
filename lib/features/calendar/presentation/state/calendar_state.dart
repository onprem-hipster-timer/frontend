import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as sf;

part 'calendar_state.freezed.dart';

/// 캘린더 뷰 타입
enum CalendarViewType {
  day,
  week,
  month,
  year,
  agenda,
}

/// CalendarViewType을 SfCalendar의 CalendarView로 변환
extension CalendarViewTypeExtension on CalendarViewType {
  sf.CalendarView toSfCalendarView() {
    switch (this) {
      case CalendarViewType.day:
        return sf.CalendarView.day;
      case CalendarViewType.week:
        return sf.CalendarView.week;
      case CalendarViewType.month:
        return sf.CalendarView.month;
      case CalendarViewType.year:
        return sf.CalendarView.schedule;
      case CalendarViewType.agenda:
        return sf.CalendarView.schedule;
    }
  }
}

/// 캘린더 UI 설정 상태 (로컬)
@freezed
abstract class CalendarSettingsState with _$CalendarSettingsState {
  const factory CalendarSettingsState({
    /// 현재 캘린더 뷰 타입
    @Default(CalendarViewType.month) CalendarViewType viewType,

    /// 선택된 날짜
    required DateTime selectedDate,

    /// 현재 표시 중인 날짜 범위의 시작
    required DateTime displayDate,

    /// 24시간 형식 사용 여부
    @Default(true) bool use24HourFormat,

    /// 주의 시작 요일 (1 = 월요일, 7 = 일요일)
    @Default(1) int firstDayOfWeek,

    /// 배지 표시 스타일 ('colored', 'dot', 'count')
    @Default('colored') String badgeVariant,

    /// 공휴일 표시 여부
    @Default(true) bool showHolidays,

    /// 주말 색상 강조 여부
    @Default(true) bool highlightWeekends,
  }) = _CalendarSettingsState;

  /// 기본 초기 상태 팩토리
  factory CalendarSettingsState.initial() {
    final now = DateTime.now();
    return CalendarSettingsState(
      selectedDate: now,
      displayDate: DateTime(now.year, now.month, 1),
    );
  }
}

/// 캘린더 필터 상태 (로컬)
@freezed
abstract class CalendarFilterState with _$CalendarFilterState {
  const factory CalendarFilterState({
    /// 선택된 태그 ID 목록 (필터링에 사용)
    @Default([]) List<String> tagIds,

    /// 선택된 사용자 ID ('all' = 전체)
    @Default('all') String selectedUserId,

    /// 취소된 일정 표시 여부
    @Default(false) bool showCancelled,

    /// 완료된 일정 표시 여부
    @Default(true) bool showCompleted,
  }) = _CalendarFilterState;
}

/// 캘린더 데이터 로딩 상태
@freezed
abstract class CalendarDataState with _$CalendarDataState {
  const factory CalendarDataState({
    /// 로딩 중 여부
    @Default(false) bool isLoading,

    /// 에러 메시지 (있는 경우)
    String? errorMessage,

    /// 마지막 데이터 로드 시간
    DateTime? lastLoadedAt,
  }) = _CalendarDataState;
}
