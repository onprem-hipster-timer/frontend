import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:momeet/core/providers/shared_preferences_provider.dart';
import 'package:momeet/features/calendar/presentation/pages/calendar_page.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/sheet_host.dart';

/// 달력 화면의 제목·기간 이동·보기 전환·날짜 고르기·새 일정·필터
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  late ProviderContainer container;

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(1000, 1400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        schedulesApiProvider.overrideWithValue(FakeSchedulesClient()),
        calendarSettingsProvider.overrideWith(_FixedSettings.new),
        currentHolidaysProvider.overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('ko', 'KR'),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('ko', 'KR'), Locale('en', 'US')],
          home: CalendarPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  CalendarSettingsState settings() => container.read(calendarSettingsProvider);

  testWidgets('보는 달을 보이고, 이전·다음은 달만 옮기고 고른 날은 둔다', (tester) async {
    await pumpPage(tester);

    expect(find.text('달력'), findsOneWidget);
    expect(find.text('2026년 11월'), findsOneWidget);

    await tapVisible(tester, find.byTooltip('이전'));
    expect(find.text('2026년 10월'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('다음'));
    await tapVisible(tester, find.byTooltip('다음'));
    expect(find.text('2026년 12월'), findsOneWidget);
    expect(settings().selectedDate, DateTime(2026, 11, 9));
  });

  testWidgets('달력을 넘기면 화살표 사이의 달도 바뀐다', (tester) async {
    await pumpPage(tester);
    await tester.fling(
      find.byType(CalendarViewWidget),
      const Offset(-600, 0),
      2000,
    );
    await tester.pumpAndSettle();

    expect(find.text('2026년 12월'), findsOneWidget);
    expect(settings().displayDate, DateTime(2026, 12, 1));
  });

  testWidgets('오늘이 보는 기간에 없으면 오늘로 가기로 읽히고, 누르면 오늘을 고르고 그 달로 간다', (
    tester,
  ) async {
    await pumpPage(tester);
    final now = DateTime.now();
    final viewingToday = now.year == 2026 && now.month == 11;
    expect(
      find.bySemanticsLabel('오늘로 가기'),
      viewingToday ? findsNothing : findsOneWidget,
    );

    await tapVisible(tester, find.byTooltip('이전'));
    expect(find.bySemanticsLabel('오늘로 가기'), findsOneWidget);
    await tapVisible(tester, find.bySemanticsLabel('오늘로 가기'));

    expect(find.text('${now.year}년 ${now.month}월'), findsOneWidget);
    expect(find.bySemanticsLabel('오늘로 가기'), findsNothing);
    expect(find.bySemanticsLabel('오늘'), findsOneWidget);
    expect(settings().selectedDate.day, now.day);
  });

  testWidgets('보기를 바꾸면 고른 날이 든 기간을 보이고 그 단위로 옮긴다', (tester) async {
    await pumpPage(tester);

    await tapVisible(tester, find.byTooltip('일간'));
    expect(settings().viewType, CalendarViewType.day);
    expect(find.text('2026년 11월 9일 (월)'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('다음'));
    expect(find.text('2026년 11월 10일 (화)'), findsOneWidget);

    await tapVisible(tester, find.byTooltip('주간'));
    expect(settings().viewType, CalendarViewType.week);
    expect(find.text('11월 8일 – 14일'), findsOneWidget);
  });

  testWidgets('좁은 화면은 보기를 메뉴로 고르고, 앱바가 넘치지 않는다', (tester) async {
    await pumpPage(tester, size: const Size(360, 800));

    expect(tester.takeException(), isNull);
    expect(find.text('달력'), findsOneWidget);
    expect(find.byType(SegmentedButton<CalendarViewType>), findsNothing);
    await tapVisible(tester, find.byTooltip('보기 바꾸기'));
    await tapVisible(tester, find.text('일간'));

    expect(settings().viewType, CalendarViewType.day);
    expect(find.text('11월 9일 (월)'), findsOneWidget);
  });

  testWidgets('좁은 화면은 주·일 기간을 줄여 쓴다', (tester) async {
    await pumpPage(tester, size: const Size(360, 800));
    container.read(calendarSettingsProvider.notifier)
      ..setSelectedDate(DateTime(2026, 11, 30))
      ..setViewType(CalendarViewType.week);
    await tester.pumpAndSettle();
    expect(find.text('11.29 – 12.5'), findsOneWidget);

    container
        .read(calendarSettingsProvider.notifier)
        .setViewType(CalendarViewType.day);
    await tester.pumpAndSettle();
    expect(find.text('11월 30일 (월)'), findsOneWidget);
  });

  testWidgets('글자가 커서 한 줄에 다 들어가지 않으면 보는 기간을 윗줄에 다 보이고 이동 버튼은 아랫줄에 둔다', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpPage(tester, size: const Size(360, 800));

    final period = find.text('2026년 11월');
    expect(
      tester.renderObject<RenderParagraph>(period).didExceedMaxLines,
      isFalse,
    );
    expect(
      tester.getRect(period).bottom,
      lessThanOrEqualTo(tester.getRect(find.byTooltip('이전')).top),
    );
    // 두 줄이 된 이동 줄이 앱바 제목을 가리지 않는다
    expect(
      tester.getRect(find.text('달력')).bottom,
      lessThanOrEqualTo(tester.getRect(period).top),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('넓은 화면은 보는 기간과 이동 버튼을 한 줄에 둔다', (tester) async {
    await pumpPage(tester);

    expect(
      tester.getCenter(find.text('2026년 11월')).dy,
      moreOrLessEquals(tester.getCenter(find.byTooltip('이전')).dy, epsilon: 4),
    );
  });

  testWidgets('주가 두 달에 걸치면 끝에도 달을 쓴다', (tester) async {
    await pumpPage(tester);
    container.read(calendarSettingsProvider.notifier)
      ..setSelectedDate(DateTime(2026, 11, 30))
      ..setViewType(CalendarViewType.week);
    await tester.pumpAndSettle();

    expect(find.text('11월 29일 – 12월 5일'), findsOneWidget);
  });

  testWidgets('보는 기간을 누르면 날짜를 골라 그날을 고르고 그 기간으로 간다', (tester) async {
    await pumpPage(tester);
    await tapVisible(tester, find.byTooltip('다음'));
    await tapVisible(tester, find.text('2026년 12월'));
    await tapVisible(
      tester,
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text('20'),
      ),
    );
    await tapVisible(tester, find.text('확인'));

    expect(settings().selectedDate, DateTime(2026, 11, 20));
    expect(find.text('2026년 11월'), findsOneWidget);
  });

  testWidgets('메뉴는 달력 보기 설정을 열고, 고른 값을 바로 반영한다', (tester) async {
    await pumpPage(tester);
    await tapVisible(tester, find.byTooltip('보기 설정'));

    expect(find.text('달력 보기'), findsOneWidget);
    await tapVisible(tester, find.text('공휴일 표시'));
    await tapVisible(tester, find.text('주말 강조'));
    await tapVisible(tester, find.text('24시간제'));
    await tapVisible(tester, find.text('월요일'));
    await tapVisible(tester, find.widgetWithText(ChoiceChip, '2'));

    final s = settings();
    expect(s.showHolidays, isFalse);
    expect(s.highlightWeekends, isFalse);
    expect(s.use24HourFormat, isFalse);
    expect(s.firstDayOfWeek, DateTime.monday);
    expect(s.monthEventsPerDay, 2);
    expect(find.text('오후 1:00'), findsOneWidget);

    await tapVisible(tester, find.widgetWithText(ChoiceChip, '자동'));
    expect(settings().monthEventsPerDay, isNull);
  });

  testWidgets('일정 한 줄도 들어가지 않는 낮은 월 칸은 일정을 점으로 보이고 오류가 나지 않는다', (tester) async {
    await pumpPage(tester, size: const Size(800, 360));

    expect(tester.takeException(), isNull);
    final calendar = tester.widget<SfCalendar>(find.byType(SfCalendar));
    expect(
      calendar.monthViewSettings.appointmentDisplayMode,
      MonthAppointmentDisplayMode.indicator,
    );
  });

  testWidgets('칸이 넉넉한 월 보기는 일정을 막대로 보인다', (tester) async {
    await pumpPage(tester);

    expect(
      tester
          .widget<SfCalendar>(find.byType(SfCalendar))
          .monthViewSettings
          .appointmentDisplayMode,
      MonthAppointmentDisplayMode.appointment,
    );
  });

  testWidgets('추가 버튼은 새 일정 시트를 연다', (tester) async {
    await pumpPage(tester);
    await tapVisible(tester, find.byType(FloatingActionButton));

    expect(find.text('새 일정'), findsOneWidget);
  });

  testWidgets('필터에서 취소된 일정 표시를 켜고 초기화로 되돌린다', (tester) async {
    await pumpPage(tester);
    await tapVisible(tester, find.byTooltip('필터'));

    expect(find.text('필터'), findsOneWidget);
    expect(find.text('전체 표시'), findsOneWidget);
    await tapVisible(tester, find.text('취소된 일정 표시'));
    final shown = container.read(calendarFilterProvider).showCancelled;
    await tapVisible(tester, find.text('초기화'));

    expect(container.read(calendarFilterProvider).showCancelled, isNot(shown));
  });
}

class _FixedSettings extends CalendarSettings {
  @override
  CalendarSettingsState build() => CalendarSettingsState(
    selectedDate: DateTime(2026, 11, 9),
    displayDate: DateTime(2026, 11, 1),
    firstDayOfWeek: DateTime.sunday,
  );
}
