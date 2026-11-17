import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/core/providers/shared_preferences_provider.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_create_page.dart';
import 'package:momeet/features/meeting/presentation/providers/pending_meeting_store.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_calendar.dart';
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

/// 낱말 잇기 문자(U+2060)를 빼고 [text]인 글자
Finder plain(String text) => find.byWidgetPredicate(
  (widget) => widget is Text && widget.data?.replaceAll('⁠', '') == text,
);

/// 낱말 잇기 문자를 빼고 [part]가 든 글자
Finder plainContaining(String part) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data?.replaceAll('⁠', '').contains(part) ?? false),
);

const rangeQuestion = '언제 모일까요?';
const exclusionQuestion = '이 범위에서 제외하고 싶은 날짜가 있나요?';
const modeQuestion = '어떻게 받을까요?';
const hoursQuestion = '6시부터 18시까지로 할까요?';
const visibilityQuestion = '어떻게 할까요?';
const guestQuestion = '게스트를 허용할까요?';
const titleQuestion = '마지막으로 제목을 지어 주세요';

const questions = [
  exclusionQuestion,
  modeQuestion,
  hoursQuestion,
  visibilityQuestion,
  guestQuestion,
  titleQuestion,
];

/// 지금 질문이 [shown]이다: 다른 질문은 없다. 날짜를 묻는 동안(기간·제외)은 '언제 모일까요?'가 함께 있다
void expectOnly(String shown) {
  for (final question in questions) {
    expect(
      plain(question),
      question == shown ? findsOneWidget : findsNothing,
      reason: question,
    );
  }
  final datesAsked = shown == rangeQuestion || shown == exclusionQuestion;
  expect(plain(rangeQuestion), datesAsked ? findsOneWidget : findsNothing);
}

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
    Size size = const Size(480, 1800),
  }) async {
    tester.view.physicalSize = size;
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

  Future<void> tapDay(WidgetTester tester, int day) async {
    final cell = dayCell(nextMonth(day));
    await tester.ensureVisible(cell);
    await tester.pumpAndSettle();
    await tester.tap(cell);
    await tester.pumpAndSettle();
  }

  /// 다음 달 [from]일과 [to]일을 차례로 눌러 기간을 고른다
  Future<void> pickRange(WidgetTester tester, int from, int to) async {
    await tapDay(tester, from);
    await tapDay(tester, to);
  }

  /// [label] 단추(같은 글자가 여럿이면 마지막)를 누른다
  Future<void> press(WidgetTester tester, String label) async {
    final target = find.text(label).last;
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  /// 다음 달 [from]~[to]일을 제외 없이, [mode] 방식(시간별이면 6~18시), [public], [guests]로 답해 제목까지 간다
  Future<void> answerAll(
    WidgetTester tester, {
    int from = 3,
    int to = 5,
    String mode = '시간별',
    bool public = true,
    bool guests = true,
  }) async {
    await pickRange(tester, from, to);
    if (from != to) await press(tester, '없어요');
    await press(tester, mode);
    if (mode == '시간별') await press(tester, '예');
    await press(tester, public ? '공개' : '비공개');
    if (public) await press(tester, guests ? '허용' : '허용 안 함');
  }

  /// 전체 설정을 펼친다. [nextMonthShown]이면 펼친 폼의 달력도 다음 달로 넘긴다
  Future<void> expand(
    WidgetTester tester, {
    bool nextMonthShown = false,
  }) async {
    await press(tester, '전체 설정 펼치기');
    if (!nextMonthShown) return;
    await tester.tap(find.byTooltip('다음 달'));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    final arrow = find.byTooltip('모임 만들기');
    await tester.ensureVisible(arrow);
    await tester.pumpAndSettle();
    await tester.tap(arrow);
    await tester.pumpAndSettle();
  }

  String location() => router.routerDelegate.currentConfiguration.uri.path;

  const loginReason = '모임을 만들고 나중에 고치려면 로그인이 필요해요';

  group('하나씩 묻기', () {
    testWidgets('처음에는 언제 모일까요?만 묻고 다른 질문과 제목 칸은 없다', (tester) async {
      await pumpPage(tester);

      expectOnly(rangeQuestion);
      expect(plain('시작하는 날과 끝나는 날을 눌러 주세요'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('전체 설정 펼치기'), findsOneWidget);
    });

    testWidgets('시작하는 날만 누르면 다음 질문이 없고, 끝나는 날을 누르면 제외만 묻는다', (tester) async {
      await pumpPage(tester);

      await tapDay(tester, 3);
      expectOnly(rangeQuestion);
      expect(plainContaining('부터예요. 끝나는 날을 눌러 주세요'), findsOneWidget);
      expect(
        tester.getSemantics(dayCell(nextMonth(3))),
        isSemantics(isSelected: true),
      );

      await tapDay(tester, 5);
      expect(plain(exclusionQuestion), findsOneWidget);
      for (final question in questions.skip(1)) {
        expect(plain(question), findsNothing, reason: question);
      }
      for (final day in [3, 4, 5]) {
        expect(
          tester.getSemantics(dayCell(nextMonth(day))),
          isSemantics(isSelected: true),
        );
      }
      expect(plainContaining('· 3일'), findsOneWidget, reason: '고른 기간');
    });

    testWidgets('답할 때마다 다음 질문 하나만 나오고 답한 것은 한 줄 요약으로 남는다', (tester) async {
      await pumpPage(tester);
      await pickRange(tester, 3, 5);

      await press(tester, '없어요');
      expectOnly(modeQuestion);
      expect(find.text('제외 없음'), findsOneWidget);
      expect(find.byType(MeetingCalendar), findsNothing, reason: '날짜를 다 물었다');

      await press(tester, '시간별');
      expectOnly(hoursQuestion);
      expect(find.text('시간별'), findsOneWidget, reason: '요약');

      await press(tester, '예');
      expectOnly(visibilityQuestion);
      expect(plainContaining('로그인하지 않고'), findsOneWidget);
      expect(find.text('6:00–18:00'), findsOneWidget);

      await press(tester, '공개');
      expectOnly(guestQuestion);
      expect(plainContaining('안전하지 않아요'), findsOneWidget);

      await press(tester, '허용');
      expectOnly(titleQuestion);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('공개'), findsOneWidget);
      expect(find.text('게스트 허용'), findsOneWidget);
    });

    testWidgets('미리 고른 답이 없다: 방식·공개·게스트 단추가 모두 같은 모양이다', (tester) async {
      await pumpPage(tester);
      await pickRange(tester, 3, 5);
      await press(tester, '없어요');
      for (final mode in ['시간별', '날짜별', '요일별']) {
        expect(
          tester.getSemantics(find.text(mode)),
          isNot(isSemantics(isSelected: true)),
          reason: mode,
        );
      }
      await press(tester, '날짜별');

      for (final label in ['공개', '비공개']) {
        expect(
          tester.getSemantics(find.text(label)),
          isNot(isSemantics(isSelected: true)),
          reason: label,
        );
      }
    });

    testWidgets('하루만 고르면 제외를 묻지 않고 방식을 묻는다', (tester) async {
      await pumpPage(tester);
      await pickRange(tester, 3, 3);

      expectOnly(modeQuestion);
      expect(find.text('제외 없음'), findsNothing);
    });

    testWidgets('날짜별은 시간을, 비공개는 게스트를 묻지 않고 제목으로 간다', (tester) async {
      await pumpPage(tester);
      await pickRange(tester, 3, 5);
      await press(tester, '없어요');
      await press(tester, '날짜별');
      expectOnly(visibilityQuestion);

      await press(tester, '비공개');
      expectOnly(titleQuestion);
      await submit(tester);

      expect(meetings.created.single.mode, MeetingMode.daily);
      expect(calls, ['create']);
    });
  });

  group('제외', () {
    testWidgets('기간 안의 날을 누르면 빼고 목록에 적으며, 첫날·마지막 날은 뺄 수 없다고 알린다', (
      tester,
    ) async {
      await pumpPage(tester);
      await pickRange(tester, 3, 6);

      await tapDay(tester, 4);
      expect(
        tester.getSemantics(dayCell(nextMonth(4))),
        isSemantics(hint: '뺀 날', isSelected: false),
      );
      expect(plainContaining('제외: ${nextMonth(4).month}.4('), findsOneWidget);
      expect(find.text('다 골랐어요'), findsOneWidget);
      expect(find.text('없어요'), findsNothing);

      await tapDay(tester, 3);
      expect(find.text('첫날과 마지막 날은 뺄 수 없어요'), findsOneWidget);
      expect(
        tester.getSemantics(dayCell(nextMonth(3))),
        isSemantics(isSelected: true),
      );

      await tapDay(tester, 4);
      expect(find.text('없어요'), findsOneWidget, reason: '다시 누르면 되돌린다');
      await tapDay(tester, 5);
      await press(tester, '다 골랐어요');
      expect(find.text('1일 제외'), findsOneWidget);

      await press(tester, '날짜별');
      await press(tester, '비공개');
      await submit(tester);
      final body = meetings.created.single;
      expect(body.startDate, nextMonth(3));
      expect(body.endDate, nextMonth(6));
      expect(body.excludedDates, [nextMonth(5)]);
    });

    testWidgets('주말 제외는 첫날·마지막 날이 아닌 주말을 모두 빼고, 다 골랐어요로 답한다', (tester) async {
      await pumpPage(tester);
      await pickRange(tester, 1, 10);
      final weekends = [
        for (var day = 2; day <= 9; day++)
          if (nextMonth(day).weekday >= DateTime.saturday) nextMonth(day),
      ];

      await press(tester, '주말 제외');
      expect(find.text('주말 제외'), findsNothing, reason: '뺄 주말이 없다');
      await press(tester, '다 골랐어요');
      await press(tester, '날짜별');
      await press(tester, '비공개');
      await submit(tester);

      expect(meetings.created.single.excludedDates, weekends);
    });

    testWidgets('기간 다시 고르기는 기간을 다시 묻고, 고르면 제외를 다시 묻는다', (tester) async {
      await pumpPage(tester);
      await pickRange(tester, 3, 6);

      await press(tester, '기간 다시 고르기');
      expectOnly(rangeQuestion);
      await pickRange(tester, 10, 12);

      expectOnly(exclusionQuestion);
      expect(plainContaining('· 3일'), findsOneWidget);
    });
  });

  group('받는 방식', () {
    testWidgets('시간별로 받을 수 없는 날짜면 시간별을 흐리게 두고 까닭을 적으며, 눌러도 방식을 묻는다', (
      tester,
    ) async {
      await pumpPage(tester);
      await pickRange(tester, 1, 6);
      await press(tester, '없어요');

      expect(plainContaining('5일 이하이고 기간이 7일 안일 때만'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('시간별')),
        isSemantics(isEnabled: false),
      );
      await press(tester, '시간별');
      expectOnly(modeQuestion);
    });

    testWidgets('가운데 날을 빼 5일이 되면 시간별을 고를 수 있다', (tester) async {
      await pumpPage(tester);
      await pickRange(tester, 1, 7);
      await tapDay(tester, 3);
      await tapDay(tester, 4);
      await press(tester, '다 골랐어요');

      await press(tester, '시간별');
      expectOnly(hoursQuestion);
    });

    testWidgets('요일별은 시작일부터 7일로 맞추고 제외를 되돌리며 무엇을 맞췄는지 알린다', (tester) async {
      await pumpPage(tester);
      await pickRange(tester, 10, 12);
      await tapDay(tester, 11);
      await press(tester, '다 골랐어요');

      await press(tester, '요일별');

      expect(plainContaining('요일별은 7일로 받아서 기간을'), findsOneWidget);
      expect(plain('요일별이라 제외한 날짜를 되돌렸어요'), findsOneWidget);
      expect(find.text('1일 제외'), findsNothing);
      expectOnly(visibilityQuestion);
      await press(tester, '비공개');
      expect(plainContaining('요일별은 7일로'), findsNothing, reason: '다음 답에서 지운다');
      await submit(tester);

      final body = meetings.created.single;
      expect(body.mode, MeetingMode.weekly);
      expect(body.startDate, nextMonth(10));
      expect(body.endDate, nextMonth(16));
      expect(body.excludedDates, isEmpty);
      expect(body.startTime, '00:00:00');
      expect(body.endTime, '00:00:00');
    });
  });

  testWidgets('아니요를 누르면 시각을 골라 그 시간으로 만든다', (tester) async {
    await pumpPage(tester);
    await pickRange(tester, 3, 5);
    await press(tester, '없어요');
    await press(tester, '시간별');

    await press(tester, '아니요');
    expect(plain('몇 시부터 몇 시까지로 할까요?'), findsOneWidget);
    await tester.tap(find.text('6:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('9:00').last);
    await tester.pumpAndSettle();
    expectOnly('');
    await press(tester, '이 시간으로 할게요');
    expect(find.text('9:00–18:00'), findsOneWidget);
    await press(tester, '비공개');
    await submit(tester);

    final body = meetings.created.single;
    expect(body.mode, MeetingMode.hourly);
    expect(body.startTime, '09:00:00');
    expect(body.endTime, '18:00:00');
  });

  group('앞 답 바꾸기', () {
    testWidgets('요약을 눌러 비공개로 바꾸면 게스트 답을 지우고 알리며, 그대로 둘게요는 바꾸지 않는다', (
      tester,
    ) async {
      await pumpPage(tester);
      await answerAll(tester);

      await press(tester, '공개');
      expectOnly(visibilityQuestion);
      expect(
        tester.getSemantics(find.text('공개').last),
        isSemantics(isSelected: true),
        reason: '지금 답',
      );
      await press(tester, '그대로 둘게요');
      expectOnly(titleQuestion);
      expect(find.text('게스트 허용'), findsOneWidget);

      await press(tester, '공개');
      await press(tester, '비공개');
      expectOnly(titleQuestion);
      expect(find.text('게스트 허용'), findsNothing);
      expect(plain('비공개라 게스트는 받지 않아요'), findsOneWidget);
      await submit(tester);
      expect(calls, ['create']);
    });

    testWidgets('기간을 줄이면 새 기간 밖의 제외 날짜를 빼고 알린다', (tester) async {
      await pumpPage(tester);
      await pickRange(tester, 3, 7);
      await tapDay(tester, 4);
      await tapDay(tester, 6);
      await press(tester, '다 골랐어요');
      await press(tester, '날짜별');
      await press(tester, '비공개');

      await press(tester, '2일 제외');
      expectOnly(exclusionQuestion);
      await press(tester, '기간 다시 고르기');
      await pickRange(tester, 3, 5);

      expect(plain('새 기간에 들지 않는 제외 날짜는 뺐어요'), findsOneWidget);
      expectOnly(titleQuestion);
      expect(find.text('1일 제외'), findsOneWidget);
    });

    testWidgets('기간을 시간별로 받을 수 없게 바꾸면 날짜별로 바꾸고 알린다', (tester) async {
      await pumpPage(tester);
      await answerAll(tester);

      final range = find.textContaining('(').first;
      await tester.tap(range);
      await tester.pumpAndSettle();
      expectOnly(rangeQuestion);
      await pickRange(tester, 3, 12);

      expect(plain('이 날짜는 시간별로 받을 수 없어 날짜별로 바꿨어요'), findsOneWidget);
      expect(find.text('날짜별'), findsOneWidget);
      expect(find.text('6:00–18:00'), findsNothing);
      expect(plain(exclusionQuestion), findsNothing, reason: '제외는 이미 답했다');
    });
  });

  group('달력의 자리', () {
    testWidgets('좁은 화면에서 끝나는 날을 눌러 제외를 물어도 달력이 그 자리에 있다', (tester) async {
      await pumpPage(tester, size: const Size(360, 1600));
      await tapDay(tester, 3);
      final before = tester.getTopLeft(find.byType(MeetingCalendar));

      await tester.tap(dayCell(nextMonth(5)));
      await tester.pump();
      expect(tester.getTopLeft(find.byType(MeetingCalendar)), before);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(MeetingCalendar)), before);
    });

    testWidgets('넓은 화면 첫 질문은 왼쪽에 질문, 오른쪽에 달력을 나란히 두고 다른 칸이 없다', (tester) async {
      await pumpPage(tester, size: const Size(1280, 900));

      final prompt = tester.getRect(plain(rangeQuestion));
      final calendar = tester.getRect(find.byType(MeetingCalendar));
      expect(prompt.right, lessThan(calendar.left));
      expect((prompt.top - calendar.top).abs(), lessThan(40));
      expect(find.byType(MeetingModeSelector), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('넓은 화면에서 끝나는 날을 눌러 제외를 물어도 달력이 그 자리에 있다', (tester) async {
      await pumpPage(tester, size: const Size(1280, 900));
      await tapDay(tester, 3);
      final before = tester.getTopLeft(find.byType(MeetingCalendar));

      await tester.tap(dayCell(nextMonth(5)));
      await tester.pump();
      expect(tester.getTopLeft(find.byType(MeetingCalendar)), before);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(MeetingCalendar)), before);
      expect(
        tester.getRect(plain(exclusionQuestion)).right,
        lessThan(before.dx),
        reason: '질문은 달력 왼쪽',
      );
    });

    testWidgets('넓은 화면에서 날짜를 다 물으면 달력 없이 한 칸이다', (tester) async {
      await pumpPage(tester, size: const Size(1280, 900));
      await pickRange(tester, 3, 5);
      await press(tester, '없어요');

      expect(find.byType(MeetingCalendar), findsNothing);
      final question = tester.getRect(plain(modeQuestion));
      final tile = tester.getRect(
        find.ancestor(of: find.text('날짜별'), matching: find.byType(InkWell)),
      );
      expect(tile.width, greaterThan(400), reason: '질문 칸이 화면 가운데를 채운다');
      expect((question.left - tile.left).abs(), lessThan(1));
    });
  });

  testWidgets('애니메이션을 줄였으면 다음 질문이 기다리지 않고 바로 다 보인다', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpPage(tester);
    await tapDay(tester, 3);

    await tester.tap(dayCell(nextMonth(5)));
    await tester.pump();
    await tester.pump();

    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: plain(exclusionQuestion),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, 1);
  });

  testWidgets('새 질문은 펼쳐지며 나타난다', (tester) async {
    await pumpPage(tester);
    await tapDay(tester, 3);

    await tester.tap(dayCell(nextMonth(5)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    FadeTransition fade() => tester.widget<FadeTransition>(
      find
          .ancestor(
            of: plain(exclusionQuestion),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade().opacity.value, 0, reason: '요약이 바뀐 것을 먼저 본다');
    await tester.pumpAndSettle();
    expect(fade().opacity.value, 1);
  });

  group('전체 설정 펼치기', () {
    testWidgets('답하지 않은 설정을 기본값(시간별 6~18시, 공개, 게스트 허용)으로 채운 폼을 보이고 화살표로 만든다', (
      tester,
    ) async {
      await pumpPage(tester);
      await pickRange(tester, 3, 5);

      await expand(tester);

      expect(find.text('전체 설정 펼치기'), findsNothing);
      expect(find.byType(MeetingModeSelector), findsOneWidget);
      expect(
        tester.getSemantics(find.text('시간별')),
        isSemantics(isSelected: true),
      );
      expect(find.text('6:00'), findsOneWidget);
      expect(find.text('18:00'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('허용').first),
        isSemantics(isChecked: true),
      );
      expect(
        tester.getSemantics(find.text('허용').last),
        isSemantics(isChecked: true),
      );

      await submit(tester);

      final body = meetings.created.single;
      expect(body.title, '지현님의 모임 일정');
      expect(body.startDate, nextMonth(3));
      expect(body.endDate, nextMonth(5));
      expect(body.mode, MeetingMode.hourly);
      expect(body.startTime, '06:00:00');
      expect(body.endTime, '18:00:00');
      expect(calls, [
        'create',
        'visibility public',
        'update {allow_guests: true}',
      ]);
      expect(location(), '/meetings/meeting-new-1/created');
    });

    testWidgets('기간은 꼭 고른다: 날짜가 없거나 시작일만 눌렀으면 만들지 않고 알린다', (tester) async {
      await pumpPage(tester);
      await expand(tester, nextMonthShown: true);

      await submit(tester);
      expect(find.text('모임 날짜를 골라 주세요'), findsOneWidget);

      await tapDay(tester, 3);
      await submit(tester);
      expect(find.text('끝나는 날을 골라 주세요'), findsOneWidget);
      expect(meetings.created, isEmpty);
    });

    testWidgets('제외할 날로 바꾸면 달력에서 날을 빼고, 기간이 길어지면 시간별을 날짜별로 바꾼다', (
      tester,
    ) async {
      await pumpPage(tester);
      await expand(tester, nextMonthShown: true);
      await pickRange(tester, 3, 9);
      expect(
        tester.getSemantics(find.text('날짜별')),
        isSemantics(isSelected: true),
      );

      await press(tester, '제외할 날');
      await tapDay(tester, 5);
      await submit(tester);

      final body = meetings.created.single;
      expect(body.mode, MeetingMode.daily);
      expect(body.excludedDates, [nextMonth(5)]);
    });

    testWidgets('질문에 답한 값은 그대로 펼친다', (tester) async {
      await pumpPage(tester);
      await answerAll(tester, mode: '날짜별', public: false);

      await expand(tester);

      expect(
        tester.getSemantics(find.text('날짜별')),
        isSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(find.text('비허용').first),
        isSemantics(isChecked: true),
      );
    });
  });

  group('만들기', () {
    testWidgets('제목을 비우면 이름이 든 자리 글자로 만들고, 공개로 열고 게스트를 켠 뒤 만든 뒤 화면으로 간다', (
      tester,
    ) async {
      await pumpPage(tester);
      await answerAll(tester);

      await submit(tester);

      final body = meetings.created.single;
      expect(body.title, '지현님의 모임 일정');
      expect(body.timezone, 'Asia/Seoul');
      expect(body.startDate, nextMonth(3));
      expect(body.endDate, nextMonth(5));
      expect(body.excludedDates, isEmpty);
      expect(body.mode, MeetingMode.hourly);
      final (type, id, update) = visibility.updates.single;
      expect(type, ResourceType.meeting);
      expect(id, 'meeting-new-1');
      expect(update.level, VisibilityLevel.public);
      expect(calls, [
        'create',
        'visibility public',
        'update {allow_guests: true}',
      ]);
      expect(location(), '/meetings/meeting-new-1/created');
    });

    testWidgets('게스트만 허용 안 하면 공개로 열고 게스트는 켜지 않는다', (tester) async {
      await pumpPage(tester);
      await answerAll(tester, guests: false);

      await submit(tester);

      expect(calls, ['create', 'visibility public']);
    });

    testWidgets('이름이 없으면 모임 일정을, 제목을 쓰면 그 제목을 앞뒤 공백 없이 보낸다', (tester) async {
      await pumpPage(tester, name: null);
      await answerAll(tester);
      expect(find.text('모임 일정'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '  주간 회의 ');
      await submit(tester);

      expect(meetings.created.single.title, '주간 회의');
    });

    testWidgets('만들지 못하면 알리고 화면과 답을 그대로 둔다', (tester) async {
      meetings.createError = StateError('서버 오류');
      await pumpPage(tester);
      await answerAll(tester);

      await submit(tester);

      expect(find.textContaining('모임을 만들지 못했습니다'), findsOneWidget);
      expect(calls, ['create']);
      expect(location(), AppRoute.meetings.path);
      expectOnly(titleQuestion);
    });

    testWidgets('공개로 열지 못하면 만든 모임을 지우고 알리며, 다시 누르면 새로 만든다', (tester) async {
      visibility.setError = StateError('공개 실패');
      await pumpPage(tester);
      await answerAll(tester);

      await submit(tester);

      expect(calls, ['create', 'visibility public', 'delete meeting-new-1']);
      expect(find.textContaining('모임을 만들지 못했습니다'), findsOneWidget);

      visibility.setError = null;
      await submit(tester);
      expect(meetings.created, hasLength(2));
      expect(location(), '/meetings/meeting-new-2/created');
    });

    testWidgets('게스트 로그인을 켜지 못하면 만든 모임을 지우고 알린다', (tester) async {
      meetings.updateError = StateError('게스트 실패');
      await pumpPage(tester);
      await answerAll(tester);

      await submit(tester);

      expect(calls, [
        'create',
        'visibility public',
        'update {allow_guests: true}',
        'delete meeting-new-1',
      ]);
      expect(find.textContaining('게스트 실패'), findsOneWidget);
      expect(location(), AppRoute.meetings.path);
    });

    testWidgets('만든 모임을 지우지도 못하면 처음 실패를 알린다', (tester) async {
      meetings
        ..updateError = StateError('게스트 실패')
        ..deleteError = StateError('지우기 실패');
      await pumpPage(tester);
      await answerAll(tester);

      await submit(tester);

      expect(meetings.deleted, ['meeting-new-1']);
      expect(find.textContaining('게스트 실패'), findsOneWidget);
      expect(find.textContaining('지우기 실패'), findsNothing);
    });

    testWidgets('만드는 중에는 화살표를 막고 완료 키를 다시 눌러도 한 번만 보낸다', (tester) async {
      final gate = Completer<void>();
      meetings.createGate = gate.future;
      await pumpPage(tester);
      await answerAll(tester);

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
  });

  group('로그인하지 않았으면', () {
    testWidgets('모두 답하는 동안 로그인 말이 없고, 화살표를 누르면 만들지 않고 그때 로그인을 묻는 시트를 연다', (
      tester,
    ) async {
      await pumpPage(tester, signedIn: false);
      await answerAll(tester);
      await tester.enterText(find.byType(TextField), '스터디');
      expect(find.text(loginReason), findsNothing);

      await submit(tester);

      expect(meetings.created, isEmpty);
      expect(calls, isEmpty);
      final sheet = find.byType(BottomSheet);
      expect(sheet, findsOneWidget);
      for (final text in [loginReason, '입력한 내용은 그대로 남아요']) {
        expect(
          find.descendant(of: sheet, matching: find.text(text)),
          findsOneWidget,
        );
      }
    });

    testWidgets('닫기로 시트를 닫으면 답한 그대로의 화면으로 돌아온다', (tester) async {
      await pumpPage(tester, signedIn: false);
      await answerAll(tester);
      await tester.enterText(find.byType(TextField), '스터디');
      await submit(tester);

      await tester.tap(find.widgetWithText(TextButton, '닫기'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('스터디'), findsOneWidget);
      expectOnly(titleQuestion);
      expect(prefs.getString(PendingMeetingStore.key), isNull);
    });

    testWidgets('넓은 화면에서는 같은 내용을 대화상자로 묻는다', (tester) async {
      await pumpPage(tester, signedIn: false, size: const Size(1280, 900));
      await answerAll(tester);

      await submit(tester);

      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text(loginReason)),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, '로그인하고 계속하기'));
      await tester.pumpAndSettle();
      expect(location(), AppRoute.login.path);
    });

    testWidgets('로그인하고 돌아오면 답한 것을 요약하고 제목부터 이어, 화살표 한 번으로 만든다', (tester) async {
      await pumpPage(tester, signedIn: false);
      await pickRange(tester, 3, 6);
      await tapDay(tester, 4);
      await press(tester, '다 골랐어요');
      await press(tester, '시간별');
      await press(tester, '예');
      await press(tester, '공개');
      await press(tester, '허용 안 함');
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

      expectOnly(titleQuestion);
      expect(find.text('스터디'), findsOneWidget);
      expect(find.text('1일 제외'), findsOneWidget);
      expect(find.text('6:00–18:00'), findsOneWidget);
      expect(find.text('게스트 안 받음'), findsOneWidget);
      await submit(tester);

      final body = meetings.created.single;
      expect(body.title, '스터디');
      expect(body.startDate, nextMonth(3));
      expect(body.endDate, nextMonth(6));
      expect(body.excludedDates, [nextMonth(4)]);
      expect(calls, ['create', 'visibility public']);
    });

    testWidgets('펼친 폼에서 로그인하러 갔으면 펼친 폼으로 돌아온다', (tester) async {
      await pumpPage(tester, signedIn: false);
      await expand(tester, nextMonthShown: true);
      await pickRange(tester, 3, 4);
      await submit(tester);
      await tester.tap(find.widgetWithText(FilledButton, '로그인하고 계속하기'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await pumpPage(tester, nextMonthShown: false);

      expect(find.byType(MeetingModeSelector), findsOneWidget);
      expect(find.text('전체 설정 펼치기'), findsNothing);
      expect(
        tester.getSemantics(dayCell(nextMonth(4))),
        isSemantics(isSelected: true),
      );
    });

    testWidgets('둔 값은 한 번만 꺼낸다', (tester) async {
      await pumpPage(tester, signedIn: false);
      await answerAll(tester);
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
      expectOnly(rangeQuestion);
    });
  });

  testWidgets('둔 폼의 답한 질문을 모르면 펼친 폼으로 연다', (tester) async {
    await PendingMeetingStore(prefs).save((
      flow: MeetingFlow(
        draft: const MeetingDraft().withDates(
          MeetingDates.range(nextMonth(3), nextMonth(4)),
        ),
        expanded: true,
      ),
      title: '',
    ));
    await pumpPage(tester, nextMonthShown: false);

    expect(find.byType(MeetingModeSelector), findsOneWidget);
  });
}
