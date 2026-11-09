import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/pages/calendar_page.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/sheet_host.dart';

/// 달력 화면의 제목·기간 이동·보기 전환·날짜 고르기·새 일정·필터
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  late ProviderContainer container;

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    container = ProviderContainer(
      overrides: [
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

  testWidgets('월 보기 제목과 고른 날짜를 보이고, 이전·다음은 달을 옮긴다', (tester) async {
    await pumpPage(tester);

    expect(find.text('2026년 11월'), findsOneWidget);
    expect(find.text('11월 9일 (월)'), findsOneWidget);

    await tapVisible(tester, find.byIcon(Icons.chevron_left).first);
    expect(find.text('2026년 10월'), findsOneWidget);
    await tapVisible(tester, find.byIcon(Icons.chevron_right).first);
    await tapVisible(tester, find.byIcon(Icons.chevron_right).first);
    expect(find.text('2026년 12월'), findsOneWidget);
  });

  testWidgets('오늘은 오늘이 든 달로 돌아간다', (tester) async {
    await pumpPage(tester);
    await tapVisible(tester, find.byTooltip('오늘'));

    final now = DateTime.now();
    expect(find.text('${now.year}년 ${now.month}월'), findsOneWidget);
    expect(settings().selectedDate.day, now.day);
  });

  testWidgets('보기를 바꾸면 제목 형식과 이동 단위가 바뀐다', (tester) async {
    await pumpPage(tester);

    String dayTitle(DateTime d) =>
        DateFormat('yyyy년 M월 d일 (E)', 'ko').format(d);

    await tapVisible(tester, find.byTooltip('일간'));
    expect(settings().viewType, CalendarViewType.day);
    final shown = settings().displayDate;
    expect(find.text(dayTitle(shown)), findsOneWidget);
    await tapVisible(tester, find.byIcon(Icons.chevron_right).first);
    expect(
      find.text(dayTitle(shown.add(const Duration(days: 1)))),
      findsOneWidget,
    );

    await tapVisible(tester, find.byTooltip('주간'));
    expect(settings().viewType, CalendarViewType.week);
    expect(find.textContaining(' - '), findsOneWidget);
  });

  testWidgets('제목을 누르면 날짜를 골라 그 날짜로 옮긴다', (tester) async {
    await pumpPage(tester);
    await tapVisible(tester, find.text('2026년 11월'));
    await tapVisible(
      tester,
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text('20'),
      ),
    );
    await tapVisible(tester, find.text('확인'));

    expect(settings().selectedDate, DateTime(2026, 11, 20));
    expect(find.text('11월 20일 (금)'), findsOneWidget);
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
