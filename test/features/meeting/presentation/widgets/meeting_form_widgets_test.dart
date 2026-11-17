import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_choice_row.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_date_badge.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_help_icon.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_mode_selector.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_shake.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_time_range.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_title_field.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

Future<void> pumpBody(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  group('받는 방식 고르기', () {
    testWidgets('누른 방식을 알리고 고른 방식만 고른 상태로 읽힌다', (tester) async {
      final picked = <MeetingMode>[];
      await pumpBody(
        tester,
        MeetingModeSelector(
          mode: MeetingMode.daily,
          hourlyEnabled: true,
          onChanged: picked.add,
        ),
      );

      await tester.tap(find.text('요일별'));
      await tester.tap(find.text('시간별'));

      expect(picked, [MeetingMode.weekly, MeetingMode.hourly]);
      expect(
        tester.getSemantics(find.text('날짜별')),
        isSemantics(isSelected: true, isInMutuallyExclusiveGroup: true),
      );
      expect(
        tester.getSemantics(find.text('시간별')),
        isSemantics(isSelected: false),
      );
    });

    testWidgets('시간별을 고를 수 없으면 눌러도 알리지 않는다', (tester) async {
      final picked = <MeetingMode>[];
      await pumpBody(
        tester,
        MeetingModeSelector(
          mode: MeetingMode.daily,
          hourlyEnabled: false,
          onChanged: picked.add,
        ),
      );

      await tester.tap(find.text('시간별'));

      expect(picked, isEmpty);
      expect(
        tester.getSemantics(find.text('시간별')),
        isSemantics(isEnabled: false),
      );
    });
  });

  group('허용 / 비허용', () {
    testWidgets('라디오나 글자를 누르면 그 값을 알린다', (tester) async {
      final values = <bool>[];
      await pumpBody(
        tester,
        MeetingChoiceRow(label: '공개 여부', value: true, onChanged: values.add),
      );

      await tester.tap(find.text('비허용'));
      await tester.tap(find.byType(Radio<bool>).last);

      expect(values, [false, false]);
    });

    testWidgets('고를 수 없으면 둘 다 눌러도 알리지 않고 꺼진 상태로 읽힌다', (tester) async {
      await pumpBody(
        tester,
        const MeetingChoiceRow(label: '게스트 로그인', value: false, onChanged: null),
      );

      await tester.tap(find.text('허용'));
      await tester.pump();

      expect(
        tester.getSemantics(find.text('허용')),
        isSemantics(isEnabled: false, isChecked: false),
      );
      expect(
        tester.getSemantics(find.text('비허용')),
        isSemantics(isEnabled: false, isChecked: true),
      );
    });
  });

  group('떨림', () {
    /// 제자리에서 옆으로 밀린 거리
    double offsetOf(WidgetTester tester) =>
        tester.getTopLeft(find.text('방식')).dx;

    Widget shake(int count, {bool reduceMotion = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: MeetingShake(count: count, child: const Text('방식')),
        ),
      ),
    );

    testWidgets('처음 그릴 때는 떨지 않고 횟수가 바뀌면 짧게 떤 뒤 제자리로 온다', (tester) async {
      await tester.pumpWidget(shake(0));
      await tester.pump(const Duration(milliseconds: 100));
      expect(offsetOf(tester), 0);

      await tester.pumpWidget(shake(1));
      await tester.pump(const Duration(milliseconds: 40));
      expect(offsetOf(tester), isNot(0));

      await tester.pumpAndSettle();
      expect(offsetOf(tester), 0);
    });

    testWidgets('같은 횟수로 다시 그리면 떨지 않는다', (tester) async {
      await tester.pumpWidget(shake(2));
      await tester.pumpWidget(shake(2));
      await tester.pump(const Duration(milliseconds: 40));

      expect(offsetOf(tester), 0);
    });

    testWidgets('기기에서 애니메이션을 줄였으면 떨지 않는다', (tester) async {
      await tester.pumpWidget(shake(0, reduceMotion: true));
      await tester.pumpWidget(shake(1, reduceMotion: true));
      await tester.pump(const Duration(milliseconds: 40));

      expect(offsetOf(tester), 0);
    });
  });

  group('물음표 도움말', () {
    testWidgets('누르면 도움말이 뜬다', (tester) async {
      await pumpBody(tester, const MeetingHelpIcon('도움말 내용'));

      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('도움말 내용'), findsOneWidget);
    });

    testWidgets('마우스를 올려도 도움말이 뜬다', (tester) async {
      await pumpBody(tester, const MeetingHelpIcon('도움말 내용'));

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byIcon(Icons.help_outline)));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('도움말 내용'), findsOneWidget);
    });
  });

  group('하루 시간 범위', () {
    List<int?> optionsOf(WidgetTester tester, int index) => tester
        .widget<DropdownButton<int>>(find.byType(DropdownButton<int>).at(index))
        .items!
        .map((item) => item.value)
        .toList();

    testWidgets('시작은 6~23시, 끝은 시작 뒤부터 24시까지 고른다', (tester) async {
      final starts = <int>[];
      final ends = <int>[];
      await pumpBody(
        tester,
        MeetingTimeRange(
          startHour: 20,
          endHour: 22,
          onStartChanged: starts.add,
          onEndChanged: ends.add,
        ),
      );

      expect(optionsOf(tester, 0), [for (var h = 6; h <= 23; h++) h]);
      expect(optionsOf(tester, 1), [21, 22, 23, 24]);

      await tester.tap(find.text('20:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('21:00').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('22:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('24:00').last);
      await tester.pumpAndSettle();

      expect(starts, [21]);
      expect(ends, [24]);
    });

    testWidgets('스크린 리더가 시작·끝 시각 이름을 함께 읽는다', (tester) async {
      await pumpBody(
        tester,
        MeetingTimeRange(
          startHour: 6,
          endHour: 18,
          onStartChanged: (_) {},
          onEndChanged: (_) {},
        ),
      );

      expect(find.bySemanticsLabel(RegExp('시작 시각')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('끝 시각')), findsOneWidget);
    });
  });

  group('제목과 화살표', () {
    testWidgets('제목이 비면 이름이 든 자리 글자를 보이고 화살표·완료 키로 만든다', (tester) async {
      var submits = 0;
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpBody(
        tester,
        MeetingTitleField(
          controller: controller,
          placeholder: '지현님의 모임 일정',
          submitting: false,
          onSubmit: () => submits++,
        ),
      );

      expect(find.text('지현님의 모임 일정'), findsOneWidget);
      await tester.tap(find.byTooltip('모임 만들기'));
      await tester.enterText(find.byType(TextField), '주간 회의');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(submits, 2);
    });

    testWidgets('만드는 중에는 화살표 대신 진행 표시를 두고 누를 수 없다', (tester) async {
      var submits = 0;
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpBody(
        tester,
        MeetingTitleField(
          controller: controller,
          placeholder: '모임 일정',
          submitting: true,
          onSubmit: () => submits++,
        ),
      );

      await tester.tap(find.byTooltip('모임 만들기'));

      expect(submits, 0);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('제목은 200자까지 받는다', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpBody(
        tester,
        MeetingTitleField(
          controller: controller,
          placeholder: '모임 일정',
          submitting: false,
          onSubmit: () {},
        ),
      );

      await tester.enterText(find.byType(TextField), '가' * 250);

      expect(controller.text.length, 200);
    });
  });

  testWidgets('첫날 달력 그림의 윗띠는 달력의 강조색(primary)이고 고리는 그 위 글자색이다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: MeetingDateBadge(day: DateTime.utc(2027, 3, 1))),
      ),
    );
    final scheme = Theme.of(
      tester.element(find.byType(MeetingDateBadge)),
    ).colorScheme;
    final fills = [
      for (final box in tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(MeetingDateBadge),
          matching: find.byType(DecoratedBox),
        ),
      ))
        if (box.decoration case BoxDecoration(:final color?)) color,
    ];

    expect(fills, contains(scheme.primary));
    expect(fills.where((color) => color == scheme.onPrimary), hasLength(4));
    expect(fills, isNot(contains(scheme.tertiaryContainer)));
    expect(fills, isNot(contains(scheme.onTertiaryContainer)));
  });
}
