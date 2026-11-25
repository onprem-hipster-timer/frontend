import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_appointment_block.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_timer_start_button_view.dart';
import 'package:momeet/features/trial/domain/trial_flow.dart';
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_spotlight.dart';

import '../../trial_harness.dart';

final _ring = find.byKey(TrialSpotlight.ringKey);

/// [label] 글자가 든 단추
Finder _button(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
);

/// 테두리가 하나뿐이고 [target]과 같은 자리다
void _expectRingOn(WidgetTester tester, Finder target) {
  expect(_ring, findsOneWidget);
  expect(target, findsOneWidget);
  expect(tester.getRect(_ring), tester.getRect(target));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  testWidgets('달력 단계에서는 화면 안의 시험 일정을 강조한다', (tester) async {
    await openTrial(tester);

    final screen = Offset.zero & tester.view.physicalSize;
    final blocks = find
        .ancestor(
          of: find.text(trialExamTitle),
          matching: find.byType(ScheduleAppointmentBlock),
        )
        .evaluate()
        .map((element) => tester.getRect(find.byWidget(element.widget)))
        .where((rect) => screen.contains(rect.center));
    expect(_ring, findsOneWidget);
    expect(tester.getRect(_ring), blocks.single);
  });

  testWidgets('일정 상세 단계에서는 할 일로 변환을, 변환한 뒤에는 연결된 할 일 보기를 강조한다', (tester) async {
    await openTrial(tester);
    await goToSchedule(tester);
    _expectRingOn(tester, _button(convertLabel));

    await tester.tap(find.text(convertLabel));
    await tester.pumpAndSettle();
    _expectRingOn(tester, _button(linkedLabel));
  });

  testWidgets('할 일 단계에서는 재생 버튼의 둥근 아이콘을, 타이머를 시작한 뒤에는 남은 시간을 강조한다', (
    tester,
  ) async {
    await openTrial(tester);
    await goToTodo(tester);
    _expectRingOn(
      tester,
      find.descendant(
        of: find.byType(TodoTimerStartButtonView),
        matching: find.byIcon(Icons.play_circle_outline),
      ),
    );
    // 퍼지는 테두리까지(사이 3, 퍼짐 4, 선 굵기의 반 1) 옆의 수정 단추에 닿지 않는다
    final reach = tester.getRect(_ring).inflate(8);
    expect(reach.overlaps(tester.getRect(_button('수정'))), isFalse);

    await startTimer(tester);
    _expectRingOn(tester, find.byType(ActionChip));
  });

  testWidgets('타이머 단계와 끝 화면에서는 아무것도 강조하지 않는다', (tester) async {
    await openTrial(tester);
    await goToTimer(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(headlineOf(TrialStep.timer), findsOneWidget);
    expect(_ring, findsNothing);

    await tester.pump(trialTimerSweep);
    await tester.pumpAndSettle();
    expect(headlineOf(TrialStep.end), findsOneWidget);
    expect(_ring, findsNothing);
  });

  testWidgets('강조한 할 일로 변환의 가운데를 누르면 변환된다', (tester) async {
    await openTrial(tester);
    await goToSchedule(tester);

    await tester.tapAt(tester.getCenter(_ring));
    await tester.pumpAndSettle();

    expect(convertedHeadline, findsOneWidget);
  });

  testWidgets('애니메이션을 줄이지 않았으면 달력의 강조가 자리 잡은 뒤 나타나 되풀이해 퍼진다', (tester) async {
    await openTrial(tester, motion: true);

    expect(_ring, findsOneWidget);
    final fade = tester.widget<FadeTransition>(
      find.ancestor(of: _ring, matching: find.byType(FadeTransition)).first,
    );
    expect(fade.opacity.value, 1);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pumpWidget(const SizedBox());
  });
}
