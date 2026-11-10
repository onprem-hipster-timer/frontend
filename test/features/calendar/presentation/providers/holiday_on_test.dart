import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/calendar/presentation/providers/holiday_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';

HolidayItem _item(String locdate, String name, {bool isHoliday = true}) =>
    HolidayItem(
      locdate: locdate,
      seq: 1,
      dateKind: '01',
      dateName: name,
      isHoliday: isHoliday,
    );

void main() {
  final holidays = [
    _item('20261225', '성탄절'),
    _item('20261224', '쉬지 않는 기념일', isHoliday: false),
    _item('2026122', '깨진 날짜'),
  ];

  test('그날 쉬는 날을 찾고, 시각은 보지 않는다', () {
    expect(holidayOn(holidays, DateTime(2026, 12, 25, 18))?.dateName, '성탄절');
  });

  test('쉬지 않는 날과 날짜를 읽지 못하는 항목은 건너뛴다', () {
    expect(holidayOn(holidays, DateTime(2026, 12, 24)), isNull);
    expect(holidayOn(holidays, DateTime(2026, 12, 2)), isNull);
  });
}
