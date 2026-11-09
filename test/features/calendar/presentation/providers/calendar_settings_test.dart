import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/providers/shared_preferences_provider.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/providers/holiday_provider.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> container([
    Map<String, Object> saved = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(saved);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        holidaysProvider.overrideWith(
          (ref, year) async => [
            HolidayItem(
              locdate:
                  '${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}15',
              seq: 1,
              dateKind: '01',
              dateName: '쉬는 날',
              isHoliday: true,
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('저장한 값이 없으면 공휴일·주말 강조·24시간제를 켜고 일요일부터, 일정 수는 자동', () async {
    final settings = (await container()).read(calendarSettingsProvider);

    expect(settings.showHolidays, isTrue);
    expect(settings.highlightWeekends, isTrue);
    expect(settings.use24HourFormat, isTrue);
    expect(settings.firstDayOfWeek, DateTime.sunday);
    expect(settings.monthEventsPerDay, isNull);
  });

  test('바꾼 값은 기기에 저장해 다음에 그대로 연다', () async {
    final first = await container();
    first.read(calendarSettingsProvider.notifier)
      ..setShowHolidays(false)
      ..setHighlightWeekends(false)
      ..setUse24HourFormat(false)
      ..setFirstDayOfWeek(DateTime.monday)
      ..setMonthEventsPerDay(2);
    final prefs = await SharedPreferences.getInstance();

    final next = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(next.dispose);
    final settings = next.read(calendarSettingsProvider);
    expect(settings.showHolidays, isFalse);
    expect(settings.highlightWeekends, isFalse);
    expect(settings.use24HourFormat, isFalse);
    expect(settings.firstDayOfWeek, DateTime.monday);
    expect(settings.monthEventsPerDay, 2);
  });

  test('일정 수를 자동으로 되돌리면 저장한 값을 지운다', () async {
    final c = await container({'calendar.monthEventsPerDay': 4});
    expect(c.read(calendarSettingsProvider).monthEventsPerDay, 4);

    c.read(calendarSettingsProvider.notifier).setMonthEventsPerDay(null);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('calendar.monthEventsPerDay'), isFalse);
    expect(c.read(calendarSettingsProvider).monthEventsPerDay, isNull);
  });

  test('주 시작 요일을 바꾸면 주 보기 기간도 그 요일부터 다시 잡는다', () async {
    final c = await container();
    final notifier = c.read(calendarSettingsProvider.notifier)
      ..setSelectedDate(DateTime(2026, 11, 12))
      ..setViewType(CalendarViewType.week);
    expect(c.read(calendarSettingsProvider).displayDate, DateTime(2026, 11, 8));

    notifier.setFirstDayOfWeek(DateTime.monday);
    expect(c.read(calendarSettingsProvider).displayDate, DateTime(2026, 11, 9));
  });

  test('공휴일을 끄면 공휴일을 보이지 않는다', () async {
    final c = await container();
    expect(await c.read(currentHolidaysProvider.future), hasLength(1));

    c.read(calendarSettingsProvider.notifier).setShowHolidays(false);
    expect(await c.read(currentHolidaysProvider.future), isEmpty);
  });
}
