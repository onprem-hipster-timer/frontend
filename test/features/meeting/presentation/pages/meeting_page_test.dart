import 'dart:async';

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_page.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../../../helpers/fake_rest_clients.dart';
import '../../meeting_fixtures.dart';
import '../../meeting_grid_finders.dart';

/// 서울 2027년 3월 [day]일 [hour]시의 UTC 시각
DateTime seoul(int day, int hour) => DateTime.utc(2027, 3, day, hour - 9);

void main() {
  late FakeMeetingsClient meetings;

  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('ko');
  });

  setUp(() => meetings = FakeMeetingsClient(meeting: makeMeeting()));

  Future<GoRouter> pumpMeeting(
    WidgetTester tester, {
    String initialLocation = '/meetings/meeting-1',
    Size? size,
  }) async {
    if (size != null) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoute.calendar.path,
          name: AppRoute.calendar.name,
          builder: (context, state) => const Text('처음 화면'),
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
          ...meetingOverrides(meetings: meetings),
          schedulesApiProvider.overrideWithValue(FakeSchedulesClient()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('주소의 모임을 불러와 제목, 하루 범위, 시간 기준과 격자를 보인다', (tester) async {
    await pumpMeeting(tester);

    expect(meetings.reads, ['meeting-1']);
    expect(meetings.availabilityReads, 1);
    expect(find.widgetWithText(AppBar, '팀 회의'), findsOneWidget);
    expect(find.text('내 시간 선택하기'), findsOneWidget);
    expect(find.text('6:00 ~ 18:00'), findsOneWidget);
    expect(find.text('한국 시간 기준'), findsOneWidget);
    expect(find.text('3.1'), findsOneWidget);
  });

  testWidgets('터치 기기는 길게 누른 채 끌기를 알린다', (tester) async {
    await pumpMeeting(tester);

    expect(find.text('길게 누른 채 끌면 여러 칸을 칠합니다'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('마우스 기기는 누른 채 끌기를 알린다', (tester) async {
    await pumpMeeting(tester);

    expect(find.text('누른 채 끌면 여러 칸을 칠합니다'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('칸을 누르면 저장 중이다가 참여하고 저장한 뒤 저장됨과 내 이름 칩을 보인다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpMeeting(tester);
    expect(find.text('편집'), findsNothing);

    await tester.tapAt(cellCenter(tester, '3월 1일 (월) 6:00 ~ 6:30'));
    await tester.pump();
    expect(find.text('저장 중'), findsOneWidget);
    expect(cellData('3월 1일 (월) 6:00 ~ 6:30').value, '내 시간');

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(meetings.participations, ['지현']);
    expect(meetings.puts, hasLength(1));
    expect(find.text('저장됨'), findsOneWidget);
    expect(find.bySemanticsLabel('지현, 나'), findsOneWidget);
    expect(find.text('편집'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('저장하지 못하면 칠한 칸을 두고 알리며 다시 시도하면 저장한다', (tester) async {
    final semantics = tester.ensureSemantics();
    meetings.putError = Exception('끊김');
    await pumpMeeting(tester);

    await tester.tapAt(cellCenter(tester, '3월 1일 (월) 6:00 ~ 6:30'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('저장하지 못했습니다'), findsOneWidget);
    expect(cellData('3월 1일 (월) 6:00 ~ 6:30').value, '내 시간');

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(meetings.puts, hasLength(2));
    expect(find.text('저장됨'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('카드의 내 달력에 일정 만들기는 모임 제목과 그 시간으로 새 일정을 연다', (tester) async {
    meetings.availability = [
      availabilityOf('a', name: '민수', slots: [(seoul(1, 9), seoul(1, 10))]),
      availabilityOf('b', name: '서연', slots: [(seoul(1, 9), seoul(1, 10))]),
    ];
    await pumpMeeting(tester);

    final button = find.byTooltip('내 달력에 일정 만들기');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('새 일정'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '팀 회의'), findsOneWidget);
    final start = seoul(1, 9).toLocal();
    final end = seoul(1, 10).toLocal();
    String hm(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    Finder inSheet(String text) => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.textContaining(text),
    );
    expect(inSheet(hm(start)), findsOneWidget);
    expect(inSheet(hm(end)), findsOneWidget);
  });

  testWidgets('편집은 이 모임에서 보일 내 이름을 지금 이름으로 채워 연다', (tester) async {
    meetings.availability = [
      availabilityOf('participant-user-1', name: '지현', userId: 'user-1'),
    ];
    await pumpMeeting(tester);

    await tester.ensureVisible(find.text('편집'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('편집'));
    await tester.pumpAndSettle();

    expect(find.text('내 닉네임'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '지현'), findsOneWidget);
  });

  testWidgets('링크 상자는 모임 링크를 보이고 복사한다', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpMeeting(tester);

    const link = 'https://app.example.com/meetings/meeting-1';
    expect(find.text(link), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('링크 복사'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('링크 복사'));
    await tester.pumpAndSettle();

    expect(copied, [link]);
    expect(find.text('링크를 복사했습니다'), findsOneWidget);
  });

  testWidgets('로그인 상자 자리에 지금 계정으로 진행 중이라고 하고 게스트로 들어가는 길은 없다', (tester) async {
    meetings.meeting = makeMeeting().copyWith(allowGuests: true);
    await pumpMeeting(tester);

    expect(find.text('user@example.com 계정으로 진행 중입니다'), findsOneWidget);
    expect(find.text('Guest'), findsNothing);
    expect(find.text('로그아웃'), findsNothing);
  });

  testWidgets('넓으면 격자 오른쪽에 계정·링크·일정 참여자·선택된 일정을 둔다', (tester) async {
    await pumpMeeting(tester, size: const Size(1280, 800));

    final grid = tester.getTopLeft(find.text('내 시간 선택하기'));
    final account = tester.getTopLeft(find.text('로그인'));
    final link = tester.getTopLeft(find.text('링크'));
    final people = tester.getTopLeft(find.text('일정 참여자'));
    final slots = tester.getTopLeft(find.text('선택된 일정'));
    expect(account.dx, greaterThan(grid.dx + 400));
    expect(link.dx, account.dx);
    expect(people.dx, link.dx);
    final rows = [account.dy, link.dy, people.dy, slots.dy];
    expect(rows, orderedEquals([...rows]..sort()));
  });

  group('좁은 화면', () {
    const narrow = Size(360, 800);

    double fontSize(WidgetTester tester, Finder text) =>
        tester.renderObject<RenderParagraph>(text).text.style!.fontSize!;

    testWidgets('조용한 계정 줄 다음 바로 격자이고, 선택된 일정·일정 참여자·링크 순서다', (tester) async {
      await pumpMeeting(tester, size: narrow);

      final order = [
        for (final title in [
          'user@example.com 계정으로 진행 중입니다',
          '내 시간 선택하기',
          '선택된 일정',
          '일정 참여자',
          '링크',
        ])
          tester.getTopLeft(find.text(title, skipOffstage: false)),
      ];
      for (var i = 1; i < order.length; i++) {
        expect(order[i].dy, greaterThan(order[i - 1].dy));
        expect(order[i].dx, lessThan(40));
      }
      expect(find.text('로그인'), findsNothing, reason: '계정은 상자 제목 없이 한 줄이다');
    });

    testWidgets('계정 줄은 상자가 아닌 작은 글씨다', (tester) async {
      await pumpMeeting(tester, size: narrow);

      final account = find.text('user@example.com 계정으로 진행 중입니다');
      expect(
        find.ancestor(of: account, matching: find.byType(Card)),
        findsNothing,
      );
      expect(
        fontSize(tester, account),
        lessThan(fontSize(tester, find.text('내 시간 선택하기'))),
      );
    });

    testWidgets('격자 → 선택된 일정 → 일정 참여자·링크로 갈수록 제목이 작아지고 끝의 둘은 상자가 아니다', (
      tester,
    ) async {
      await pumpMeeting(tester, size: narrow);

      double size(String title) =>
          fontSize(tester, find.text(title, skipOffstage: false));
      expect(size('내 시간 선택하기'), greaterThanOrEqualTo(size('선택된 일정')));
      expect(size('선택된 일정'), greaterThan(size('일정 참여자')));
      expect(size('일정 참여자'), size('링크'));
      for (final title in ['일정 참여자', '링크']) {
        expect(
          find.ancestor(
            of: find.text(title, skipOffstage: false),
            matching: find.byType(Card),
          ),
          findsNothing,
          reason: title,
        );
      }
      expect(find.text('내 시간 입력하기'), findsNothing, reason: '로그인했으면 바로 칠한다');
    });
  });

  testWidgets('불러오지 못하면 알리고 다시 시도하면 다시 받는다', (tester) async {
    meetings.readError = StateError('없음');
    await pumpMeeting(tester);

    expect(find.text('모임을 불러오지 못했습니다'), findsOneWidget);

    meetings.readError = null;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, '팀 회의'), findsOneWidget);
    expect(meetings.reads, hasLength(2));
  });

  testWidgets('볼 수 없거나 없는 모임(404)은 찾을 수 없다고 하고 다시 시도·로그인은 두지 않는다', (
    tester,
  ) async {
    meetings.readError = notFound();
    await pumpMeeting(tester);

    expect(find.widgetWithText(AppBar, '모임'), findsOneWidget);
    expect(find.text('모임을 찾을 수 없습니다'), findsOneWidget);
    expect(find.text('링크가 맞는지 확인해 주세요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsNothing);
    expect(find.text('로그인'), findsNothing);
    expect(find.textContaining('404'), findsNothing);
    expect(meetings.availabilityReads, 0);
  });

  testWidgets('링크로 바로 열어 돌아갈 곳이 없으면 처음 화면으로 가는 버튼을 둔다', (tester) async {
    await pumpMeeting(tester);

    await tester.tap(find.byTooltip('처음 화면으로'));
    await tester.pumpAndSettle();

    expect(find.text('처음 화면'), findsOneWidget);
  });

  testWidgets('다른 화면에서 열었으면 뒤로 가기를 둔다', (tester) async {
    final router = await pumpMeeting(tester, initialLocation: '/');
    router.pushNamed(
      AppRoute.meeting.name,
      pathParameters: {'meetingId': 'meeting-1'},
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('처음 화면으로'), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('처음 화면'), findsOneWidget);
  });

  group('주인의 참여자 빼기', () {
    const cell = '3월 1일 (월) 9:00 ~ 9:30';

    setUp(() {
      meetings = FakeMeetingsClient(meeting: makeMeeting(ownerId: 'user-1'))
        ..availability = [
          availabilityOf(
            'me',
            name: '지현',
            userId: 'user-1',
            owner: true,
            slots: [(seoul(1, 9), seoul(1, 10))],
          ),
          availabilityOf('a', name: '민수', slots: [(seoul(1, 9), seoul(1, 10))]),
          availabilityOf(
            'g',
            name: '하준',
            guest: true,
            slots: [(seoul(1, 9), seoul(1, 10))],
          ),
        ];
    });

    Future<void> openEdit(WidgetTester tester) async {
      await tester.ensureVisible(find.text('편집'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('편집'));
      await tester.pumpAndSettle();
    }

    Future<void> removeChip(WidgetTester tester, String name) async {
      await tester.ensureVisible(find.byTooltip('$name 빼기'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('$name 빼기'));
      await tester.pumpAndSettle();
    }

    /// 되돌리기 알림이 저절로 닫힐 때까지 넘긴다
    Future<void> letUndoPass(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    }

    testWidgets('편집은 다른 참여자 칩에 빼기를, 내 칩에 이름 바꾸기를 두고 완료로 닫는다', (tester) async {
      await pumpMeeting(tester, size: const Size(1280, 900));
      expect(find.byTooltip('민수 빼기'), findsNothing);

      await openEdit(tester);
      expect(find.byTooltip('민수 빼기'), findsOneWidget);
      expect(find.byTooltip('하준 빼기'), findsOneWidget);
      expect(find.byTooltip('지현 빼기'), findsNothing);
      expect(find.byTooltip('내 닉네임 바꾸기'), findsOneWidget);

      await tester.tap(find.byTooltip('내 닉네임 바꾸기'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, '지현'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.text('완료'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('민수 빼기'), findsNothing);
      expect(find.byTooltip('내 닉네임 바꾸기'), findsNothing);
    });

    testWidgets('참여하지 않은 주인도 편집으로 모든 참여자를 뺄 수 있다', (tester) async {
      meetings.availability.removeAt(0);
      await pumpMeeting(tester, size: const Size(1280, 900));

      await openEdit(tester);

      expect(find.byTooltip('민수 빼기'), findsOneWidget);
      expect(find.byTooltip('하준 빼기'), findsOneWidget);
      expect(find.byTooltip('내 닉네임 바꾸기'), findsNothing);
    });

    testWidgets('빼면 칩·격자·카드에서 바로 빠지고 되돌리기 알림이 저절로 닫힐 때 보낸다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpMeeting(tester, size: const Size(1280, 900));
      expect(cellData(cell).hint, '다른 참여자 2명');
      await openEdit(tester);

      await removeChip(tester, '민수');

      expect(find.text('민수를 뺐습니다'), findsOneWidget);
      expect(find.bySemanticsLabel('민수'), findsNothing);
      expect(cellData(cell).hint, '다른 참여자 1명');
      expect(find.text('2'), findsOneWidget, reason: '카드 인원수');
      expect(meetings.removedParticipants, isEmpty);

      await tester.pump(const Duration(seconds: 3));
      expect(meetings.removedParticipants, isEmpty);
      await letUndoPass(tester);

      expect(meetings.removedParticipants, ['a']);
      expect(find.bySemanticsLabel('민수'), findsNothing);
      expect(find.text('민수를 뺐습니다'), findsNothing);
      semantics.dispose();
    });

    testWidgets('되돌리면 다시 보이고 보내지 않는다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpMeeting(tester, size: const Size(1280, 900));
      await openEdit(tester);
      await removeChip(tester, '민수');

      await tester.tap(find.text('되돌리기'));
      await tester.pumpAndSettle();
      await letUndoPass(tester);

      expect(find.bySemanticsLabel('민수'), findsOneWidget);
      expect(cellData(cell).hint, '다른 참여자 2명');
      expect(meetings.removedParticipants, isEmpty);
      semantics.dispose();
    });

    testWidgets('둘을 잇달아 빼면 앞의 것은 다음 알림이 덮을 때 보내고 뒤의 것은 되돌릴 수 있다', (
      tester,
    ) async {
      await pumpMeeting(tester, size: const Size(1280, 900));
      await openEdit(tester);

      await removeChip(tester, '민수');
      await removeChip(tester, '하준');

      expect(meetings.removedParticipants, ['a']);
      expect(find.text('게스트 하준을 뺐습니다'), findsOneWidget);
      await tester.tap(find.text('되돌리기'));
      await tester.pumpAndSettle();
      await letUndoPass(tester);

      expect(meetings.removedParticipants, ['a']);
      expect(find.bySemanticsLabel('하준, 게스트'), findsOneWidget);
      expect(find.bySemanticsLabel('민수'), findsNothing);
    });

    testWidgets('게스트를 빼면 게스트라고 알리고 그 참여자 id로 보낸다', (tester) async {
      await pumpMeeting(tester, size: const Size(1280, 900));
      await openEdit(tester);

      await removeChip(tester, '하준');
      expect(find.text('게스트 하준을 뺐습니다'), findsOneWidget);
      await letUndoPass(tester);

      expect(meetings.removedParticipants, ['g']);
    });

    testWidgets('보내지 못하면 다시 보이고 알린다', (tester) async {
      meetings.removeError = StateError('끊김');
      await pumpMeeting(tester, size: const Size(1280, 900));
      await openEdit(tester);

      await removeChip(tester, '민수');
      await letUndoPass(tester);

      expect(meetings.removedParticipants, ['a']);
      expect(find.textContaining('민수를 빼지 못했습니다'), findsOneWidget);
      expect(find.byTooltip('민수 빼기'), findsOneWidget);
    });

    testWidgets('알림이 떠 있는 동안 화면을 떠나도 알림이 닫힐 때 보낸다', (tester) async {
      final router = await pumpMeeting(tester, initialLocation: '/');
      unawaited(
        router.pushNamed(
          AppRoute.meeting.name,
          pathParameters: {'meetingId': 'meeting-1'},
        ),
      );
      await tester.pumpAndSettle();
      await openEdit(tester);
      await removeChip(tester, '민수');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('처음 화면'), findsOneWidget);
      expect(meetings.removedParticipants, isEmpty);
      await letUndoPass(tester);

      expect(meetings.removedParticipants, ['a']);
    });

    testWidgets('주인이 아니면 빼기 단추가 없고 편집은 바로 내 닉네임 바꾸기다', (tester) async {
      meetings.meeting = makeMeeting(ownerId: 'someone');
      await pumpMeeting(tester, size: const Size(1280, 900));

      await openEdit(tester);

      expect(find.text('내 닉네임'), findsOneWidget);
      expect(find.byTooltip('민수 빼기'), findsNothing);
    });
  });
}
