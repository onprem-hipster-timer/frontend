import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_data_source.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_month_cell_view.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view_view.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  /// 2026년 3월 18일(수)을 보는 월 보기
  Future<void> pumpMonth(WidgetTester tester, {int? weeks}) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final day = DateTime(2026, 3, 18);
    final settings = CalendarSettingsState(
      selectedDate: day,
      displayDate: day,
      firstDayOfWeek: DateTime.sunday,
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ko', 'KR')],
        home: Scaffold(
          body: weeks == null
              ? CalendarViewWidgetView(
                  settings: settings,
                  schedules: AsyncData(ScheduleCalendarDataSource(const [])),
                  holidays: const [],
                  onRetry: () {},
                  onDisplayDateChanged: (_) {},
                  onMoreTap: (_) {},
                  onDateTap: (_) {},
                  onDragEnd: (_) {},
                  onResizeEnd: (_) {},
                )
              : CalendarViewWidgetView(
                  settings: settings,
                  schedules: AsyncData(ScheduleCalendarDataSource(const [])),
                  holidays: const [],
                  onRetry: () {},
                  onDisplayDateChanged: (_) {},
                  onMoreTap: (_) {},
                  onDateTap: (_) {},
                  onDragEnd: (_) {},
                  onResizeEnd: (_) {},
                  monthWeeks: weeks,
                ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 화면 안에 그린 날짜 칸의 날짜. 달력은 넘기기 위해 앞뒤 기간도 화면 밖에 그려 둔다
  List<DateTime> shownDays(WidgetTester tester) {
    final screen = Offset.zero & tester.view.physicalSize;
    return [
      for (final element in find.byType(CalendarMonthCellView).evaluate())
        if (screen.contains(tester.getCenter(find.byWidget(element.widget))))
          (element.widget as CalendarMonthCellView).date,
    ]..sort();
  }

  testWidgets('주 수를 정하지 않으면 월 보기는 보는 날의 달을 여섯 주로 그린다', (tester) async {
    await pumpMonth(tester);

    final days = shownDays(tester);
    expect(days, hasLength(42));
    expect(days.first, DateTime(2026, 3, 1));
    expect(days.last, DateTime(2026, 4, 11));
  });

  testWidgets('월 보기를 두 주로 정하면 보는 날이 든 주부터 두 주만 그린다', (tester) async {
    await pumpMonth(tester, weeks: 2);

    final days = shownDays(tester);
    expect(days, hasLength(14));
    expect(days.first, DateTime(2026, 3, 15));
    expect(days.last, DateTime(2026, 3, 28));
  });
}
