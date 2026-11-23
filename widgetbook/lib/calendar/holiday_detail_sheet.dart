import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/holiday_detail_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_plan.dart';

@widgetbook.UseCase(name: '공휴일 안내 시트', type: HolidayDetailSheet, path: '[달력]')
Widget holidayDetailSheet(BuildContext context) {
  final knobs = context.knobs;
  final name = knobs.string(label: '공휴일 이름', initialValue: '삼일절');
  final date = knobs.string(
    label: '날짜',
    description: '서버가 주는 yyyyMMdd 형식. 형식이 다르면 받은 글자를 그대로 보인다',
    initialValue: '20260301',
  );
  // 앱에서는 달력의 공휴일 칸을 누르면 아래에서 올라온다
  return PlanSheetFrame(
    child: HolidayDetailSheet(
      holiday: HolidayItem(
        locdate: date,
        seq: 1,
        dateKind: '01',
        dateName: name,
        isHoliday: true,
      ),
    ),
  );
}
