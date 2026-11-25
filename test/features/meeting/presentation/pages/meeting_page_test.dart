import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_section.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_finish_slot.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slots_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slot_card.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_page.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/ui/ui.dart';
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

  /// 도움말(물음표)에 [text]가 있는지
  Finder helpWith(String text) => find.byWidgetPredicate(
    (widget) => widget is Tooltip && (widget.message ?? '').contains(text),
  );

  testWidgets('터치 기기는 도움말에서 길게 누른 채 끌기를 알린다', (tester) async {
    await pumpMeeting(tester);

    expect(helpWith('길게 누른 채 끌면 여러 칸을 한 번에 칠해요'), findsOneWidget);
    expect(find.text('길게 누른 채 끌면 여러 칸을 칠합니다'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('마우스 기기는 도움말에서 누른 채 끌기를 알린다', (tester) async {
    await pumpMeeting(tester);

    expect(helpWith('누른 채 끌어서 여러 칸을 칠해요'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  /// '저장하기' 자리 안의 [finder]
  Finder inFinish(Finder finder) =>
      find.descendant(of: find.byType(MeetingFinishSlot), matching: finder);

  /// '내 시간 선택하기' 안의 [finder]
  Finder inSection(Finder finder) => find.descendant(
    of: find.byType(MeetingAvailabilitySection),
    matching: finder,
  );

  /// [label] 단추를 누를 수 있는지
  bool enabled(WidgetTester tester, String label) => tester
      .widget<FilledButton>(find.widgetWithText(FilledButton, label))
      .enabled;

  testWidgets('칸을 누르면 저장하기 자리에 자동 저장 중이다가, 참여하고 저장한 뒤 자동 저장됐어요와 내 이름 칩을 보인다', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpMeeting(tester);
    expect(find.text('편집'), findsNothing);

    await tester.tapAt(cellCenter(tester, '3월 1일 (월) 6:00 ~ 6:30'));
    await tester.pump();
    expect(inFinish(find.text('자동 저장 중')), findsOneWidget);
    expect(inFinish(find.byIcon(Icons.sync)), findsOneWidget);
    expect(enabled(tester, '저장하기'), isTrue);
    expect(cellData('3월 1일 (월) 6:00 ~ 6:30').value, '가능');

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(meetings.participations, ['지현']);
    expect(meetings.puts, hasLength(1));
    final saved = inFinish(find.text('자동 저장됐어요'));
    expect(saved, findsOneWidget);
    expect(
      tester.getSemantics(saved),
      isSemantics(label: '자동 저장됐어요', isLiveRegion: true),
    );
    final check = inFinish(find.byIcon(Icons.check_circle_outline));
    expect(
      tester.widget<Icon>(check).color,
      AppColors.of(tester.element(check)).success,
    );
    expect(enabled(tester, '그래도 저장하기'), isTrue);
    expect(find.text('자동 저장 중'), findsNothing);
    expect(find.text('입력을 마쳤어요'), findsNothing, reason: '마쳤다는 말은 누를 때만 한다');
    for (final old in ['저장 중', '저장됨']) {
      expect(inSection(find.text(old)), findsNothing);
    }
    expect(find.bySemanticsLabel('지현, 나'), findsOneWidget);
    expect(find.text('편집'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('누르지 않아도 저장하지 못하면 칠한 칸을 두고 저장하기 자리에 알리며, 다시 저장하기로 다시 보내 마친다', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    meetings.putError = Exception('끊김');
    await pumpMeeting(tester);

    await tester.tapAt(cellCenter(tester, '3월 1일 (월) 6:00 ~ 6:30'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(meetings.puts, hasLength(1));
    final error = inFinish(find.text('저장하지 못했어요'));
    expect(error, findsOneWidget);
    expect(
      tester.widget<Text>(error).style?.color,
      Theme.of(tester.element(error)).colorScheme.error,
    );
    expect(
      tester.getSemantics(error),
      isSemantics(label: '저장하지 못했어요', isLiveRegion: true),
    );
    expect(enabled(tester, '다시 저장하기'), isTrue);
    expect(find.text('입력을 마쳤어요'), findsNothing);
    expect(cellData('3월 1일 (월) 6:00 ~ 6:30').value, '가능');
    for (final old in ['저장하지 못했습니다', '다시 시도']) {
      expect(inSection(find.text(old)), findsNothing);
    }

    await tester.tap(find.widgetWithText(FilledButton, '다시 저장하기'));
    await tester.pumpAndSettle();
    expect(meetings.puts, hasLength(2));
    expect(find.text('저장하지 못했어요'), findsNothing);
    expect(find.text('입력을 마쳤어요'), findsOneWidget);
    expect(
      tester.takeAnnouncements().map((a) => a.message),
      contains('입력을 마쳤어요. 언제든 다시 고칠 수 있어요'),
    );
    semantics.dispose();
  });

  group('저장하기', () {
    const cell = '3월 1일 (월) 6:00 ~ 6:30';
    Finder finish() => find.widgetWithText(FilledButton, '저장하기');

    /// '추천 시간' 제목이 화면(아래 붙은 단추 위) 안에 있는지
    void expectSlotsInView(WidgetTester tester, {required double bottom}) {
      final title = tester.getRect(find.text('추천 시간'));
      expect(title.top, greaterThanOrEqualTo(0));
      expect(title.bottom, lessThanOrEqualTo(bottom));
    }

    testWidgets('바꾸기 전에는 없고, 칸을 칠하면 좁은 화면 아래에 붙어 마지막 칸을 가리지 않는다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpMeeting(tester, size: const Size(400, 800));
      expect(finish(), findsNothing);

      await tester.tapAt(cellCenter(tester, cell));
      await tester.pump();
      expect(finish(), findsOneWidget);
      final bar = tester.getRect(finish());
      expect(bar.bottom, greaterThan(800 - 80));
      expect(
        tester.getRect(find.text('자동 저장 중')).bottom,
        lessThanOrEqualTo(bar.top),
        reason: '좁으면 상태는 단추 위에 둔다',
      );

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -5000));
      await tester.pumpAndSettle();
      final last = cellCenter(tester, '3월 5일 (금) 17:30 ~ 18:00');
      expect(last.dy, lessThan(bar.top), reason: '단추 자리를 비워 둔다');
      semantics.dispose();
    });

    testWidgets('보내는 중에 누르면 기다렸다가 마쳤다고 알리고 추천 시간을 보인다', (tester) async {
      final semantics = tester.ensureSemantics();
      meetings.putGate = Completer<void>();
      await pumpMeeting(tester, size: const Size(400, 800));
      await tester.tapAt(cellCenter(tester, cell));
      await tester.pump(const Duration(seconds: 1));
      expect(meetings.puts, hasLength(1));
      expect(inFinish(find.text('자동 저장 중')), findsOneWidget);

      await tester.tap(finish());
      await tester.pump();
      expect(find.text('저장하는 중'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('저장하는 중')),
        isSemantics(isButton: true, isEnabled: false),
      );
      expect(find.text('자동 저장 중'), findsNothing, reason: '누른 뒤에는 막힌 단추만 둔다');
      expect(find.text('입력을 마쳤어요'), findsNothing);

      meetings.putGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('입력을 마쳤어요'), findsOneWidget);
      expect(find.text('언제든 다시 고칠 수 있어요'), findsOneWidget);
      expect(finish(), findsNothing, reason: '다음에 바꿀 때까지 조용하다');
      expect(meetings.puts, hasLength(1), reason: '이미 보낸 것을 또 보내지 않는다');
      final bar = tester.getRect(find.text('입력을 마쳤어요'));
      expectSlotsInView(tester, bottom: bar.top);
      expect(
        tester.takeAnnouncements().map((a) => a.message),
        contains('입력을 마쳤어요. 언제든 다시 고칠 수 있어요'),
      );
      semantics.dispose();
    });

    testWidgets('기다리던 저장은 기다리지 않고 바로 보낸다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpMeeting(tester, size: const Size(400, 800));
      await tester.tapAt(cellCenter(tester, cell));
      await tester.pump();
      expect(meetings.puts, isEmpty);

      await tester.tap(finish());
      await tester.pump();
      await tester.pump();
      expect(meetings.puts, hasLength(1));
      await tester.pumpAndSettle();
      expect(find.text('입력을 마쳤어요'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('저장하지 못하면 마쳤다고 하지 않고, 다시 저장하기로 다시 보낸다', (tester) async {
      final semantics = tester.ensureSemantics();
      meetings.putError = Exception('끊김');
      await pumpMeeting(tester, size: const Size(400, 800));
      await tester.tapAt(cellCenter(tester, cell));
      await tester.pump();

      await tester.tap(finish());
      await tester.pumpAndSettle();
      expect(find.text('저장하지 못했어요'), findsOneWidget);
      expect(find.text('입력을 마쳤어요'), findsNothing);
      expect(meetings.puts, hasLength(1));

      await tester.tap(find.text('다시 저장하기'));
      await tester.pumpAndSettle();
      expect(meetings.puts, hasLength(2));
      expect(find.text('입력을 마쳤어요'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('마친 뒤 또 칠하면 자동 저장 중과 저장하기부터 다시 보인다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpMeeting(tester, size: const Size(400, 800));
      await tester.tapAt(cellCenter(tester, cell));
      await tester.pump();
      await tester.tap(finish());
      await tester.pumpAndSettle();
      expect(find.text('입력을 마쳤어요'), findsOneWidget);

      await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
      await tester.pumpAndSettle();
      await tester.tapAt(cellCenter(tester, '3월 2일 (화) 6:00 ~ 6:30'));
      await tester.pump();
      expect(inFinish(find.text('자동 저장 중')), findsOneWidget);
      expect(enabled(tester, '저장하기'), isTrue);
      expect(find.text('입력을 마쳤어요'), findsNothing);
      semantics.dispose();
    });

    testWidgets('넓은 화면에서는 격자 아래 오른쪽 끝에 맞춰 두고 상태는 단추 앞에 둔다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpMeeting(tester, size: const Size(1280, 900));
      await tester.tapAt(cellCenter(tester, cell));
      await tester.pump();

      final button = tester.getRect(finish());
      final lastCell = cellCenter(tester, '3월 5일 (금) 17:30 ~ 18:00');
      expect(button.top, greaterThan(lastCell.dy));
      expect(
        button.right,
        closeTo(
          tester.getRect(find.byType(MeetingAvailabilitySection)).right,
          1,
        ),
      );
      final status = tester.getRect(find.text('자동 저장 중'));
      expect(status.right, lessThanOrEqualTo(button.left));
      expect(status.center.dy, closeTo(button.center.dy, 4));
      semantics.dispose();
    });

    testWidgets('저절로 저장하면 그래도 저장하기를 두고, 누르면 다시 보내지 않고 마쳤다고 알리며 추천 시간을 보인다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpMeeting(tester, size: const Size(400, 800));
      await tester.tapAt(cellCenter(tester, cell));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(meetings.puts, hasLength(1));
      expect(inFinish(find.text('자동 저장됐어요')), findsOneWidget);
      expect(finish(), findsNothing);
      expect(find.text('입력을 마쳤어요'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, '그래도 저장하기'));
      await tester.pumpAndSettle();

      expect(find.text('입력을 마쳤어요'), findsOneWidget);
      expect(find.text('자동 저장됐어요'), findsNothing);
      expect(find.text('그래도 저장하기'), findsNothing);
      expect(meetings.puts, hasLength(1), reason: '이미 저장했다');
      expectSlotsInView(
        tester,
        bottom: tester.getRect(find.text('입력을 마쳤어요')).top,
      );
      expect(
        tester.takeAnnouncements().map((a) => a.message),
        contains('입력을 마쳤어요. 언제든 다시 고칠 수 있어요'),
      );
      semantics.dispose();
    });

    group('Ctrl+S', () {
      const finished = '입력을 마쳤어요. 언제든 다시 고칠 수 있어요';
      const platforms = TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.macOS,
      });

      /// Ctrl+S(macOS는 Cmd+S)를 눌렀다 떼고, 앱이 S 누름을 받았는지 돌려준다
      Future<bool> pressSave(WidgetTester tester) async {
        final modifier = defaultTargetPlatform == TargetPlatform.macOS
            ? LogicalKeyboardKey.metaLeft
            : LogicalKeyboardKey.controlLeft;
        await tester.sendKeyDownEvent(modifier);
        final handled = await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
        await tester.sendKeyUpEvent(modifier);
        return handled;
      }

      /// 지금까지 스크린 리더에 알린 말(가져오면 비운다)
      List<String> announced(WidgetTester tester) => [
        for (final announcement in tester.takeAnnouncements())
          announcement.message,
      ];

      testWidgets('자동 저장 중이면 저장하기처럼 기다리던 저장을 바로 보내고 마쳤다고 알린다', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpMeeting(tester, size: const Size(400, 800));
        await tester.tapAt(cellCenter(tester, cell));
        await tester.pump();
        expect(inFinish(find.text('자동 저장 중')), findsOneWidget);
        expect(meetings.puts, isEmpty);

        expect(await pressSave(tester), isTrue);
        await tester.pump();
        await tester.pump();
        expect(meetings.puts, hasLength(1), reason: '기다리지 않고 바로 보낸다');
        await tester.pumpAndSettle();
        expect(find.text('입력을 마쳤어요'), findsOneWidget);
        expect(announced(tester), contains(finished));
        expectSlotsInView(
          tester,
          bottom: tester.getRect(find.text('입력을 마쳤어요')).top,
        );
        semantics.dispose();
      }, variant: platforms);

      testWidgets('저절로 저장했으면 그래도 저장하기처럼 다시 보내지 않고 마쳤다고 알린다', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpMeeting(tester, size: const Size(400, 800));
        await tester.tapAt(cellCenter(tester, cell));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(inFinish(find.text('자동 저장됐어요')), findsOneWidget);

        expect(await pressSave(tester), isTrue);
        await tester.pumpAndSettle();
        expect(find.text('입력을 마쳤어요'), findsOneWidget);
        expect(meetings.puts, hasLength(1), reason: '이미 저장했다');
        expect(announced(tester), contains(finished));
        semantics.dispose();
      }, variant: platforms);

      testWidgets('저장하지 못했으면 다시 저장하기처럼 다시 보내 마친다', (tester) async {
        final semantics = tester.ensureSemantics();
        meetings.putError = Exception('끊김');
        await pumpMeeting(tester, size: const Size(400, 800));
        await tester.tapAt(cellCenter(tester, cell));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(inFinish(find.text('저장하지 못했어요')), findsOneWidget);
        expect(meetings.puts, hasLength(1));

        expect(await pressSave(tester), isTrue);
        await tester.pumpAndSettle();
        expect(meetings.puts, hasLength(2));
        expect(find.text('입력을 마쳤어요'), findsOneWidget);
        expect(announced(tester), contains(finished));
        semantics.dispose();
      }, variant: platforms);

      testWidgets('누를 단추가 없으면(바꾸기 전, 저장하는 중, 마친 뒤) 저장하거나 알리지 않고 키만 받는다', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        meetings.putGate = Completer<void>();
        await pumpMeeting(tester, size: const Size(400, 800));
        announced(tester);

        expect(await pressSave(tester), isTrue, reason: '브라우저의 페이지 저장을 막는다');
        await tester.pumpAndSettle();
        expect(meetings.puts, isEmpty);
        expect(finish(), findsNothing);
        expect(announced(tester), isEmpty);

        await tester.tapAt(cellCenter(tester, cell));
        await tester.pump(const Duration(seconds: 1));
        expect(meetings.puts, hasLength(1));
        await tester.tap(finish());
        await tester.pump();
        expect(find.text('저장하는 중'), findsOneWidget);
        expect(await pressSave(tester), isTrue);
        await tester.pump();
        expect(find.text('저장하는 중'), findsOneWidget);

        meetings.putGate!.complete();
        await tester.pumpAndSettle();
        expect(find.text('입력을 마쳤어요'), findsOneWidget);
        expect(
          announced(tester).where((message) => message == finished),
          hasLength(1),
          reason: '저장하는 중에 눌러도 한 번만 마친다',
        );

        expect(await pressSave(tester), isTrue);
        await tester.pumpAndSettle();
        expect(announced(tester), isEmpty);
        expect(find.text('입력을 마쳤어요'), findsOneWidget);
        expect(meetings.puts, hasLength(1));
        semantics.dispose();
      }, variant: platforms);
    });
  });

  testWidgets('카드의 달력 단추를 누르면 모임 제목과 그 시간으로 새 일정이 열린다', (tester) async {
    meetings.availability = [
      availabilityOf('a', name: '민수', slots: [(seoul(1, 9), seoul(1, 10))]),
      availabilityOf('b', name: '서연', slots: [(seoul(1, 9), seoul(1, 10))]),
    ];
    await pumpMeeting(tester);

    final button = find.text('내 달력에 넣기');
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

  testWidgets('공유 창이 없는 환경이면 공유하기가 모임 링크를 복사한다', (tester) async {
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
    await tester.ensureVisible(find.text('공유하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('공유하기'));
    await tester.pumpAndSettle();

    expect(copied, [link]);
    expect(find.text('링크를 복사했습니다'), findsOneWidget);
  });

  testWidgets('로그인 상자 자리에 지금 계정으로 진행 중이라고 하고 로그아웃을 두며 게스트로 들어가는 길은 없다', (
    tester,
  ) async {
    meetings.meeting = makeMeeting().copyWith(allowGuests: true);
    await pumpMeeting(tester);

    expect(find.text('user@example.com 계정으로 진행 중입니다'), findsOneWidget);
    expect(find.text('Guest'), findsNothing);
    expect(find.text('로그아웃'), findsOneWidget);
  });

  testWidgets('넓으면 격자 오른쪽에 계정·링크·일정 참여자·추천 시간을 둔다', (tester) async {
    await pumpMeeting(tester, size: const Size(1280, 800));

    final grid = tester.getTopLeft(find.text('내 시간 선택하기'));
    final account = tester.getTopLeft(find.text('로그인'));
    final link = tester.getTopLeft(find.text('링크'));
    final people = tester.getTopLeft(find.text('일정 참여자'));
    final slots = tester.getTopLeft(find.text('추천 시간'));
    expect(account.dx, greaterThan(grid.dx + 400));
    expect(link.dx, account.dx);
    expect(people.dx, link.dx);
    final rows = [account.dy, link.dy, people.dy, slots.dy];
    expect(rows, orderedEquals([...rows]..sort()));
  });

  group('넓은 화면의 양쪽 높이', () {
    const wide = Size(1280, 800);

    /// 3월 1일에 12명이 6~18시에 되는 서로 다른 이어진 시간을 칠한 모임(추천 카드가 많다)
    List<AvailabilityRead> crowd() => [
      for (var i = 0; i < 12; i++)
        availabilityOf(
          'p$i',
          slots: [
            (seoul(1 + i % 5, 6 + i), seoul(1 + i % 5, 8 + i)),
            (seoul(1 + (i + 1) % 5, 6 + i), seoul(1 + (i + 1) % 5, 8 + i)),
          ],
        ),
    ];

    ScrollableState pageScroll(WidgetTester tester) =>
        tester.state<ScrollableState>(find.byType(Scrollable).first);

    ScrollableState cardScroll(WidgetTester tester) => tester.state(
      find
          .ancestor(
            of: find.byType(MeetingSlotCard).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );

    testWidgets('격자가 짧으면 화면은 굴러가지 않고 오른쪽 칸은 화면 안에 들며 카드 목록만 상자 안에서 굴러간다', (
      tester,
    ) async {
      meetings =
          FakeMeetingsClient(
              meeting: makeMeeting(
                endDate: DateTime.utc(2027, 3, 10),
                mode: MeetingMode.daily,
                startTime: '00:00:00',
                endTime: '00:00:00',
              ),
            )
            ..availability = [
              for (var i = 0; i < 12; i++)
                availabilityOf(
                  'p$i',
                  slots: [(seoul(1 + i % 9, 0), seoul(2 + i % 9 + i % 2, 0))],
                ),
            ];
      await pumpMeeting(tester, size: wide);

      expect(pageScroll(tester).position.maxScrollExtent, 0);
      final panel = tester.getRect(find.byType(MeetingSlotsPanel));
      expect(panel.bottom, lessThanOrEqualTo(wide.height));
      final title = tester.getTopLeft(find.text('추천 시간'));

      final cards = cardScroll(tester);
      expect(cards.position.maxScrollExtent, greaterThan(0));
      await tester.drag(
        find.byType(MeetingSlotCard).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(cards.position.pixels, greaterThan(0));
      expect(tester.getTopLeft(find.text('추천 시간')), title, reason: '제목 줄은 그대로');
      expect(find.byType(Scrollbar), findsWidgets);
    });

    testWidgets('격자가 길면 화면이 굴러가고 오른쪽 칸은 화면에 머문다', (tester) async {
      meetings = FakeMeetingsClient(
        meeting: makeMeeting(startTime: '06:00:00', endTime: '00:00:00'),
      )..availability = crowd();
      await pumpMeeting(tester, size: wide);
      final page = pageScroll(tester);
      expect(page.position.maxScrollExtent, greaterThan(200));
      final account = tester.getTopLeft(find.text('로그인'));

      page.position.jumpTo(200);
      await tester.pump();

      expect(tester.getTopLeft(find.text('로그인')), account);
      expect(
        tester.getRect(find.byType(MeetingSlotsPanel)).bottom,
        lessThanOrEqualTo(wide.height),
      );
    });

    testWidgets('카드 목록 끝에서 휠을 더 굴리면 화면이 굴러간다', (tester) async {
      meetings = FakeMeetingsClient(
        meeting: makeMeeting(startTime: '06:00:00', endTime: '00:00:00'),
      )..availability = crowd();
      await pumpMeeting(tester, size: wide);
      final cards = cardScroll(tester);
      cards.position.jumpTo(cards.position.maxScrollExtent);
      await tester.pump();
      final page = pageScroll(tester);
      expect(page.position.pixels, 0);

      final at = tester.getCenter(find.byType(MeetingSlotCard).last);
      // ignore: avoid_print
      print(
        'DEBUG ${find.byType(Scrollable).evaluate().map((e) => ((e as StatefulElement).state as ScrollableState).position).map((p) => '${p.pixels}/${p.maxScrollExtent}').toList()} at $at',
      );
      // 목록 끝에서는 바깥(오른쪽 칸이 넘치면 그 칸, 다음은 화면)이 받는다
      for (var i = 0; i < 3; i++) {
        await tester.sendEventToBinding(
          PointerScrollEvent(position: at, scrollDelta: const Offset(0, 120)),
        );
        await tester.pumpAndSettle();
      }

      expect(page.position.pixels, greaterThan(0));
    });
  });

  group('좁은 화면', () {
    const narrow = Size(360, 800);

    double fontSize(WidgetTester tester, Finder text) =>
        tester.renderObject<RenderParagraph>(text).text.style!.fontSize!;

    testWidgets('조용한 계정 줄 다음 바로 격자이고, 추천 시간·일정 참여자·링크 순서다', (tester) async {
      await pumpMeeting(tester, size: narrow);

      final order = [
        for (final title in [
          'user@example.com 계정으로 진행 중입니다',
          '내 시간 선택하기',
          '추천 시간',
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

    testWidgets('격자 → 추천 시간 → 일정 참여자·링크로 갈수록 제목이 작아지고 끝의 둘은 상자가 아니다', (
      tester,
    ) async {
      await pumpMeeting(tester, size: narrow);

      double size(String title) =>
          fontSize(tester, find.text(title, skipOffstage: false));
      expect(size('내 시간 선택하기'), greaterThanOrEqualTo(size('추천 시간')));
      expect(size('추천 시간'), greaterThan(size('일정 참여자')));
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

  group('링크를 누가 열 수 있는지', () {
    testWidgets('정한 이메일만 여는 모임은 링크 칸에 한 줄로 알린다', (tester) async {
      meetings.meeting = makeMeeting().copyWith(
        visibilityLevel: VisibilityLevel.allowedEmails,
      );
      await pumpMeeting(tester, size: const Size(1280, 900));

      expect(find.text('정한 이메일로 로그인한 사람만 열 수 있어요'), findsOneWidget);
    });

    testWidgets('공개 모임과 범위를 모르는 모임은 알리지 않는다', (tester) async {
      for (final level in [VisibilityLevel.public, null]) {
        meetings.meeting = makeMeeting().copyWith(visibilityLevel: level);
        await pumpMeeting(tester, size: const Size(1280, 900));
        expect(find.textContaining('열 수 있어요'), findsNothing, reason: '$level');
        expect(find.text('나만 볼 수 있어요'), findsNothing, reason: '$level');
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  testWidgets('링크로 바로 열어 돌아갈 곳이 없으면 뒤로 가기 없이 서비스 배지로 홈에 간다', (tester) async {
    await pumpMeeting(tester);

    expect(find.byType(BackButton), findsNothing);
    await tester.tap(find.byTooltip('홈으로'));
    await tester.pumpAndSettle();

    expect(find.text('처음 화면'), findsOneWidget);
  });

  group('다른 화면에서 열었으면', () {
    Future<GoRouter> pushMeeting(WidgetTester tester) async {
      final router = await pumpMeeting(tester, initialLocation: '/');
      router.pushNamed(
        AppRoute.meeting.name,
        pathParameters: {'meetingId': 'meeting-1'},
      );
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('뒤로 가기가 맨 왼쪽이고 그 오른쪽에 서비스 배지가 있다', (tester) async {
      await pushMeeting(tester);

      final back = tester.getCenter(find.byType(BackButton));
      final home = tester.getCenter(find.byTooltip('홈으로'));
      expect(back.dx, lessThan(home.dx));
      expect(back.dy, home.dy);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('처음 화면'), findsOneWidget);
    });

    testWidgets('서비스 배지는 뒤로 가지 않고 홈으로 간다', (tester) async {
      final router = await pushMeeting(tester);

      await tester.tap(find.byTooltip('홈으로'));
      await tester.pumpAndSettle();

      expect(find.text('처음 화면'), findsOneWidget);
      expect(router.canPop(), isFalse);
    });
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
