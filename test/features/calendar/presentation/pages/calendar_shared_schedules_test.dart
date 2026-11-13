import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/shared_preferences_provider.dart';
import 'package:momeet/features/calendar/presentation/pages/calendar_page.dart';
import 'package:momeet/features/calendar/presentation/pages/schedule_detail_page.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_detail_providers.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view_actions.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_appointment_block.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_list_sheet.dart';
import 'package:momeet/features/calendar/presentation/widgets/shared_schedule_mark.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/providers/friend_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/schedule_fixtures.dart';
import '../../../../helpers/timer_fixtures.dart';

/// 달력에서 다른 사람이 공유한 일정을 내 일정과 함께, 보기만 하게 보인다
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  final mine = makeSchedule(
    id: 'mine-1',
    title: '팀 회의',
    startTime: DateTime(2026, 11, 9, 9),
    endTime: DateTime(2026, 11, 9, 10),
  ).copyWith(ownerId: 'me');
  final shared =
      makeSchedule(
        id: 'shared-1',
        title: '영희 발표',
        startTime: DateTime(2026, 11, 9, 13),
        endTime: DateTime(2026, 11, 9, 14),
        sourceTodoId: 'todo-of-friend',
      ).copyWith(
        ownerId: 'friend-1',
        isShared: true,
        visibilityLevel: VisibilityLevel.friends,
      );
  final friends = [makeFriend('friend-1', displayName: '영희')];

  late FakeSchedulesClient schedules;

  setUp(() {
    schedules = FakeSchedulesClient([mine, shared]);
  });

  Future<ProviderContainer> pumpCalendar(
    WidgetTester tester, {
    CalendarViewType viewType = CalendarViewType.day,
  }) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        schedulesApiProvider.overrideWithValue(schedules),
        calendarSettingsProvider.overrideWith(() => _FixedSettings(viewType)),
        currentHolidaysProvider.overrideWith((ref) async => const []),
        friendsProvider.overrideWith((ref) async => friends),
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
    return container;
  }

  Finder block(String title) => find.ancestor(
    of: find.text(title),
    matching: find.byType(ScheduleAppointmentBlock),
  );

  testWidgets('내 일정과 공유받은 일정을 한 번에 받아 함께 보인다', (tester) async {
    await pumpCalendar(tester);

    expect(schedules.readScopes, everyElement(ResourceScope.all));
    expect(find.text('팀 회의'), findsOneWidget);
    expect(find.text('영희 발표'), findsOneWidget);
  });

  for (final viewType in [
    CalendarViewType.month,
    CalendarViewType.day,
    CalendarViewType.agenda,
  ]) {
    testWidgets('${viewType.name} 보기에서 공유받은 일정만 공유 표시를 둔다', (tester) async {
      await pumpCalendar(tester, viewType: viewType);

      expect(
        tester.widget<ScheduleAppointmentBlock>(block('영희 발표')).shared,
        isTrue,
      );
      expect(
        tester.widget<ScheduleAppointmentBlock>(block('팀 회의')).shared,
        isFalse,
      );
      expect(
        find.descendant(
          of: block('영희 발표'),
          matching: find.byType(SharedScheduleMark),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: block('팀 회의'),
          matching: find.byType(SharedScheduleMark),
        ),
        findsNothing,
      );
    });
  }

  group('끌거나 길이를 바꾸기', () {
    /// 달력이 [id] 일정을 [hours]시간 옮겨 그린 것처럼 바꾸고 그 일정을 돌려준다
    Future<Appointment> moveInPlace(
      ProviderContainer container,
      String id,
      int hours,
    ) async {
      final source = await container.read(
        scheduleOnlyDataSourceProvider.future,
      );
      final appointment = source.getAppointmentById(id)!;
      appointment.startTime = appointment.startTime.add(Duration(hours: hours));
      appointment.endTime = appointment.endTime.add(Duration(hours: hours));
      return appointment;
    }

    testWidgets('공유받은 일정은 보내지 않고 제자리로 되돌리며 알린다', (tester) async {
      final container = await pumpCalendar(tester);
      final appointment = await moveInPlace(container, 'shared-1', 2);
      final context = tester.element(find.byType(CalendarViewWidget));
      final ref = tester
          .state<ConsumerState>(find.byType(CalendarViewWidget))
          .ref;

      moveDraggedSchedule(
        context,
        ref,
        AppointmentDragEndDetails(
          appointment,
          null,
          null,
          appointment.startTime,
        ),
      );
      await tester.pumpAndSettle();

      expect(schedules.updated, isEmpty);
      expect(find.text('공유받은 일정은 옮기거나 길이를 바꿀 수 없습니다'), findsOneWidget);
      final redrawn = await container.read(
        scheduleOnlyDataSourceProvider.future,
      );
      expect(
        redrawn.getAppointmentById('shared-1')!.startTime,
        shared.startTime.toLocal(),
      );

      resizeSchedule(
        context,
        ref,
        AppointmentResizeEndDetails(
          appointment,
          null,
          appointment.startTime,
          appointment.endTime,
        ),
      );
      await tester.pumpAndSettle();
      expect(schedules.updated, isEmpty);
    });

    testWidgets('내 일정은 그대로 옮긴다', (tester) async {
      final container = await pumpCalendar(tester);
      final appointment = await moveInPlace(container, 'mine-1', 2);

      moveDraggedSchedule(
        tester.element(find.byType(CalendarViewWidget)),
        tester.state<ConsumerState>(find.byType(CalendarViewWidget)).ref,
        AppointmentDragEndDetails(
          appointment,
          null,
          null,
          appointment.startTime,
        ),
      );
      await tester.pumpAndSettle();

      expect(schedules.updated.single.$1, 'mine-1');
      expect(find.text('공유받은 일정은 옮기거나 길이를 바꿀 수 없습니다'), findsNothing);
    });
  });

  testWidgets('그날 일정 목록에서 공유받은 일정은 공유한 사람을 보인다', (tester) async {
    await tester.pumpWidget(
      pumpApp(
        Scaffold(
          body: ScheduleListSheet(
            date: DateTime(2026, 11, 9),
            schedules: [mine, shared],
          ),
        ),
        overrides: [friendsProvider.overrideWith((ref) async => friends)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('13:00 - 14:00 · 영희님이 공유'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, '팀 회의'),
        matching: find.textContaining('공유'),
      ),
      findsNothing,
    );
  });

  group('공유받은 일정 상세', () {
    Future<void> pumpDetail(
      WidgetTester tester, {
      List<FriendRead>? friendList,
    }) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        pumpApp(
          const ScheduleDetailPage(scheduleId: 'shared-1'),
          overrides: [
            schedulesApiProvider.overrideWithValue(schedules),
            friendsProvider.overrideWith((ref) async => friendList ?? friends),
            scheduleTimersProvider('shared-1').overrideWith(
              (ref) async => throw StateError('공유받은 일정의 타이머는 읽지 않는다'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('공유한 사람과 보기만 할 수 있다는 것을 알리고 일정 정보를 보인다', (tester) async {
      await pumpDetail(tester);

      expect(find.text('영희 발표'), findsOneWidget);
      expect(find.text('영희님이 공유'), findsOneWidget);
      expect(find.text('공유받은 일정이라 보기만 할 수 있습니다'), findsOneWidget);
      expect(find.text('시간'), findsOneWidget);
    });

    testWidgets('수정·삭제·할 일로 바꾸기·연결된 할 일·공유 설정·타이머를 두지 않는다', (tester) async {
      await pumpDetail(tester);

      for (final label in [
        '수정',
        '삭제',
        '할 일로 변환',
        '연결된 할 일 보기',
        '공유 설정',
        '타이머 기록',
      ]) {
        expect(find.textContaining(label), findsNothing, reason: label);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('친구 목록에 없는 사람이 공유했으면 공유받았다고만 한다', (tester) async {
      await pumpDetail(tester, friendList: const []);

      expect(find.text('공유받음'), findsOneWidget);
    });
  });
}

class _FixedSettings extends CalendarSettings {
  _FixedSettings(this.viewType);

  final CalendarViewType viewType;

  @override
  CalendarSettingsState build() => CalendarSettingsState(
    viewType: viewType,
    selectedDate: DateTime(2026, 11, 9),
    displayDate: DateTime(2026, 11, 9),
    firstDayOfWeek: DateTime.sunday,
  );
}
