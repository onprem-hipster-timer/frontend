import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_month_cell_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _holidayNames = {'삼일절': '삼일절', '긴 이름': '부처님 오신 날 대체공휴일', '없음': null};

@widgetbook.UseCase(
  name: '월 보기 날짜 칸',
  type: CalendarMonthCellView,
  path: '[달력]',
)
Widget calendarMonthCellView(BuildContext context) {
  final knobs = context.knobs;
  final holiday = knobs.object.dropdown(
    label: '3월 1일 공휴일',
    options: _holidayNames.keys.toList(),
    description: '공휴일은 빨간 숫자 옆에 이름을 두고, 칸에 다 들어가지 않으면 두 번 흘려 보인 뒤 줄인다',
  );
  final today = knobs.boolean(
    label: '오늘 포함',
    initialValue: true,
    description: '오늘은 칸을 옅게 칠하고 숫자를 동그라미 안에 둔다(3월 4일)',
  );
  final highlightWeekends = knobs.boolean(
    label: '주말 강조',
    initialValue: true,
    description: '달력 보기 설정 서랍에서 끈다. 꺼도 공휴일은 빨갛다',
  );
  // 앱에서는 월 보기의 한 주 줄. 칸 폭은 화면 폭의 7분의 1, 높이는 요일 줄을 뺀 높이의 6분의 1이다.
  // 윗줄은 지난달 날짜라 숫자가 흐리다
  return LayoutBuilder(
    builder: (context, constraints) {
      final height = (constraints.maxHeight - 30) / 6;
      Widget week(DateTime sunday, bool currentMonth) => SizedBox(
        height: height,
        child: Row(
          children: [
            for (var i = 0; i < DateTime.daysPerWeek; i++)
              Expanded(
                child: CalendarMonthCellView(
                  date: sunday.add(Duration(days: i)),
                  isToday: today && currentMonth && i == 3,
                  isCurrentMonth: currentMonth,
                  highlightWeekends: highlightWeekends,
                  holidayName: currentMonth && i == 0
                      ? _holidayNames[holiday]
                      : null,
                ),
              ),
          ],
        ),
      );
      return Column(
        children: [
          week(DateTime(2026, 2, 22), false),
          week(DateTime(2026, 3, 1), true),
        ],
      );
    },
  );
}
