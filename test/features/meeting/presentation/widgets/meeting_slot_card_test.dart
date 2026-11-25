import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_run_highlight.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_name_chip.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slot_card.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slots_panel.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../meeting_fixtures.dart';

/// 서울 2027년 3월 [day]일 [hour]시의 UTC 시각
DateTime seoul(int day, int hour) => DateTime.utc(2027, 3, day, hour - 9);

/// [mode] 모임: 민수(주인)·서연이 3월 2일(시간별은 10~12시, 그 밖은 2~3일)에 되고 다현은 그때 안 된다.
/// [userId]가 없으면 회원이 아닌 사람(게스트)이 본다
MeetingBoard boardIn(MeetingMode mode, {String? userId = 'user-1'}) {
  final hourly = mode == MeetingMode.hourly;
  final when = hourly
      ? (seoul(2, 10), seoul(2, 12))
      : (seoul(2, 0), seoul(4, 0));
  return MeetingBoard(
    meeting: makeMeeting(
      mode: mode,
      endDate: hourly ? null : DateTime.utc(2027, 3, 7),
      startTime: hourly ? '06:00:00' : '00:00:00',
      endTime: hourly ? '18:00:00' : '00:00:00',
    ),
    availability: [
      availabilityOf(
        'a',
        name: '민수',
        userId: 'owner-1',
        owner: true,
        slots: [when],
      ),
      availabilityOf('b', name: '서연', slots: [when]),
      availabilityOf('d', name: '다현', unavailable: [when]),
    ],
    userId: userId,
    selfName: '지현',
  );
}

/// 화면 배치: 넓은 화면 옆 칸(남은 높이를 채우고 그 안에서 굴린다), 좁은 화면의 한 줄·여러 줄 카드
enum Layout { wideSide, narrowPhone, narrowTablet, narrowTabletPortrait }

/// [layout]에 둔 [board]의 추천 시간. [guest]면 게스트가 보는 것처럼 '내 달력에 넣기'가 없다
Future<void> pumpIn(
  WidgetTester tester,
  Layout layout,
  MeetingBoard board, {
  bool guest = false,
}) {
  final (view, panel) = switch (layout) {
    Layout.wideSide => (const Size(1280, 800), (380.0, 500.0)),
    Layout.narrowPhone => (const Size(360, 800), (328.0, null)),
    Layout.narrowTablet => (const Size(700, 800), (668.0, null)),
    Layout.narrowTabletPortrait => (const Size(800, 1280), (768.0, null)),
  };
  tester.view.physicalSize = view;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final slots = MeetingSlotsPanel(
    board: board,
    onAddToCalendar: guest ? null : (_) {},
    highlight: MeetingRunHighlight(),
    fill: layout == Layout.wideSide,
  );
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: layout == Layout.wideSide
            ? Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  width: panel.$1,
                  height: panel.$2,
                  child: slots,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SizedBox(width: panel.$1, child: slots),
              ),
      ),
    ),
  );
}

/// [box] 안의 마지막 내용(글자, 아이콘, 이름 칩, 단추)의 아래 끝
double contentBottom(WidgetTester tester, Finder box) => [
  for (final element
      in find
          .descendant(
            of: box,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Text ||
                  widget is Icon ||
                  widget is MeetingNameChip ||
                  widget is IconButton ||
                  widget is ButtonStyleButton,
            ),
          )
          .evaluate())
    tester.getRect(find.byWidget(element.widget)).bottom,
].reduce((a, b) => a > b ? a : b);

const calendarLabel = '내 달력에 넣기';

/// [inner]가 [outer] 안에 다 든다
bool within(Rect outer, Rect inner) =>
    outer.inflate(0.5).contains(inner.topLeft) &&
    outer.inflate(0.5).contains(inner.bottomRight);

/// [width] 폭의 카드 하나(3월 2일 10~12시, 세 명). [onAddToCalendar]가 없으면 게스트가 보는 카드다
Future<void> pumpCard(
  WidgetTester tester, {
  required double width,
  bool pinned = false,
  VoidCallback? onAddToCalendar,
}) {
  tester.view.physicalSize = const Size(600, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: MeetingSlotCard(
              title: '3월 2일 (화)',
              detail: '10:00 ~ 12:00',
              people: const [
                (name: '민수', owner: true, guest: false, self: false),
                (name: '서연', owner: false, guest: false, self: false),
                (name: '지현', owner: false, guest: false, self: true),
              ],
              unavailable: const ['다현'],
              pinned: pinned,
              onTap: () {},
              onCopy: () {},
              onAddToCalendar: onAddToCalendar,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(tz.initializeTimeZones);

  group('펼친 이름은 내용 높이만큼이다', () {
    for (final mode in MeetingMode.values) {
      for (final layout in Layout.values) {
        testWidgets('${mode.name} ${layout.name}', (tester) async {
          await pumpIn(tester, layout, boardIn(mode));
          final card = find.byType(MeetingSlotCard).first;
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          addTearDown(mouse.removePointer);
          await mouse.addPointer(location: Offset.zero);

          await mouse.moveTo(tester.getCenter(card));
          await tester.pumpAndSettle();
          final hover = find
              .ancestor(
                of: find.byType(MeetingNameChip).first,
                matching: find.byType(Material),
              )
              .first;
          expect(find.text('불가능 1명 · 다현'), findsOneWidget);
          expect(
            tester.getRect(hover).bottom - contentBottom(tester, hover),
            closeTo(8, 0.5),
            reason: '마우스로 띄운 이름 상자는 안쪽 여백만큼만 더 길다',
          );

          await tester.tap(card);
          await tester.pumpAndSettle();
          await mouse.moveTo(Offset.zero);
          await tester.pumpAndSettle();
          expect(find.text('불가능 1명 · 다현'), findsOneWidget);
          expect(
            tester.getRect(card).bottom - contentBottom(tester, card),
            lessThanOrEqualTo(12),
            reason: '고정해 펼친 카드는 마지막 줄 아래 여백만큼만 더 길다',
          );
        });
      }
    }
  });

  group('추천 시간 상자의 카드', () {
    for (final layout in Layout.values) {
      for (final scale in [1.0, 1.6]) {
        for (final guest in [false, true]) {
          final who = guest ? '게스트가' : '회원이';
          testWidgets('${layout.name}에서 글자 $scale배로 $who 보면 카드가 넘치지 않고 '
              '${guest ? '내 달력에 넣기가 없다' : '카드마다 내 달력에 넣기가 보인다'}', (
            tester,
          ) async {
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await pumpIn(
              tester,
              layout,
              boardIn(MeetingMode.hourly),
              guest: guest,
            );
            await tester.tap(find.byType(MeetingSlotCard).first);
            await tester.pumpAndSettle();

            final cards = find.byType(MeetingSlotCard);
            expect(cards, findsWidgets);
            for (final card in cards.evaluate()) {
              final label = find.descendant(
                of: find.byWidget(card.widget),
                matching: find.text(calendarLabel),
              );
              expect(label, guest ? findsNothing : findsOneWidget);
              if (!guest) {
                expect(
                  within(
                    tester.getRect(find.byWidget(card.widget)),
                    tester.getRect(label),
                  ),
                  isTrue,
                );
              }
            }
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });

  group('내 달력에 넣기', () {
    for (final width in [192, 259, 328, 480]) {
      for (final pinned in [false, true]) {
        final state = pinned ? '펼친' : '접은';
        testWidgets('폭 $width의 $state 회원 카드에서 내 달력에 넣기를 누르면 일정을 연다', (
          tester,
        ) async {
          var added = 0;
          await pumpCard(
            tester,
            width: width.toDouble(),
            pinned: pinned,
            onAddToCalendar: () => added++,
          );

          final label = find.text(calendarLabel);
          expect(
            find.ancestor(of: label, matching: find.byType(FilledButton)),
            findsOneWidget,
          );
          expect(
            within(
              tester.getRect(find.byType(MeetingSlotCard)),
              tester.getRect(label),
            ),
            isTrue,
          );

          await tester.tap(label);
          expect(added, 1);
        });

        testWidgets('폭 $width의 $state 게스트 카드에는 내 달력에 넣기가 없고 복사만 있다', (
          tester,
        ) async {
          await pumpCard(tester, width: width.toDouble(), pinned: pinned);

          expect(find.text(calendarLabel), findsNothing);
          expect(find.byType(FilledButton), findsNothing);
          expect(find.byTooltip('복사'), findsOneWidget);
        });
      }
    }

    testWidgets('내 달력에 넣기는 날짜와 같은 왼쪽에서 시작하고 복사는 그 줄 끝에 있다', (tester) async {
      await pumpCard(tester, width: 328, onAddToCalendar: () {});

      final button = tester.getRect(find.byType(FilledButton));
      final copy = tester.getRect(find.byTooltip('복사'));
      expect(button.left, tester.getRect(find.text('3월 2일 (화)')).left);
      expect(
        button.top,
        greaterThan(tester.getRect(find.text('10:00 ~ 12:00')).bottom),
      );
      expect(copy.center.dy, closeTo(button.center.dy, 0.5));
      expect(copy.left, greaterThan(button.right));
    });

    testWidgets('펼침 표시는 사람 수 바로 뒤에 있다', (tester) async {
      await pumpCard(tester, width: 328, onAddToCalendar: () {});

      final count = tester.getRect(find.text('3'));
      final chevron = tester.getRect(find.byIcon(Icons.expand_more));
      expect(chevron.left, greaterThanOrEqualTo(count.right));
      expect(chevron.center.dy, closeTo(count.center.dy, 2));
    });

    testWidgets('좁은 카드에 큰 글자면 내 달력에 넣기가 맨 아래 줄을 다 쓰고 복사는 날짜 줄로 간다', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpCard(tester, width: 192, onAddToCalendar: () {});

      final card = tester.getRect(find.byType(MeetingSlotCard));
      final button = tester.getRect(find.byType(FilledButton));
      final copy = tester.getRect(find.byTooltip('복사'));
      expect(button.width, greaterThan(card.width - 24));
      expect(
        copy.bottom,
        lessThan(tester.getRect(find.text('10:00 ~ 12:00')).top),
      );
      expect(
        tester.getSize(find.text(calendarLabel)).height,
        lessThan(tester.getSize(find.text('10:00 ~ 12:00')).height * 1.5),
        reason: '글이 한 줄이다',
      );
    });

    testWidgets('키보드로 내 달력에 넣기에 닿은 다음 복사에 닿고 Enter로 누를 수 있다', (tester) async {
      var added = 0;
      await pumpCard(tester, width: 328, onAddToCalendar: () => added++);
      final calendar = Focus.of(tester.element(find.text(calendarLabel)));
      final copy = Focus.of(
        tester.element(find.byIcon(Icons.content_copy_outlined)),
      );

      final order = <String>[];
      for (var i = 0; i < 6; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        if (calendar.hasPrimaryFocus) order.add('달력');
        if (copy.hasPrimaryFocus) order.add('복사');
      }
      expect(order.take(2), ['달력', '복사']);

      calendar.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(added, 1);
    });

    testWidgets('스크린 리더는 내 달력에 넣기를 누를 수 있는 단추로 읽는다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpCard(tester, width: 328, onAddToCalendar: () {});

      expect(
        tester.getSemantics(find.byType(FilledButton)),
        isSemantics(
          label: calendarLabel,
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });
  });
}
