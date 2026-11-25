import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_list_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_plan.dart';

final _day = DateTime(2026, 3, 2);

typedef _Item = (String title, String longTitle, int? from, int? to, int tag);

const _items = <_Item>[
  ('대체공휴일 가족 나들이', '대체공휴일 가족 나들이와 저녁 식사 예약 확인', null, null, 4),
  ('아침 달리기', '아침 달리기 5km와 스트레칭 기록 남기기', 7, 8, 2),
  ('분기 계획 회의', '분기 계획 회의와 지난 분기 회고 자료 같이 보기', 10, 12, 0),
  ('토끼와 점심', '토끼와 점심, 새로 생긴 칼국수 가게', 12, 13, 3),
  ('영어 스터디', '영어 스터디 3장 단어 시험과 말하기 연습', 14, 16, 1),
  ('가계부 정리', '이번 달 가계부 정리하고 고정 지출 줄이기', 18, 19, 5),
  ('여행 숙소 알아보기', '여름 여행 숙소 세 곳 비교해서 하나 고르기', 19, 20, 6),
  ('독서 모임 책 읽기', '독서 모임 책 읽기, 다음 주까지 4장부터 6장', 21, 22, 7),
];

ScheduleRead _schedule(int index, bool long) {
  final (title, longTitle, from, to, tag) = _items[index % _items.length];
  // 종일 일정은 그날 0시부터 다음 날 0시까지다
  final start = from == null ? _day : _day.add(Duration(hours: from));
  final end = to == null
      ? _day.add(const Duration(days: 1))
      : _day.add(Duration(hours: to));
  return planSchedule(
    id: 'schedule-$index',
    title: long ? longTitle : title,
    start: start,
    end: end,
    tags: [planTags[tag]],
  );
}

@widgetbook.UseCase(name: '하루 일정 목록 시트', type: ScheduleListSheet, path: '[달력]')
Widget scheduleListSheet(BuildContext context) {
  final knobs = context.knobs;
  final count = knobs.int.slider(
    label: '일정 수',
    description: '시트는 화면 높이의 절반까지 자라고 그 뒤로는 목록을 굴린다',
    initialValue: 4,
    min: 1,
    max: _items.length,
  );
  final long = knobs.boolean(label: '긴 제목');
  // 앱에서는 월 보기의 +N이나 일정이 여럿인 날을 누르면 화면 높이의 절반까지 올라온다
  return PlanSheetFrame(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      child: ScheduleListSheet(
        date: _day,
        schedules: [for (var i = 0; i < count; i++) _schedule(i, long)],
      ),
    ),
  );
}
