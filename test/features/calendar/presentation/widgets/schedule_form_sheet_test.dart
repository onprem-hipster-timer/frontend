import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_form_sheet.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/schedule_fixtures.dart';
import '../../../../helpers/sheet_host.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  late FakeSchedulesClient schedules;
  late GoRouter router;

  // 날짜 고르기 창은 오늘 기준 1년 전~2년 뒤만 받으므로 이번 달 안에서 고른다
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 10, 9);
  final end = DateTime(now.year, now.month, 10, 10);

  setUp(() {
    schedules = FakeSchedulesClient();
  });

  /// 일정 상세 자리. 받은 id를 글자로 보인다
  final detailRoute = GoRoute(
    path: AppRoute.scheduleDetail.path,
    name: AppRoute.scheduleDetail.name,
    builder: (context, state) =>
        Text('일정 상세 ${state.uri.queryParameters['id']}'),
  );

  Future<void> openCreate(
    WidgetTester tester, {
    DateTime? initialStartTime,
    DateTime? initialEndTime,
    DateTime? initialDate,
    String? initialTitle,
  }) async {
    router = await pumpSheetHost(
      tester,
      overrides: [schedulesApiProvider.overrideWithValue(schedules)],
      routes: [detailRoute],
      open: (context) => showScheduleFormSheet(
        context,
        initialStartTime: initialStartTime,
        initialEndTime: initialEndTime,
        initialDate: initialDate,
        initialTitle: initialTitle,
      ),
    );
  }

  Future<void> openEdit(WidgetTester tester, ScheduleRead schedule) async {
    schedules.schedules.add(schedule);
    router = await pumpSheetHost(
      tester,
      overrides: [schedulesApiProvider.overrideWithValue(schedules)],
      routes: [detailRoute],
      open: (context) => showScheduleEditSheet(context, schedule),
    );
  }

  Finder viewAction() => find.widgetWithText(SnackBarAction, '일정 보기');

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  String hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  group('새 일정', () {
    testWidgets('제목이 비면 오류를 보이고 보내지 않는다', (tester) async {
      await openCreate(tester, initialStartTime: start, initialEndTime: end);

      expect(find.text('새 일정'), findsOneWidget);
      await tapVisible(tester, find.text('저장'));
      expect(find.text('제목을 입력해주세요'), findsOneWidget);
      expect(schedules.created, isEmpty);
    });

    testWidgets('받은 시각을 보이고, 제목·설명을 다듬어 UTC 시각과 함께 보낸 뒤 닫는다', (tester) async {
      await openCreate(tester, initialStartTime: start, initialEndTime: end);

      expect(find.textContaining('${start.month}월 10일'), findsNWidgets(2));
      expect(find.textContaining('09:00'), findsOneWidget);
      expect(find.textContaining('10:00'), findsOneWidget);
      await tester.enterText(field('제목'), '  회의  ');
      await tester.enterText(field('설명 (선택사항)'), '  안건 정리  ');
      await tapVisible(tester, find.text('저장'));

      final body = schedules.created.single;
      expect(body.title, '회의');
      expect(body.description, '안건 정리');
      expect(body.startTime, start.toUtc());
      expect(body.startTime.isUtc, isTrue);
      expect(body.endTime, end.toUtc());
      expect(find.text('새 일정'), findsNothing);
      expect(find.text('일정이 생성되었습니다'), findsOneWidget);
    });

    testWidgets('설명이 비면 null로 보낸다', (tester) async {
      await openCreate(tester, initialStartTime: start, initialEndTime: end);
      await tester.enterText(field('제목'), '회의');
      await tapVisible(tester, find.text('저장'));

      expect(schedules.created.single.description, isNull);
    });

    testWidgets('날짜만 받으면 그날 지금의 다음 정각부터 1시간으로 잡는다', (tester) async {
      final day = DateTime(now.year, now.month, 12);
      await openCreate(tester, initialDate: day);
      final hour = DateTime.now().hour;
      final next = hour < 23 ? hour + 1 : hour;
      await tester.enterText(field('제목'), '회의');
      await tapVisible(tester, find.text('저장'));

      final body = schedules.created.single;
      expect(body.startTime.toLocal(), DateTime(day.year, day.month, 12, next));
      expect(
        body.endTime.toLocal(),
        DateTime(day.year, day.month, 12, next).add(const Duration(hours: 1)),
      );
    });

    testWidgets('종일을 켜면 시작은 그날 00:00, 종료는 종료일 23:59로 보내고 시각을 숨긴다', (
      tester,
    ) async {
      await openCreate(tester, initialStartTime: start, initialEndTime: end);
      await tapVisible(tester, find.text('종일'));

      expect(find.text('하루 종일 일정으로 설정됩니다'), findsOneWidget);
      expect(find.textContaining(':'), findsNothing);
      await tester.enterText(field('제목'), '휴가');
      await tapVisible(tester, find.text('저장'));

      final body = schedules.created.single;
      expect(body.startTime.toLocal(), DateTime(now.year, now.month, 10));
      expect(body.endTime.toLocal(), DateTime(now.year, now.month, 10, 23, 59));
    });

    testWidgets('제목을 받으면 채워 열고 그대로 보낼 수 있다', (tester) async {
      await openCreate(
        tester,
        initialStartTime: start,
        initialEndTime: end,
        initialTitle: '팀 회의',
      );
      await tapVisible(tester, find.text('저장'));

      expect(schedules.created.single.title, '팀 회의');
    });

    testWidgets('받은 시각이 그날 00:00부터 마지막 날 23:59까지면 종일로 연다', (tester) async {
      await openCreate(
        tester,
        initialStartTime: DateTime(now.year, now.month, 10),
        initialEndTime: DateTime(now.year, now.month, 11, 23, 59),
      );

      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
      expect(find.textContaining(':'), findsNothing);
    });

    testWidgets('종료가 시작보다 이르면 오류를 보이고 보내지 않는다', (tester) async {
      await openCreate(tester, initialStartTime: end, initialEndTime: start);

      expect(find.text('종료 시간은 시작 시간보다 늦어야 합니다'), findsOneWidget);
      await tester.enterText(field('제목'), '회의');
      await tapVisible(tester, find.text('저장'));

      expect(find.text('종료 시간은 시작 시간보다 늦어야 합니다'), findsNWidgets(2));
      expect(schedules.created, isEmpty);
    });

    testWidgets('시작을 종료보다 늦은 날로 고르면 종료를 그 1시간 뒤로 민다', (tester) async {
      await openCreate(tester, initialStartTime: start, initialEndTime: end);
      await tapVisible(tester, find.textContaining('09:00'));
      await tapVisible(tester, find.text('20'));
      await tapVisible(tester, find.text('확인'));
      await tapVisible(tester, find.text('확인'));
      await tester.enterText(field('제목'), '회의');
      await tapVisible(tester, find.text('저장'));

      final body = schedules.created.single;
      expect(body.startTime.toLocal(), DateTime(now.year, now.month, 20, 9));
      expect(body.endTime.toLocal(), DateTime(now.year, now.month, 20, 10));
    });

    testWidgets('종료를 시작보다 이른 날로 고르면 시작을 그 1시간 앞으로 당긴다', (tester) async {
      await openCreate(tester, initialStartTime: start, initialEndTime: end);
      await tapVisible(tester, find.textContaining('10:00'));
      await tapVisible(tester, find.text('5'));
      await tapVisible(tester, find.text('확인'));
      await tapVisible(tester, find.text('확인'));
      await tester.enterText(field('제목'), '회의');
      await tapVisible(tester, find.text('저장'));

      final body = schedules.created.single;
      expect(body.startTime.toLocal(), DateTime(now.year, now.month, 5, 9));
      expect(body.endTime.toLocal(), DateTime(now.year, now.month, 5, 10));
    });

    testWidgets('날짜 고르기를 취소하면 시각을 바꾸지 않는다', (tester) async {
      await openCreate(tester, initialStartTime: start, initialEndTime: end);
      await tapVisible(tester, find.textContaining('09:00'));
      await tapVisible(tester, find.text('20'));
      await tapVisible(
        tester,
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('취소'),
        ),
      );

      expect(find.textContaining('${start.month}월 10일'), findsNWidgets(2));
      expect(find.textContaining(hm(start)), findsOneWidget);
    });

    testWidgets('보내기에 실패하면 시트를 두고 오류를 알린다', (tester) async {
      schedules.writeError = Exception('서버 오류');
      await openCreate(tester, initialStartTime: start, initialEndTime: end);
      await tester.enterText(field('제목'), '회의');
      await tapVisible(tester, find.text('저장'));

      expect(find.text('새 일정'), findsOneWidget);
      expect(find.textContaining('일정 생성에 실패했습니다'), findsOneWidget);
    });

    testWidgets('취소는 보내지 않고 닫는다', (tester) async {
      await openCreate(tester, initialStartTime: start, initialEndTime: end);
      await tester.enterText(field('제목'), '회의');
      await tapVisible(tester, find.widgetWithText(OutlinedButton, '취소'));

      expect(find.text('새 일정'), findsNothing);
      expect(schedules.created, isEmpty);
    });

    testWidgets('만든 뒤 알림에 일정 보기가 있고, 누르기 전에는 화면을 옮기지 않는다', (tester) async {
      await openCreate(tester, initialStartTime: start, initialEndTime: end);
      await tester.enterText(field('제목'), '회의');
      await tapVisible(tester, find.text('저장'));

      expect(viewAction(), findsOneWidget);
      expect(router.state.uri.path, '/');
      expect(find.text('열기'), findsOneWidget);
    });

    testWidgets('닫힌 시트의 알림에서 일정 보기를 누르면 만든 일정의 상세로 간다', (tester) async {
      await openCreate(tester, initialStartTime: start, initialEndTime: end);
      await tester.enterText(field('제목'), '회의');
      await tapVisible(tester, find.text('저장'));
      expect(find.text('새 일정'), findsNothing);

      await tester.tap(viewAction());
      await tester.pumpAndSettle();

      expect(router.state.uri.path, AppRoute.scheduleDetail.path);
      expect(router.state.uri.queryParameters['id'], 'schedule-new-1');
      expect(find.text('일정 상세 schedule-new-1'), findsOneWidget);
    });

    testWidgets('일정 보기로 간 상세에서 뒤로 가면 시트를 열었던 화면으로 돌아온다', (tester) async {
      await openCreate(tester, initialStartTime: start, initialEndTime: end);
      await tester.enterText(field('제목'), '회의');
      await tapVisible(tester, find.text('저장'));
      await tester.tap(viewAction());
      await tester.pumpAndSettle();

      router.pop();
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/');
      expect(find.text('열기'), findsOneWidget);
    });

    testWidgets('보내기에 실패하면 일정 보기가 없다', (tester) async {
      schedules.writeError = Exception('서버 오류');
      await openCreate(tester, initialStartTime: start, initialEndTime: end);
      await tester.enterText(field('제목'), '회의');
      await tapVisible(tester, find.text('저장'));

      expect(find.textContaining('일정 생성에 실패했습니다'), findsOneWidget);
      expect(find.text('일정 보기'), findsNothing);
    });

    testWidgets('달력 탭 밖 화면(모임)에서 연 시트로 만들어도 일정 보기로 상세에 가고, 뒤로 가면 그 화면으로 돌아온다', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      router = GoRouter(
        initialLocation: '/m/meeting-1',
        routes: [
          GoRoute(
            path: '/m/:id',
            builder: (context, state) => Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showScheduleFormSheet(
                    context,
                    initialStartTime: start,
                    initialEndTime: end,
                    initialTitle: '팀 모임',
                  ),
                  child: const Text('모임 화면'),
                ),
              ),
            ),
          ),
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => Scaffold(body: shell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoute.calendar.path,
                    name: AppRoute.calendar.name,
                    builder: (context, state) => const Text('달력 화면'),
                    routes: [
                      GoRoute(
                        path: 'schedule/detail',
                        name: AppRoute.scheduleDetail.name,
                        builder: (context, state) =>
                            Text('일정 상세 ${state.uri.queryParameters['id']}'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          retry: appRetry,
          overrides: [schedulesApiProvider.overrideWithValue(schedules)],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko', 'KR')],
            locale: const Locale('ko', 'KR'),
          ),
        ),
      );
      await tester.tap(find.text('모임 화면'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('저장'));

      expect(schedules.created.single.title, '팀 모임');
      await tester.tap(viewAction());
      await tester.pumpAndSettle();
      expect(find.text('일정 상세 schedule-new-1'), findsOneWidget);
      expect(find.text('모임 화면'), findsNothing);

      router.pop();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/m/meeting-1');
      expect(find.text('모임 화면'), findsOneWidget);
    });
  });

  group('일정 수정', () {
    ScheduleRead existing({String? description = '안건'}) => makeSchedule(
      id: 'schedule-1',
      title: '회의',
      description: description,
      startTime: start.toUtc(),
      endTime: end.toUtc(),
    );

    testWidgets('기존 값을 채우고 바꾼 값을 보낸 뒤 닫는다', (tester) async {
      await openEdit(tester, existing());

      expect(find.text('일정 수정'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '회의'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '안건'), findsOneWidget);
      expect(find.textContaining('09:00'), findsOneWidget);

      await tester.enterText(field('제목'), '회의 2');
      await tapVisible(tester, find.text('수정'));

      final (id, body, options) = schedules.updated.single;
      expect(id, 'schedule-1');
      expect(body.title, '회의 2');
      expect(body.description, '안건');
      expect(body.startTime, start.toUtc());
      expect(body.endTime, end.toUtc());
      expect(explicitNullFields(options), isEmpty);
      expect(find.text('일정 수정'), findsNothing);
      expect(find.text('일정이 수정되었습니다'), findsOneWidget);
      expect(find.byType(SnackBarAction), findsNothing);
    });

    testWidgets('설명을 비우면 description을 null로 보내라고 표시한다', (tester) async {
      await openEdit(tester, existing());
      await tester.enterText(field('설명 (선택사항)'), '');
      await tapVisible(tester, find.text('수정'));

      final (_, body, options) = schedules.updated.single;
      expect(body.description, isNull);
      expect(explicitNullFields(options), ['description']);
    });

    testWidgets('다음 날 00:00에 끝나는 하루짜리 일정은 종일로 연다', (tester) async {
      final day = DateTime(now.year, now.month, 10);
      await openEdit(
        tester,
        makeSchedule(
          id: 'schedule-2',
          title: '휴가',
          startTime: day.toUtc(),
          endTime: day.add(const Duration(days: 1)).toUtc(),
        ),
      );

      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
    });

    testWidgets('폼에서 종일로 만든 일정(00:00~23:59)은 종일로 연다', (tester) async {
      final day = DateTime(now.year, now.month, 10);
      await openEdit(
        tester,
        makeSchedule(
          id: 'schedule-3',
          title: '휴가',
          startTime: day.toUtc(),
          endTime: DateTime(now.year, now.month, 10, 23, 59).toUtc(),
        ),
      );

      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
    });

    testWidgets('수정에 실패하면 시트를 두고 오류를 알린다', (tester) async {
      schedules.writeError = Exception('서버 오류');
      await openEdit(tester, existing());
      await tapVisible(tester, find.text('수정'));

      expect(find.text('일정 수정'), findsOneWidget);
      expect(find.textContaining('일정 수정에 실패했습니다'), findsOneWidget);
    });
  });
}
