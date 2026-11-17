import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_calendar.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 2027년 3월의 [day]일 (3월 1일은 월요일)
DateTime march(int day) => DateTime.utc(2027, 3, day);

Finder dayCell(String label) => find.bySemanticsLabel(RegExp('^$label'));

void main() {
  late List<DateTime> taps;

  Future<void> pumpCalendar(
    WidgetTester tester, {
    DateTime? firstDay,
    MeetingDayState Function(DateTime day)? stateOf,
  }) async {
    taps = [];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MeetingCalendar(
              firstDay: firstDay ?? march(10),
              stateOf: stateOf ?? (_) => MeetingDayState.open,
              onDayTap: taps.add,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('첫날이 든 달을 연도·달 숫자·영문 달 이름으로 보이고 일요일부터 칸을 놓는다', (tester) async {
    await pumpCalendar(tester);

    expect(find.text('2027'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.text('March'), findsOneWidget);
    final sunday = tester.getRect(find.text('Sun'));
    final monday = tester.getRect(find.text('Mon'));
    expect(sunday.left, lessThan(monday.left));
    final first = tester.getCenter(dayCell('3월 1일'));
    expect((first.dx - monday.center.dx).abs(), lessThan(1));
  });

  testWidgets('누른 날을 날짜만으로 알린다', (tester) async {
    await pumpCalendar(tester);

    await tester.tap(dayCell('3월 12일'));

    expect(taps, [march(12)]);
  });

  testWidgets('고를 수 없는 날은 눌러도 알리지 않고, 뺀 날은 알린다', (tester) async {
    await pumpCalendar(
      tester,
      stateOf: (day) => switch (day.day) {
        5 => MeetingDayState.unavailable,
        20 => MeetingDayState.excluded,
        _ => MeetingDayState.open,
      },
    );

    await tester.tap(dayCell('3월 5일'));
    await tester.tap(dayCell('3월 20일'));

    expect(taps, [march(20)]);
  });

  testWidgets('스크린 리더가 날짜·고른 상태·고를 수 있는지·뺀 날을 읽는다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpCalendar(
      tester,
      stateOf: (day) => switch (day.day) {
        3 => MeetingDayState.selected,
        5 => MeetingDayState.unavailable,
        20 => MeetingDayState.excluded,
        _ => MeetingDayState.open,
      },
    );

    expect(
      tester.getSemantics(dayCell('3월 3일')),
      isSemantics(
        label: '3월 3일 (수)',
        isButton: true,
        isSelected: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(dayCell('3월 5일')),
      isSemantics(
        label: '3월 5일 (금)',
        isSelected: false,
        isEnabled: false,
        hasTapAction: false,
      ),
    );
    expect(
      tester.getSemantics(dayCell('3월 20일')),
      isSemantics(
        label: '3월 20일 (토)',
        hint: '뺀 날',
        isSelected: false,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('다음 달로 넘기고 돌아올 수 있지만 첫날이 든 달 앞으로는 가지 않는다', (tester) async {
    await pumpCalendar(tester);

    final previous = find.widgetWithIcon(IconButton, Icons.chevron_left);
    expect(tester.widget<IconButton>(previous).onPressed, isNull);

    await tester.tap(find.byTooltip('다음 달'));
    await tester.pump();
    expect(find.text('April'), findsOneWidget);
    await tester.tap(dayCell('4월 30일'));
    expect(taps, [DateTime.utc(2027, 4, 30)]);

    await tester.tap(previous);
    await tester.pump();
    expect(find.text('March'), findsOneWidget);
    expect(tester.widget<IconButton>(previous).onPressed, isNull);
  });

  testWidgets('해를 넘겨 다음 달로 간다', (tester) async {
    await pumpCalendar(tester, firstDay: DateTime.utc(2027, 12, 31));

    await tester.tap(find.byTooltip('다음 달'));
    await tester.pump();

    expect(find.text('2028'), findsOneWidget);
    expect(find.text('January'), findsOneWidget);
  });

  testWidgets('한 달의 날을 빠짐없이 한 번씩 놓는다', (tester) async {
    await pumpCalendar(tester, firstDay: DateTime.utc(2028, 2, 1));

    for (var day = 1; day <= 29; day++) {
      expect(dayCell('2월 $day일'), findsOneWidget, reason: '2월 $day일');
    }
    expect(dayCell('2월 30일'), findsNothing);
    expect(dayCell('3월 1일'), findsNothing);
  });

  testWidgets(
    '날짜 글자는 달력과 같은 색이다: 고를 수 있는 일·토요일은 공휴일·토요일 색, 흐린 날과 뺀 날은 요일과 상관없이 달력의 흐린 날짜 색이고 뺀 날은 줄을 긋는다',
    (tester) async {
      await pumpCalendar(
        tester,
        stateOf: (day) => day.day < 10
            ? MeetingDayState.unavailable
            : day.day == 14
            ? MeetingDayState.excluded
            : MeetingDayState.open,
      );
      final context = tester.element(find.byType(MeetingCalendar));
      final scheme = Theme.of(context).colorScheme;
      final app = AppColors.of(context);
      TextStyle? styleOf(int day) => tester
          .widget<Text>(
            find.descendant(
              of: dayCell('3월 $day일'),
              matching: find.text('$day'),
            ),
          )
          .style;
      Color? colorOf(int day) => styleOf(day)?.color;

      final dim = scheme.onSurface.withValues(alpha: 0.4);
      expect(colorOf(7), dim, reason: '지난 일요일');
      expect(colorOf(6), dim, reason: '지난 토요일');
      expect(colorOf(14), dim, reason: '뺀 일요일');
      expect(styleOf(14)?.decoration, TextDecoration.lineThrough);
      expect(styleOf(16)?.decoration, isNot(TextDecoration.lineThrough));
      expect(colorOf(21), app.holiday);
      expect(colorOf(20), app.saturday);
      expect(colorOf(16), scheme.onSurface);
    },
  );
}
