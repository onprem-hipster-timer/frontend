import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/auth/guest_user.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_edit_page.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_page.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_form_settings.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../../../helpers/fake_rest_clients.dart';
import '../../meeting_fixtures.dart';

DateTime march(int day) => DateTime.utc(2027, 3, day);

Finder dayCell(DateTime day) =>
    find.bySemanticsLabel(RegExp('^${day.month}월 ${day.day}일'));

/// 낱말 잇기 문자(U+2060)를 빼고 [text]인 글자
Finder plain(String text) => find.byWidgetPredicate(
  (widget) => widget is Text && widget.data?.replaceAll('⁠', '') == text,
);

const saved = '모임 설정을 저장했어요';
const modeNotice = '이미 넣은 답이 다르게 보일 수 있어요. 답은 지워지지 않아요';
const daysNotice = '빠진 날에 넣은 답은 보이지 않아요. 답은 지워지지 않아요';

Object invalidMeeting(String field) => httpError(
  '/v1/meetings/meeting-1',
  422,
  data: {
    'error_type': 'InvalidMeetingError',
    'detail': [
      {
        'loc': ['body', field],
        'msg': 'invalid',
      },
    ],
  },
);

void main() {
  late List<String> calls;
  late FakeMeetingsClient meetings;
  late FakeVisibilityClient visibility;

  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('ko');
  });

  setUp(() {
    calls = [];
    meetings = FakeMeetingsClient(
      meeting: makeMeeting(ownerId: 'user-1'),
      calls: calls,
    );
    visibility = FakeVisibilityClient(calls: calls)
      ..current = visibilityOf(VisibilityLevel.public);
  });

  /// [initialLocation]을 연다. 기본은 모임 화면이고, 연필을 누르면 설정 화면이 그 위에 쌓인다
  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    String initialLocation = '/meetings/meeting-1',
    bool signedIn = true,
    GuestUser? guest,
    Size size = const Size(480, 2400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // 앞서 띄운 앱의 provider와 화면 상태를 남기지 않는다
    await tester.pumpWidget(const SizedBox());
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoute.calendar.path,
          name: AppRoute.calendar.name,
          builder: (context, state) => const Scaffold(body: Text('처음 화면')),
        ),
        GoRoute(
          path: AppRoute.meetingEdit.path,
          name: AppRoute.meetingEdit.name,
          builder: (context, state) =>
              MeetingEditPage(meetingId: state.pathParameters['meetingId']!),
        ),
        GoRoute(
          path: AppRoute.meeting.path,
          name: AppRoute.meeting.name,
          builder: (context, state) =>
              MeetingPage(meetingId: state.pathParameters['meetingId']!),
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
            signedIn: signedIn,
            guest: guest,
          ),
          schedulesApiProvider.overrideWithValue(FakeSchedulesClient()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  final pencil = find.byTooltip('모임 설정');

  /// 모임 화면에서 연필을 눌러 설정을 연다
  Future<GoRouter> openEdit(WidgetTester tester) async {
    final router = await pumpApp(tester);
    await tester.tap(pencil);
    await tester.pumpAndSettle();
    expect(find.byType(MeetingEditPage), findsOneWidget);
    return router;
  }

  /// [label] 글자(여럿이면 [at]번째)를 눌러 고른다
  Future<void> press(WidgetTester tester, String label, {int at = 0}) async {
    final target = find.text(label).at(at);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) => press(tester, '저장하기');

  /// '공개 여부'는 첫 허용/비허용, '게스트 로그인'은 둘째다
  Future<void> setPublic(WidgetTester tester, bool value) =>
      press(tester, value ? '허용' : '비허용');

  Future<void> setGuests(WidgetTester tester, bool value) =>
      press(tester, value ? '허용' : '비허용', at: 1);

  Future<void> addAccess(WidgetTester tester, String input) async {
    final field = find.widgetWithText(TextField, '이메일 또는 도메인');
    await tester.ensureVisible(field);
    await tester.enterText(field, input);
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();
  }

  Future<void> typeTitle(WidgetTester tester, String title) async {
    final field = find.widgetWithText(TextField, '제목');
    await tester.ensureVisible(field);
    await tester.enterText(field, title);
    await tester.pumpAndSettle();
  }

  MeetingDraft shownDraft(WidgetTester tester) => tester
      .widget<MeetingFormSettings>(find.byType(MeetingFormSettings))
      .draft;

  bool saveEnabled(WidgetTester tester) => tester
      .widget<FilledButton>(find.widgetWithText(FilledButton, '저장하기'))
      .enabled;

  group('연필', () {
    testWidgets('주인에게는 제목 옆에 모임 설정 연필이 있고 누르면 설정 화면이다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester);

      expect(
        tester.getSemantics(pencil),
        isSemantics(
          tooltip: '모임 설정',
          isButton: true,
          hasTapAction: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
      await tester.tap(pencil);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, '모임 설정'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('주인이 아닌 회원, 게스트, 로그인하지 않은 방문자에게는 없다', (tester) async {
      meetings.meeting = makeMeeting(ownerId: 'owner-1');
      await pumpApp(tester);
      expect(find.text('팀 회의'), findsWidgets);
      expect(pencil, findsNothing);

      await pumpApp(tester, signedIn: false);
      expect(find.text('팀 회의'), findsWidgets);
      expect(pencil, findsNothing);

      meetings.guestName = '손님';
      await pumpApp(
        tester,
        guest: const GuestUser(
          id: 'guest-1',
          handle: 'guest-1@guest.invalid',
          name: '손님',
          meetingId: 'meeting-1',
        ),
      );
      expect(find.text('팀 회의'), findsWidgets);
      expect(pencil, findsNothing);
    });
  });

  group('처음 값', () {
    testWidgets('지금 제목, 날짜, 방식, 하루 범위, 공개와 게스트를 채운다', (tester) async {
      meetings.meeting = makeMeeting(
        ownerId: 'user-1',
        excludedDates: [march(3)],
        startTime: '09:00:00',
        endTime: '00:00:00',
      ).copyWith(allowGuests: true);
      await openEdit(tester);

      expect(find.widgetWithText(TextField, '팀 회의'), findsOneWidget);
      final draft = shownDraft(tester);
      expect(draft.mode, MeetingMode.hourly);
      expect(draft.dates.days, [march(1), march(2), march(4), march(5)]);
      expect((draft.startHour, draft.endHour), (9, 24));
      expect((draft.isPublic, draft.allowGuests), (true, true));
      expect(saveEnabled(tester), isFalse);
    });

    testWidgets('날짜별·요일별 모임은 그 방식으로 채운다', (tester) async {
      for (final mode in [MeetingMode.daily, MeetingMode.weekly]) {
        meetings.meeting = makeMeeting(
          ownerId: 'user-1',
          mode: mode,
          endDate: march(7),
          startTime: '00:00:00',
          endTime: '00:00:00',
        );
        await pumpApp(tester, initialLocation: '/meetings/meeting-1/edit');
        expect(shownDraft(tester).mode, mode);
        expect(shownDraft(tester).dates.span, 7);
        expect(saveEnabled(tester), isFalse);
      }
    });

    testWidgets('정한 이메일·도메인 비공개면 넣은 값을 보인다', (tester) async {
      visibility.current = visibilityOf(
        VisibilityLevel.allowedEmails,
        emails: ['kim@example.com'],
        domains: ['corp.com'],
      );
      await openEdit(tester);

      expect(shownDraft(tester).isPublic, isFalse);
      expect(plain('kim@example.com'), findsOneWidget);
      expect(plain('@corp.com'), findsOneWidget);
    });

    testWidgets('끝이 시작보다 이른 예전 시간별 모임도 열린다', (tester) async {
      meetings.meeting = makeMeeting(
        ownerId: 'user-1',
        startTime: '18:00:00',
        endTime: '06:00:00',
      );
      await openEdit(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('18:00'), findsOneWidget);
      expect(saveEnabled(tester), isFalse);
    });

    testWidgets('규칙에 맞지 않는 예전 모임도 열리고, 제목만 바꾸면 제목만 보낸다', (tester) async {
      meetings.meeting = makeMeeting(
        ownerId: 'user-1',
        endDate: march(10),
        startTime: '06:30:00',
        endTime: '18:30:00',
      );
      visibility.current = visibilityOf(VisibilityLevel.friends);
      await openEdit(tester);

      expect(tester.takeException(), isNull);
      expect(shownDraft(tester).mode, MeetingMode.hourly);
      expect(saveEnabled(tester), isFalse);
      await typeTitle(tester, '예전 회의');
      await save(tester);
      expect(calls, ['update {title: 예전 회의}']);
    });
  });

  group('저장하기', () {
    testWidgets('제목만 바꾸면 제목만 보내고 모임 화면으로 돌아가 새 제목을 보인다', (tester) async {
      await openEdit(tester);
      await typeTitle(tester, '주간 회의');
      await save(tester);

      expect(calls, ['update {title: 주간 회의}']);
      expect(find.byType(MeetingEditPage), findsNothing);
      expect(find.widgetWithText(AppBar, '주간 회의'), findsOneWidget);
      expect(find.text(saved), findsOneWidget);
    });

    testWidgets('시간별을 날짜별로 바꾸면 방식과 하루 전체 시각을 보낸다', (tester) async {
      await openEdit(tester);
      await press(tester, '날짜별');
      await save(tester);

      expect(calls, [
        'update {mode: daily, start_time: 00:00:00, end_time: 00:00:00}',
      ]);
      expect(meetings.meeting!.mode, MeetingMode.daily);
    });

    testWidgets('게스트를 받는 공개 모임을 이메일 비공개로 바꾸면 게스트를 먼저 끄고 공개 범위를 보낸다', (
      tester,
    ) async {
      meetings.meeting = meetings.meeting!.copyWith(allowGuests: true);
      await openEdit(tester);
      await setPublic(tester, false);
      expect(shownDraft(tester).allowGuests, isFalse);
      await addAccess(tester, 'kim@example.com');
      await save(tester);

      expect(calls, [
        'update {allow_guests: false}',
        'visibility allowedEmails',
      ]);
      final body = visibility.updates.single.$3;
      expect(body.allowedEmails, ['kim@example.com']);
      expect(find.text(saved), findsOneWidget);
    });

    testWidgets('비공개를 공개로 바꾸고 게스트를 켜면 공개 범위를 먼저 정하고 게스트를 켠다', (tester) async {
      visibility.current = visibilityOf(
        VisibilityLevel.allowedEmails,
        emails: ['kim@example.com'],
      );
      await openEdit(tester);
      await setPublic(tester, true);
      await setGuests(tester, true);
      await save(tester);

      expect(calls, ['visibility public', 'update {allow_guests: true}']);
      expect(meetings.meeting!.allowGuests, isTrue);
    });

    testWidgets('비공개로 바꾸고 참여할 사람을 정하지 않으면 보내지 않고 그 칸에 알린다', (tester) async {
      await openEdit(tester);
      await setPublic(tester, false);
      await save(tester);

      expect(calls, isEmpty);
      expect(
        plain("이메일을 하나 이상 넣거나 '지금은 나만 볼게요'를 골라야 저장할 수 있어요"),
        findsOneWidget,
      );
      await press(tester, '지금은 나만 볼게요');
      await save(tester);
      expect(calls, ['visibility private']);
    });

    testWidgets('뒤 요청이 실패하면 무엇을 저장했고 못 했는지 알리고, 다시 누르면 남은 것만 보낸다', (
      tester,
    ) async {
      meetings.meeting = meetings.meeting!.copyWith(allowGuests: true);
      visibility.setError = httpError('/v1/visibility', 500);
      await openEdit(tester);
      await setPublic(tester, false);
      await addAccess(tester, 'kim@example.com');
      final reads = meetings.reads.length;
      await save(tester);

      expect(calls, [
        'update {allow_guests: false}',
        'visibility allowedEmails',
      ]);
      expect(
        plain('게스트 로그인은 저장했어요. 공개 범위는 저장하지 못했어요. 잠시 뒤 다시 시도해 주세요'),
        findsOneWidget,
      );
      expect(find.byType(MeetingEditPage), findsOneWidget);
      expect(meetings.reads.length, greaterThan(reads));
      expect(plain('kim@example.com'), findsOneWidget);

      calls.clear();
      visibility.setError = null;
      await save(tester);
      expect(calls, ['visibility allowedEmails']);
      expect(find.byType(MeetingEditPage), findsNothing);
      expect(find.text(saved), findsOneWidget);
    });

    testWidgets('서버가 거절한 칸은 그 아래에 앱의 말로 알린다', (tester) async {
      meetings.updateError = invalidMeeting('mode');
      await openEdit(tester);
      await press(tester, '날짜별');
      await save(tester);

      expect(plain('이 날짜에서는 이 방식으로 바꿀 수 없어요'), findsOneWidget);
      expect(plain('저장하지 못했어요. 표시한 칸을 확인해 주세요'), findsOneWidget);
      expect(find.text('invalid'), findsNothing);

      meetings.updateError = invalidMeeting('title');
      await typeTitle(tester, '이상한 제목');
      await save(tester);
      expect(plain('이 제목으로는 바꿀 수 없어요'), findsOneWidget);
      expect(plain('이 날짜에서는 이 방식으로 바꿀 수 없어요'), findsNothing);
    });

    testWidgets('기간을 다시 고르면 기간과 새 기간에 맞는 제외 날짜를 보낸다', (tester) async {
      meetings.meeting = meetings.meeting!.copyWith(excludedDates: [march(3)]);
      await openEdit(tester);
      for (final day in [2, 4]) {
        final cell = dayCell(march(day));
        await tester.ensureVisible(cell);
        await tester.tap(cell);
        await tester.pumpAndSettle();
      }
      await save(tester);

      expect(calls, [
        'update {start_date: ${march(2).toIso8601String()}, '
            'end_date: ${march(4).toIso8601String()}, '
            'excluded_dates: [${march(3).toIso8601String()}]}',
      ]);
    });

    testWidgets('서버가 기간을 거절하면 달력 아래에 알리고 다시 바꾸면 지운다', (tester) async {
      meetings.updateError = invalidMeeting('end_date');
      await openEdit(tester);
      Future<void> tapDay(int day) async {
        final cell = dayCell(march(day));
        await tester.ensureVisible(cell);
        await tester.tap(cell);
        await tester.pumpAndSettle();
      }

      await tapDay(2);
      await tapDay(4);
      await save(tester);
      const refusal = '이 날짜로는 바꿀 수 없어요. 기간과 제외한 날을 확인해 주세요';
      expect(plain(refusal), findsOneWidget);

      await tapDay(1);
      expect(plain(refusal), findsNothing);
    });

    testWidgets('기간의 시작일만 누르고 저장하면 보내지 않고 끝나는 날을 묻는다', (tester) async {
      await openEdit(tester);
      final cell = dayCell(march(2));
      await tester.ensureVisible(cell);
      await tester.tap(cell);
      await tester.pumpAndSettle();
      await typeTitle(tester, '주간 회의');
      await save(tester);

      expect(calls, isEmpty);
      expect(find.text('끝나는 날을 골라 주세요'), findsOneWidget);
    });

    testWidgets('제목을 비우면 칸에 보이는 제목으로 바꾼다', (tester) async {
      await openEdit(tester);
      await typeTitle(tester, '  ');
      await save(tester);

      expect(calls, ['update {title: 지현님의 모임 일정}']);
    });

    testWidgets('저장하는 동안 다시 눌러도 한 번만 보낸다', (tester) async {
      await openEdit(tester);
      await typeTitle(tester, '주간 회의');
      final button = find.widgetWithText(FilledButton, '저장하기');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.tap(button, warnIfMissed: false);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(calls, ['update {title: 주간 회의}']);
    });

    testWidgets('되돌려 처음 값과 같아지면 다시 저장할 것이 없다', (tester) async {
      await openEdit(tester);
      await press(tester, '날짜별');
      expect(saveEnabled(tester), isTrue);
      await press(tester, '시간별');

      expect(saveEnabled(tester), isFalse);
    });
  });

  group('저장 전 알림', () {
    void withAnswers() => meetings.availability = [
      availabilityOf(
        'p1',
        slots: [(DateTime.utc(2027, 3, 1), DateTime.utc(2027, 3, 1, 1))],
      ),
    ];

    testWidgets('답이 있으면 방식을 바꿀 때와 날을 뺄 때 한 줄씩 알린다', (tester) async {
      withAnswers();
      await openEdit(tester);
      expect(plain(modeNotice), findsNothing);
      expect(plain(daysNotice), findsNothing);

      await press(tester, '날짜별');
      expect(plain(modeNotice), findsOneWidget);

      await press(tester, '제외할 날');
      final third = dayCell(march(3));
      await tester.ensureVisible(third);
      await tester.tap(third);
      await tester.pumpAndSettle();
      expect(plain(daysNotice), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('아무도 답을 넣지 않았으면 알리지 않는다', (tester) async {
      meetings.availability = [availabilityOf('p1')];
      await openEdit(tester);
      await press(tester, '날짜별');

      expect(plain(modeNotice), findsNothing);
    });
  });

  group('모임 삭제', () {
    testWidgets('확인하면 지우고 처음 화면으로 가서 알린다', (tester) async {
      await openEdit(tester);
      await press(tester, '모임 삭제');
      expect(
        find.text('참여자가 넣은 답과 게스트가 모두 지워져요. 지운 모임은 되돌릴 수 없어요.'),
        findsOneWidget,
      );
      await tester.tap(find.text('삭제하기'));
      await tester.pumpAndSettle();

      expect(meetings.deleted, ['meeting-1']);
      expect(find.text('처음 화면'), findsOneWidget);
      expect(find.text('모임을 삭제했어요'), findsOneWidget);
    });

    testWidgets('취소하면 지우지 않는다', (tester) async {
      await openEdit(tester);
      await press(tester, '모임 삭제');
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(meetings.deleted, isEmpty);
      expect(find.byType(MeetingEditPage), findsOneWidget);
    });

    testWidgets('지우지 못하면 알리고 설정 화면에 남는다', (tester) async {
      meetings.deleteError = httpError('/v1/meetings/meeting-1', 500);
      await openEdit(tester);
      await press(tester, '모임 삭제');
      await tester.tap(find.text('삭제하기'));
      await tester.pumpAndSettle();

      expect(find.text('모임을 삭제하지 못했어요. 잠시 뒤 다시 시도해 주세요'), findsOneWidget);
      expect(find.byType(MeetingEditPage), findsOneWidget);
    });
  });

  group('내 모임 목록', () {
    /// 설정 화면에서 내 모임 목록을 듣는다(마이페이지가 떠 있는 것처럼)
    void listenMine(WidgetTester tester) => ProviderScope.containerOf(
      tester.element(find.byType(MeetingEditPage)),
    ).listen(myMeetingsProvider, (_, _) {});

    testWidgets('저장하면 내 모임을 다시 받는다', (tester) async {
      await openEdit(tester);
      listenMine(tester);
      await tester.pumpAndSettle();
      final reads = meetings.listReads;

      await typeTitle(tester, '주간 회의');
      await save(tester);

      expect(meetings.listReads, greaterThan(reads));
    });

    testWidgets('지우면 내 모임을 다시 받는다', (tester) async {
      await openEdit(tester);
      listenMine(tester);
      await tester.pumpAndSettle();
      final reads = meetings.listReads;

      await press(tester, '모임 삭제');
      await tester.tap(find.text('삭제하기'));
      await tester.pumpAndSettle();

      expect(meetings.listReads, greaterThan(reads));
    });
  });

  group('주소로 열 때', () {
    testWidgets('주인이 아니면 찾을 수 없는 모임이고 공개 범위를 읽지 않는다', (tester) async {
      meetings.meeting = makeMeeting(ownerId: 'owner-1');
      await pumpApp(tester, initialLocation: '/meetings/meeting-1/edit');

      expect(find.text('모임을 찾을 수 없습니다'), findsOneWidget);
      expect(find.text('저장하기'), findsNothing);
      expect(visibility.reads, 0);
    });

    testWidgets('없는 모임이면 찾을 수 없는 모임이다', (tester) async {
      meetings.readError = notFound();
      await pumpApp(tester, initialLocation: '/meetings/meeting-1/edit');

      expect(find.text('모임을 찾을 수 없습니다'), findsOneWidget);
    });

    testWidgets('바로 연 주소에서 저장하면 모임 화면으로 간다', (tester) async {
      final router = await pumpApp(
        tester,
        initialLocation: '/meetings/meeting-1/edit',
      );
      await typeTitle(tester, '주간 회의');
      await save(tester);

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/meetings/meeting-1',
      );
      expect(find.widgetWithText(AppBar, '주간 회의'), findsOneWidget);
    });
  });
}
