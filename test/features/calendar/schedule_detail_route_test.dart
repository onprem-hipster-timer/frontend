import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/calendar/presentation/pages/calendar_page.dart';
import 'package:momeet/features/calendar/presentation/pages/schedule_detail_page.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_detail_providers.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_month_cell.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_appointment_block.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_list_sheet.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../helpers/fake_rest_clients.dart';
import '../../helpers/kratos_mocks.dart';
import '../../helpers/schedule_fixtures.dart';

/// 실제 라우터(routerProvider)로 달력에서 일정 상세를 열고 닫을 때 브라우저에 알리는 주소를 본다.
void main() {
  late KratosTestHarness harness;

  setUpAll(() async {
    registerKratosFallbacks();
    await initializeDateFormatting('ko');
  });

  setUp(() async {
    harness = await KratosTestHarness.create();
  });

  final day = DateTime(2026, 11, 18);
  final schedule = makeSchedule(
    id: 'schedule-1',
    title: '팀 회의',
    startTime: DateTime(2026, 11, 18, 10).toUtc(),
    endTime: DateTime(2026, 11, 18, 11).toUtc(),
  );
  const detail = '/schedule/detail?id=schedule-1';

  Future<GoRouter> pumpCalendar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: appRetry,
        overrides: [
          ...harness.overrides,
          usersApiProvider.overrideWithValue(
            FakeUsersClient(consentRequired: false),
          ),
          schedulesApiProvider.overrideWithValue(
            FakeSchedulesClient([schedule]),
          ),
          calendarSettingsProvider.overrideWith(_November.new),
          currentHolidaysProvider.overrideWith((ref) async => const []),
          scheduleTimersProvider(
            'schedule-1',
          ).overrideWith((ref) async => const []),
          timerWsClientProvider.overrideWithValue(null),
          analyticsConsentBridgeProvider.overrideWithValue(
            InMemoryAnalyticsConsentBridge(),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            routerConfig: ref.watch(routerProvider),
            locale: const Locale('ko', 'KR'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final router = ProviderScope.containerOf(
      tester.element(find.byType(Router<Object>)),
    ).read(routerProvider);
    expect(find.byType(CalendarPage), findsOneWidget);
    return router;
  }

  /// 브라우저 주소창에 알린 주소
  String address(GoRouter router) =>
      router.routeInformationProvider.value.uri.toString();

  /// 상세의 뒤로 가기를 누르면 달력이고 주소의 경로도 달력이다
  Future<void> backToCalendar(WidgetTester tester, GoRouter router) async {
    await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleDetailPage), findsNothing);
    expect(find.byType(CalendarPage), findsOneWidget);
    // go_router는 닫은 상세의 쿼리(`?id=`)를 달력 주소에 남기므로 경로만 본다
    expect(Uri.parse(address(router)).path, AppRoute.calendar.path);
  }

  // 달력은 모바일에서 월 보기의 일정 누르기를 날짜 칸으로 받으므로, 웹처럼 일정으로 받는 데스크톱 플랫폼에서 돈다
  testWidgets('달력에서 일정을 누르면 상세를 열고 주소가 상세이며, 뒤로 가면 달력이다', (tester) async {
    final router = await pumpCalendar(tester);
    expect(address(router), AppRoute.calendar.path);

    await tester.tap(find.byType(ScheduleAppointmentBlock));
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleDetailPage), findsOneWidget);
    expect(find.text('팀 회의'), findsOneWidget);
    expect(address(router), detail);

    await backToCalendar(tester, router);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('날짜의 일정 목록에서 일정을 누르면 목록을 닫고 상세를 열며 주소가 상세이고, 뒤로 가면 달력이다', (
    tester,
  ) async {
    final router = await pumpCalendar(tester);
    final cell = find.byWidgetPredicate(
      (widget) => widget is CalendarMonthCell && widget.details.date == day,
    );
    await tester.tapAt(tester.getTopRight(cell) + const Offset(-4, 4));
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleListSheet), findsOneWidget);
    expect(address(router), AppRoute.calendar.path);

    await tester.tap(
      find.descendant(
        of: find.byType(ScheduleListSheet),
        matching: find.text('팀 회의'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleListSheet), findsNothing);
    expect(find.byType(ScheduleDetailPage), findsOneWidget);
    expect(address(router), detail);

    await backToCalendar(tester, router);
  });
}

/// 2026년 11월을 보는 월 보기
class _November extends CalendarSettings {
  @override
  CalendarSettingsState build() => CalendarSettingsState(
    selectedDate: DateTime(2026, 11, 9),
    displayDate: DateTime(2026, 11, 1),
    firstDayOfWeek: DateTime.sunday,
  );
}
