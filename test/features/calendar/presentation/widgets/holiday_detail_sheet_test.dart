import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/calendar/presentation/widgets/holiday_detail_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/sheet_host.dart';

void main() {
  HolidayItem holiday(String locdate) => HolidayItem(
    locdate: locdate,
    seq: 1,
    dateKind: '01',
    dateName: '성탄절',
    isHoliday: true,
  );

  testWidgets('공휴일 이름과 날짜를 보이고 닫기로 닫는다', (tester) async {
    await pumpSheetHost(
      tester,
      open: (context) => showHolidayDetailSheet(context, holiday('20261225')),
    );

    expect(find.text('성탄절'), findsOneWidget);
    expect(find.text('2026년 12월 25일'), findsOneWidget);
    await tapVisible(tester, find.text('닫기'));
    expect(find.text('성탄절'), findsNothing);
  });

  testWidgets('날짜 형식이 다르면 받은 값을 그대로 보인다', (tester) async {
    await pumpSheetHost(
      tester,
      open: (context) => showHolidayDetailSheet(context, holiday('2026-12')),
    );

    expect(find.text('2026-12'), findsOneWidget);
  });
}
