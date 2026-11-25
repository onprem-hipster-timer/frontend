import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncError, AsyncLoading, AsyncValue;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_data_source.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_plan.dart';

enum _Load { done, loading, failed }

/// 견본 달력이 여는 날. 보는 기간을 넘기면 다른 달·주도 볼 수 있다
final _day = DateTime(2026, 3, 4);

const _holidays = [
  HolidayItem(
    locdate: '20260301',
    seq: 1,
    dateKind: '01',
    dateName: '삼일절',
    isHoliday: true,
  ),
  HolidayItem(
    locdate: '20260302',
    seq: 2,
    dateKind: '01',
    dateName: '대체공휴일',
    isHoliday: true,
  ),
];

/// (제목, 긴 제목, 날, 시작 시, 끝 시, 태그). 시각이 없으면 종일이다
typedef _Item = (String, String, int, int?, int?, int);

const _items = <_Item>[
  ('가족 나들이', '대체공휴일 가족 나들이와 저녁 식사 예약 확인', 2, null, null, 4),
  ('아침 달리기', '아침 달리기 5km와 스트레칭 기록 남기기', 3, 7, 8, 2),
  ('분기 계획 회의', '분기 계획 회의와 지난 분기 회고 자료 같이 보기', 4, 10, 12, 0),
  ('토끼와 점심', '토끼와 점심, 새로 생긴 칼국수 가게', 4, 12, 13, 3),
  ('영어 스터디', '영어 스터디 3장 단어 시험과 말하기 연습', 4, 14, 16, 1),
  ('가계부 정리', '이번 달 가계부 정리하고 고정 지출 줄이기', 4, 18, 19, 5),
  ('독서 모임', '독서 모임 책 읽기, 다음 주까지 4장부터 6장', 5, 19, 21, 7),
  ('제주 여행', '제주 여행 3박 4일, 숙소와 렌터카 예약 확인', 12, null, null, 6),
  ('치과 검진', '치과 정기 검진과 스케일링 예약', 17, 9, 10, 2),
  ('동아리 정기 모임', '3월 동아리 정기 모임과 새 회원 환영회', 24, 18, 20, 3),
];

ScheduleRead _schedule(int index, bool long) {
  final (title, longTitle, day, from, to, tag) = _items[index];
  final date = DateTime(2026, 3, day);
  // 종일 일정은 그날 0시부터 다음 날 0시까지, 여행은 나흘에 걸친다
  final start = from == null ? date : date.add(Duration(hours: from));
  final end = from == null
      ? date.add(Duration(days: tag == 6 ? 4 : 1))
      : date.add(Duration(hours: to!));
  return planSchedule(
    id: 'schedule-$index',
    title: long ? longTitle : title,
    start: start,
    end: end,
    tags: [planTags[tag]],
  );
}

@widgetbook.UseCase(name: '달력', type: CalendarViewWidgetView, path: '[달력]')
Widget calendarViewWidgetView(BuildContext context) {
  final knobs = context.knobs;
  final view = knobs.object
      .dropdown(
        label: '보기',
        options: const [
          (CalendarViewType.month, '월간'),
          (CalendarViewType.week, '주간'),
          (CalendarViewType.day, '일간'),
          (CalendarViewType.agenda, '목록'),
        ],
        labelBuilder: (option) => option.$2,
      )
      .$1;
  final load = knobs.object.dropdown(
    label: '상태',
    options: _Load.values,
    labelBuilder: (load) => switch (load) {
      _Load.done => '불러옴',
      _Load.loading => '불러오는 중',
      _Load.failed => '불러올 수 없음',
    },
    description: '불러오는 동안에는 빈 달력 위에 로딩 표시를 겹친다',
  );
  final count = knobs.int.slider(
    label: '일정 수',
    description: '3월 4일에 일정이 몰려 있어 월 보기 칸에 다 들어가지 않으면 +N으로 줄인다',
    initialValue: _items.length,
    max: _items.length,
  );
  final long = knobs.boolean(label: '긴 제목');
  final holidays = knobs.boolean(
    label: '공휴일 표시',
    initialValue: true,
    description: '3월 1일 삼일절과 2일 대체공휴일. 달력 보기 설정 서랍에서 끈다',
  );
  final use24Hour = knobs.boolean(
    label: '24시간제',
    initialValue: true,
    description: '주간·일간 보기의 시각 눈금',
  );
  final AsyncValue<ScheduleCalendarDataSource> schedules = switch (load) {
    _Load.done => AsyncData(
      ScheduleCalendarDataSource([
        for (var i = 0; i < count; i++) _schedule(i, long),
      ]),
    ),
    _Load.loading => const AsyncLoading(),
    _Load.failed => AsyncError(Exception('불러오기 실패'), StackTrace.empty),
  };
  // 앱에서는 달력 화면의 도구 줄 아래를 모두 채운다. 보는 기간은 옆으로 넘겨 바꾼다.
  // 일정을 누르면 일정 상세 화면 안내가 뜬다
  return _Calendar(
    view: view,
    schedules: schedules,
    holidays: holidays ? _holidays : const [],
    use24Hour: use24Hour,
  );
}

/// 넘긴 기간이 이어지도록 보는 날을 들고 있는다
class _Calendar extends StatefulWidget {
  const _Calendar({
    required this.view,
    required this.schedules,
    required this.holidays,
    required this.use24Hour,
  });

  final CalendarViewType view;
  final AsyncValue<ScheduleCalendarDataSource> schedules;
  final List<HolidayItem> holidays;
  final bool use24Hour;

  @override
  State<_Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<_Calendar> {
  var _displayDate = _day;
  var _selectedDate = _day;

  @override
  Widget build(BuildContext context) {
    return CalendarViewWidgetView(
      settings: CalendarSettingsState(
        viewType: widget.view,
        selectedDate: _selectedDate,
        displayDate: _displayDate,
        firstDayOfWeek: DateTime.sunday,
        use24HourFormat: widget.use24Hour,
      ),
      schedules: widget.schedules,
      holidays: widget.holidays,
      onRetry: () {},
      onDisplayDateChanged: (date) => setState(() => _displayDate = date),
      onMoreTap: (_) {},
      onDateTap: (date) => setState(() => _selectedDate = date),
      onDragEnd: (_) {},
      onResizeEnd: (_) {},
    );
  }
}
