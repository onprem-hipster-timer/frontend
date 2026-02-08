/// Calendar Feature
///
/// 캘린더 기능 관련 모듈을 제공합니다.
///
/// 주요 구성요소:
/// - `CalendarPage`: 캘린더 메인 페이지
/// - `CalendarViewWidget`: SfCalendar 래퍼 위젯
/// - `CalendarSettingsState`: UI 설정 상태 (Freezed)
/// - `CalendarFilterState`: 필터 상태 (Freezed)
/// - `ScheduleCalendarDataSource`: Syncfusion DataSource
library;

// Pages
export 'presentation/pages/calendar_page.dart';

// Widgets
export 'presentation/widgets/calendar_view.dart';
export 'presentation/widgets/calendar_data_source.dart';
export 'presentation/widgets/calendar_appointment_builder.dart';

// Providers
export 'presentation/providers/calendar_providers.dart';

// State
export 'presentation/state/calendar_state.dart';
