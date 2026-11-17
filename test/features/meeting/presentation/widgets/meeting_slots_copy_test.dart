import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_run_highlight.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slot_card.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slots_panel.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../meeting_fixtures.dart';
import 'meeting_panels_test.dart' show boardOf, threePeople;
import 'meeting_slot_card_test.dart' show boardIn;

final link = Uri.parse('https://momeet.example/meetings/meeting-1');

void main() {
  late List<String> copied;

  setUpAll(tz.initializeTimeZones);

  setUp(() => copied = []);

  /// [board]의 추천 시간. [guest]면 게스트가 보는 것처럼 '내 달력에 일정 만들기'가 없다
  Future<void> pumpSlots(
    WidgetTester tester,
    MeetingBoard board, {
    bool guest = false,
  }) async {
    tester.view.physicalSize = const Size(480, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MeetingSlotsPanel(
              board: board,
              onAddToCalendar: guest ? null : (_) {},
              highlight: MeetingRunHighlight(),
              link: link,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final lines = {
    MeetingMode.hourly: '3월 2일 (화) 10:00 ~ 12:00 · 2명',
    MeetingMode.daily: '3월 2일 ~ 3일 (2일) · 2명',
    MeetingMode.weekly: '화요일 ~ 수요일 (2일) · 2명',
  };

  for (final MapEntry(key: mode, value: line) in lines.entries) {
    for (final guest in [false, true]) {
      testWidgets(
        '${mode.name} ${guest ? '게스트' : '회원'}: 카드의 복사는 날짜·시각 · 인원, 이름, 불가능 줄을 글로 담고 알린다',
        (tester) async {
          await pumpSlots(
            tester,
            boardIn(mode, userId: guest ? null : 'user-1'),
            guest: guest,
          );
          expect(
            find.byTooltip('내 달력에 일정 만들기'),
            guest ? findsNothing : findsOneWidget,
          );

          await tester.tap(find.byTooltip('복사'));
          await tester.pumpAndSettle();

          expect(copied.single, '$line\n민수, 서연\n불가능 1명 · 다현');
          expect(find.text('추천 시간을 복사했습니다'), findsOneWidget);
        },
      );
    }
  }

  testWidgets('하루짜리 카드는 날짜와 하루 종일, 안 되는 사람이 없으면 이름까지만 담는다', (tester) async {
    final day5 = (DateTime.utc(2027, 3, 4, 15), DateTime.utc(2027, 3, 5, 15));
    await pumpSlots(
      tester,
      MeetingBoard(
        meeting: boardIn(MeetingMode.daily).meeting,
        availability: [
          availabilityOf('a', name: '민수', slots: [day5]),
          availabilityOf('b', name: '서연', slots: [day5]),
        ],
        userId: 'user-1',
        selfName: '지현',
      ),
    );

    await tester.tap(find.byTooltip('복사'));
    await tester.pumpAndSettle();

    expect(copied.single, '3월 5일 (금) 하루 종일 · 2명\n민수, 서연');
  });

  testWidgets('모두 복사는 모임 제목과 링크 아래에 지금 순서의 카드를 번호와 함께 담는다', (tester) async {
    await pumpSlots(tester, boardOf(threePeople()));
    expect(find.byType(MeetingSlotCard), findsNWidgets(4));

    await tester.tap(find.byTooltip('모두 복사'));
    await tester.pumpAndSettle();

    expect(
      copied.single,
      '팀 회의\n'
      'https://momeet.example/meetings/meeting-1\n'
      '\n'
      '1. 3월 1일 (월) 10:00 ~ 11:00 · 3명\n'
      '민수, 서연, 하준\n'
      '\n'
      '2. 3월 1일 (월) 9:00 ~ 10:00 · 2명\n'
      '민수, 서연\n'
      '\n'
      '3. 3월 1일 (월) 11:00 ~ 12:00 · 2명\n'
      '민수, 하준\n'
      '\n'
      '4. 3월 2일 (화) 10:00 ~ 11:00 · 2명\n'
      '서연, 하준',
    );
    expect(find.text('추천 시간을 모두 복사했습니다'), findsOneWidget);

    await tester.tap(find.text('모모밋 추천'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('날짜 순').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('모두 복사'));
    await tester.pumpAndSettle();

    expect(
      copied.last.split('\n').where((l) => RegExp(r'^\d+\. ').hasMatch(l)),
      [
        '1. 3월 1일 (월) 9:00 ~ 10:00 · 2명',
        '2. 3월 1일 (월) 10:00 ~ 11:00 · 3명',
        '3. 3월 1일 (월) 11:00 ~ 12:00 · 2명',
        '4. 3월 2일 (화) 10:00 ~ 11:00 · 2명',
      ],
    );
  });

  testWidgets('추천할 카드가 없으면 모두 복사가 없다', (tester) async {
    await pumpSlots(tester, boardOf([threePeople().first]));

    expect(find.byTooltip('모두 복사'), findsNothing);
  });

  testWidgets('카드의 글은 골라 복사할 수 있고 눌러 펼치기는 그대로다', (tester) async {
    await pumpSlots(tester, boardIn(MeetingMode.hourly));
    final card = find.byType(MeetingSlotCard);

    expect(
      find.descendant(of: card, matching: find.byType(SelectionArea)),
      findsOneWidget,
    );
    await tester.tap(find.text('3월 2일 (화)'));
    await tester.pumpAndSettle();
    expect(find.text('민수'), findsOneWidget, reason: '펼쳐 이름이 보인다');
  });
}
