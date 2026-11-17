import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/core/providers/shared_preferences_provider.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_create_page.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_mode_selector.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../meeting_fixtures.dart';

/// 다음 달의 [day]일. 다음 달은 늘 오늘 뒤라 모두 고를 수 있다
DateTime nextMonth(int day) {
  final now = DateTime.now();
  return DateTime.utc(now.year, now.month + 1, day);
}

Finder dayCell(DateTime day) =>
    find.bySemanticsLabel(RegExp('^${day.month}월 ${day.day}일'));

void main() {
  late FakeMeetingsClient meetings;
  late FakeVisibilityClient visibility;
  late List<String> calls;
  late GoRouter router;
  late SharedPreferences prefs;

  setUp(() async {
    calls = [];
    meetings = FakeMeetingsClient(calls: calls);
    visibility = FakeVisibilityClient(calls: calls);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// [signedIn]이 false면 로그인하지 않은 사람이 연다. [nextMonthShown]이면 다음 달로 넘겨 둔다
  Future<void> pumpPage(
    WidgetTester tester, {
    String? name = '지현',
    bool signedIn = true,
    bool nextMonthShown = true,
  }) async {
    tester.view.physicalSize = const Size(480, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = GoRouter(
      initialLocation: AppRoute.meetings.path,
      routes: [
        GoRoute(
          path: AppRoute.login.path,
          name: AppRoute.login.name,
          builder: (context, state) => const Text('로그인 화면'),
        ),
        GoRoute(
          path: AppRoute.meetings.path,
          name: AppRoute.meetings.name,
          builder: (context, state) => const MeetingCreatePage(),
        ),
        GoRoute(
          path: AppRoute.meetingCreated.path,
          name: AppRoute.meetingCreated.name,
          builder: (context, state) =>
              Text('만든 모임 ${state.pathParameters['meetingId']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        retry: appRetry,
        overrides: [
          ...meetingOverrides(
            meetings: meetings,
            visibility: visibility,
            name: name,
            signedIn: signedIn,
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    if (!nextMonthShown) return;
    await tester.tap(find.byTooltip('다음 달'));
    await tester.pumpAndSettle();
  }

  Future<void> tapDays(WidgetTester tester, Iterable<int> days) async {
    for (final day in days) {
      await tester.tap(dayCell(nextMonth(day)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.byTooltip('모임 만들기'));
    await tester.pumpAndSettle();
  }

  String location() => router.routerDelegate.currentConfiguration.uri.path;

  const loginReason = '모임을 만들고 나중에 고치려면 로그인이 필요해요';

  /// 방식 고르기가 제자리에서 옆으로 밀린 거리
  double modeOffset(WidgetTester tester, double rest) =>
      tester.getTopLeft(find.byType(MeetingModeSelector)).dx - rest;

  testWidgets('처음에는 시간별에 하루 시간 범위·시간 기준을 보이고 공개·게스트 로그인은 허용이다', (tester) async {
    await pumpPage(tester);

    expect(
      tester.getSemantics(find.text('시간별')),
      isSemantics(isSelected: true),
    );
    expect(find.text('6:00'), findsOneWidget);
    expect(find.text('18:00'), findsOneWidget);
    expect(find.text('한국 시간 기준'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('허용').first),
      isSemantics(isChecked: true, isEnabled: true),
    );
    expect(
      tester.getSemantics(find.text('허용').last),
      isSemantics(isChecked: true, isEnabled: true),
    );
  });

  testWidgets('입력은 날짜 → 시간 → 공개·게스트 → 제목 순서로 놓인다', (tester) async {
    await pumpPage(tester);

    final dates = tester.getTopLeft(find.text('모임 날짜')).dy;
    final time = tester.getTopLeft(find.text('모임 시간')).dy;
    final public = tester.getTopLeft(find.text('공개 여부')).dy;
    final guests = tester.getTopLeft(find.text('게스트 로그인')).dy;
    final title = tester.getTopLeft(find.byType(TextField)).dy;
    expect(dates, lessThan(time));
    expect(time, lessThan(public));
    expect(public, lessThan(guests));
    expect(guests, lessThan(title));
    final field = tester.getRect(find.byType(TextField));
    final arrow = tester.getRect(find.byIcon(Icons.arrow_forward));
    expect(arrow.left, greaterThan(field.right));
    expect((arrow.center.dy - field.center.dy).abs(), lessThan(2));
  });

  testWidgets('5일째 날까지는 시간별에 머물고, 6번째 날을 고르면 묻지 않고 날짜별로 바꾸며 방식 고르기를 떤다', (
    tester,
  ) async {
    await pumpPage(tester);
    final rest = tester.getTopLeft(find.byType(MeetingModeSelector)).dx;

    await tapDays(tester, [3, 4, 5, 6, 7]);
    expect(
      tester.getSemantics(find.text('시간별')),
      isSemantics(isSelected: true),
    );

    await tester.tap(dayCell(nextMonth(8)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(modeOffset(tester, rest), isNot(0));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(modeOffset(tester, rest), 0);
    expect(
      tester.getSemantics(find.text('날짜별')),
      isSemantics(isSelected: true),
    );
    expect(
      tester.getSemantics(find.text('시간별')),
      isSemantics(isEnabled: false),
    );
    expect(find.text('6:00'), findsNothing);
    expect(find.text('한국 시간 기준'), findsOneWidget);
  });

  testWidgets('시간별에서 기간 밖의 날은 고르면 날짜별로 바뀐다고 읽힌다', (tester) async {
    await pumpPage(tester);

    await tapDays(tester, [10]);

    expect(tester.getSemantics(dayCell(nextMonth(14))).hint, isEmpty);
    expect(tester.getSemantics(dayCell(nextMonth(15))).hint, '고르면 날짜별로 바뀝니다');
    expect(tester.getSemantics(dayCell(nextMonth(5))).hint, '고르면 날짜별로 바뀝니다');
  });

  testWidgets('날짜별을 직접 고르면 떨지 않는다', (tester) async {
    await pumpPage(tester);
    final rest = tester.getTopLeft(find.byType(MeetingModeSelector)).dx;

    await tester.tap(find.text('날짜별'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(modeOffset(tester, rest), 0);
  });

  testWidgets('공개를 끄면 게스트 로그인이 비허용으로 바뀌어 고를 수 없고 그 줄이 떤다', (tester) async {
    await pumpPage(tester);
    final guestRow = find.text('비허용').last;
    final rest = tester.getTopLeft(guestRow).dx;

    await tester.tap(find.text('비허용').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getTopLeft(guestRow).dx, isNot(rest));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(
      tester.getSemantics(find.text('비허용').last),
      isSemantics(isChecked: true, isEnabled: false),
    );
    await tester.tap(find.text('허용').last);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('허용').last),
      isSemantics(isChecked: false),
    );

    await tester.tap(find.text('허용').first);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('비허용').last),
      isSemantics(isChecked: true, isEnabled: true),
    );
    await tester.tap(find.text('허용').last);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('허용').last),
      isSemantics(isChecked: true),
    );
  });

  testWidgets('날짜를 고르지 않고 화살표를 누르면 날짜를 고르라고 알리고 보내지 않는다', (tester) async {
    await pumpPage(tester);

    await submit(tester);

    expect(find.text('모임 날짜를 골라 주세요'), findsOneWidget);
    expect(meetings.created, isEmpty);
    expect(location(), AppRoute.meetings.path);
  });

  testWidgets('제목을 비우면 이름이 든 자리 글자로 만들고, 공개로 열고 게스트 로그인을 켠 뒤 만든 뒤 화면으로 간다', (
    tester,
  ) async {
    await pumpPage(tester);
    await tapDays(tester, [3, 5]);
    await tester.tap(find.text('6:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('9:00').last);
    await tester.pumpAndSettle();

    await submit(tester);

    final body = meetings.created.single;
    expect(body.title, '지현님의 모임 일정');
    expect(body.timezone, 'Asia/Seoul');
    expect(body.startDate, nextMonth(3));
    expect(body.endDate, nextMonth(5));
    expect(
      body.availableDays,
      [weekdayNumber(nextMonth(3)), weekdayNumber(nextMonth(5))]..sort(),
    );
    expect(body.startTime, '09:00:00');
    expect(body.endTime, '18:00:00');
    final (type, id, update) = visibility.updates.single;
    expect(type, ResourceType.meeting);
    expect(id, 'meeting-new-1');
    expect(update.level, VisibilityLevel.public);
    expect(meetings.updates.single.$1, 'meeting-new-1');
    expect(calls, [
      'create',
      'visibility public',
      'update {allow_guests: true}',
    ]);
    expect(location(), '/meetings/meeting-new-1/created');
  });

  testWidgets('게스트 로그인만 끄면 공개로 열고 게스트 로그인은 켜지 않는다', (tester) async {
    await pumpPage(tester);
    await tapDays(tester, [3]);
    await tester.tap(find.text('비허용').last);
    await tester.pumpAndSettle();

    await submit(tester);

    expect(calls, ['create', 'visibility public']);
    expect(location(), '/meetings/meeting-new-1/created');
  });

  testWidgets('이름이 없으면 모임 일정을, 제목을 쓰면 그 제목을 앞뒤 공백 없이 보낸다', (tester) async {
    await pumpPage(tester, name: null);
    expect(find.text('모임 일정'), findsOneWidget);
    await tapDays(tester, [3]);

    await tester.enterText(find.byType(TextField), '  주간 회의 ');
    await submit(tester);

    expect(meetings.created.single.title, '주간 회의');
  });

  testWidgets('공개를 끄면 공개 범위를 보내지 않는다', (tester) async {
    await pumpPage(tester);
    await tapDays(tester, [3]);
    await tester.tap(find.text('비허용').first);
    await tester.pumpAndSettle();

    await submit(tester);

    expect(calls, ['create']);
    expect(location(), '/meetings/meeting-new-1/created');
  });

  testWidgets('날짜별·요일별은 하루 전체로, 요일별은 누른 날부터 7일로 보낸다', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('요일별'));
    await tester.pumpAndSettle();
    expect(find.text('6:00'), findsNothing);
    await tapDays(tester, [10]);

    await submit(tester);

    final body = meetings.created.single;
    expect(body.startDate, nextMonth(10));
    expect(body.endDate, nextMonth(16));
    expect(body.availableDays, [0, 1, 2, 3, 4, 5, 6]);
    expect(body.startTime, '00:00:00');
    expect(body.endTime, '00:00:00');
  });

  testWidgets('만들지 못하면 알리고 화면과 값을 그대로 둔다', (tester) async {
    meetings.createError = StateError('서버 오류');
    await pumpPage(tester);
    await tapDays(tester, [3]);

    await submit(tester);

    expect(find.textContaining('모임을 만들지 못했습니다'), findsOneWidget);
    expect(calls, ['create']);
    expect(location(), AppRoute.meetings.path);
    expect(
      tester.getSemantics(dayCell(nextMonth(3))),
      isSemantics(isSelected: true),
    );
  });

  testWidgets('공개로 열지 못하면 만든 모임을 지우고 알리며, 다시 누르면 새로 만든다', (tester) async {
    visibility.setError = StateError('공개 실패');
    await pumpPage(tester);
    await tapDays(tester, [3]);

    await submit(tester);

    expect(calls, ['create', 'visibility public', 'delete meeting-new-1']);
    expect(find.textContaining('모임을 만들지 못했습니다'), findsOneWidget);
    expect(location(), AppRoute.meetings.path);

    visibility.setError = null;
    await submit(tester);
    expect(meetings.created, hasLength(2));
    expect(location(), '/meetings/meeting-new-2/created');
  });

  testWidgets('게스트 로그인을 켜지 못하면 만든 모임을 지우고 알리며, 다시 누르면 새로 만든다', (tester) async {
    meetings.updateError = StateError('게스트 실패');
    await pumpPage(tester);
    await tapDays(tester, [3]);

    await submit(tester);

    expect(calls, [
      'create',
      'visibility public',
      'update {allow_guests: true}',
      'delete meeting-new-1',
    ]);
    expect(find.textContaining('게스트 실패'), findsOneWidget);
    expect(location(), AppRoute.meetings.path);

    meetings.updateError = null;
    await submit(tester);
    expect(meetings.created, hasLength(2));
    expect(location(), '/meetings/meeting-new-2/created');
  });

  testWidgets('만든 모임을 지우지도 못하면 처음 실패를 알린다', (tester) async {
    meetings
      ..updateError = StateError('게스트 실패')
      ..deleteError = StateError('지우기 실패');
    await pumpPage(tester);
    await tapDays(tester, [3]);

    await submit(tester);

    expect(meetings.deleted, ['meeting-new-1']);
    expect(find.textContaining('게스트 실패'), findsOneWidget);
    expect(find.textContaining('지우기 실패'), findsNothing);
    expect(location(), AppRoute.meetings.path);
  });

  testWidgets('만드는 중에는 화살표를 막고 완료 키를 다시 눌러도 한 번만 보낸다', (tester) async {
    final gate = Completer<void>();
    meetings.createGate = gate.future;
    await pumpPage(tester);
    await tapDays(tester, [3]);

    await tester.tap(find.byTooltip('모임 만들기'));
    await tester.pump();
    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.tap(find.byTooltip('모임 만들기'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(meetings.created, hasLength(1));
  });

  group('로그인하지 않았으면', () {
    testWidgets('날짜·시간·공개·제목을 다 넣을 수 있고, 화살표를 누르면 만들지 않고 까닭과 로그인을 그 아래에 보인다', (
      tester,
    ) async {
      await pumpPage(tester, signedIn: false);
      expect(find.text(loginReason), findsNothing);
      await tapDays(tester, [3, 4]);
      await tester.tap(find.text('비허용').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '스터디');

      await submit(tester);

      expect(meetings.created, isEmpty);
      expect(calls, isEmpty);
      expect(location(), AppRoute.meetings.path);
      expect(find.text(loginReason), findsOneWidget);
      expect(find.text('입력한 내용은 그대로 남아요'), findsOneWidget);
      final login = find.widgetWithText(FilledButton, '로그인하고 계속하기');
      expect(login, findsOneWidget);
      expect(
        tester.getTopLeft(login).dy,
        greaterThan(tester.getBottomLeft(find.byType(TextField)).dy),
      );
    });

    testWidgets('날짜를 고르지 않았으면 로그인보다 날짜를 먼저 고르라고 한다', (tester) async {
      await pumpPage(tester, signedIn: false);

      await submit(tester);

      expect(find.text('모임 날짜를 골라 주세요'), findsOneWidget);
      expect(find.text(loginReason), findsNothing);
    });

    testWidgets(
      '로그인하고 계속하기는 이 만들기 화면으로 돌아오게 로그인으로 가고, 로그인해 다시 열면 넣은 그대로이며 화살표 한 번으로 만든다',
      (tester) async {
        await pumpPage(tester, signedIn: false);
        await tapDays(tester, [3, 4]);
        await tester.tap(find.text('6:00'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('9:00').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('비허용').last);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '스터디');
        await submit(tester);

        await tester.tap(find.widgetWithText(FilledButton, '로그인하고 계속하기'));
        await tester.pumpAndSettle();

        expect(
          router.routerDelegate.currentConfiguration.uri.toString(),
          '${AppRoute.login.path}?redirect=${Uri.encodeComponent(AppRoute.meetings.path)}',
        );

        // 로그인을 마치고 돌아와 화면을 새로 연다(Google 로그인은 앱을 새로 띄운다)
        await tester.pumpWidget(const SizedBox());
        await pumpPage(tester, nextMonthShown: false);

        expect(find.text('스터디'), findsOneWidget);
        expect(find.text('9:00'), findsOneWidget);
        expect(find.text(loginReason), findsNothing);
        expect(
          tester.getSemantics(find.text('비허용').last),
          isSemantics(isChecked: true),
        );
        expect(
          tester.getSemantics(dayCell(nextMonth(3))),
          isSemantics(isSelected: true),
          reason: '고른 날짜의 달을 보인다',
        );

        await submit(tester);

        final body = meetings.created.single;
        expect(body.title, '스터디');
        expect(body.startDate, nextMonth(3));
        expect(body.endDate, nextMonth(4));
        expect(body.startTime, '09:00:00');
        expect(calls, ['create', 'visibility public']);
        expect(location(), '/meetings/meeting-new-1/created');
      },
    );

    testWidgets('둔 값은 한 번만 꺼낸다', (tester) async {
      await pumpPage(tester, signedIn: false);
      await tapDays(tester, [3]);
      await tester.enterText(find.byType(TextField), '스터디');
      await submit(tester);
      await tester.tap(find.widgetWithText(FilledButton, '로그인하고 계속하기'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await pumpPage(tester, nextMonthShown: false);
      expect(find.text('스터디'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await pumpPage(tester, nextMonthShown: false);
      expect(find.text('스터디'), findsNothing);
    });
  });
}
