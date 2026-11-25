import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_detail_body.dart';
import 'package:momeet/features/trial/domain/trial_flow.dart';
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_end.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_prompt.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_spotlight.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_todo_row.dart';
import 'package:momeet/shared/domain/terms.dart';

import '../../../../helpers/start_timer_sheet_driver.dart';
import '../../trial_harness.dart';

final _reveal = find.byKey(TrialPrompt.revealKey);
final _ring = find.byKey(TrialSpotlight.ringKey);

/// 보상 줄의 첫 낱말이 다 나타난 때(누른 순간부터)
final _firstWord = trialRewardLeave + trialRewardWord;

/// 나타나는 중인 보상 줄의 낱말들
Finder get _words => find.descendant(of: _reveal, matching: find.byType(Text));

/// 누른 뒤 보상 줄이 낱말마다 먼저 나타나고, 큰 한 줄과 강조는 그 뒤에 나타나며, 그동안 [stage]는 움직이지 않는다
Future<void> _expectRewardFirst(
  WidgetTester tester, {
  required Finder lead,
  required Finder headline,
  required Finder stage,
  required bool ring,
}) async {
  await tester.pump();
  final at = tester.getTopLeft(stage);
  await pumpFrames(tester, _firstWord);
  expect(shownOf(tester, _words.first), 1);
  expect(shownOf(tester, _words.last), lessThan(1));
  expect(shownOf(tester, headline), 0);
  if (ring) expect(shownOf(tester, _ring), 0);

  await pumpFrames(tester, const Duration(milliseconds: 2500));
  expect(_reveal, findsNothing);
  expect(shownOf(tester, lead), 1);
  expect(shownOf(tester, headline), 1);
  if (ring) expect(shownOf(tester, _ring), 1);
  expect(tester.getTopLeft(stage), at);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  testWidgets('할 일로 변환을 누르면 보상 줄이 먼저 나타나고 다음에 누를 것과 그 강조가 뒤따른다', (
    tester,
  ) async {
    await openTrial(tester);
    await goToSchedule(tester);
    await turnMotionOn(tester);

    await tester.tap(find.text(convertLabel));
    await _expectRewardFirst(
      tester,
      lead: convertedLead,
      headline: convertedHeadline,
      stage: find.byType(ScheduleDetailBody),
      ring: true,
    );
  });

  testWidgets('새 작업 시트에서 시작을 누르면 보상 줄이 먼저 나타나고 다음에 누를 것과 그 강조가 뒤따른다', (
    tester,
  ) async {
    await openTrial(tester);
    await goToTodo(tester);
    await tester.tap(find.byTooltip('${Terms.timer} 시작'));
    await tester.pumpAndSettle();
    await turnMotionOn(tester);

    await tester.tap(StartSheet.startButton);
    // 시트가 닫히는 동안 할 일 줄은 그대로다
    await _expectRewardFirst(
      tester,
      lead: startedLead,
      headline: startedHeadline,
      stage: find.byType(TrialTodoRow),
      ring: true,
    );
  });

  testWidgets('타이머가 끝나면 끝 화면의 보상 줄이 먼저 나타나고 움직임이 모두 멈춘다', (tester) async {
    await openTrial(tester);
    await goToTimer(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();

    // 타이머의 시간이 다 지나 끝 화면이 처음 그려질 때까지
    while (leadOf(TrialStep.end).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await pumpFrames(tester, _firstWord);
    expect(shownOf(tester, _words.first), 1);
    expect(shownOf(tester, _words.last), lessThan(1));
    expect(shownOf(tester, headlineOf(TrialStep.end)), 0);

    await tester.pumpAndSettle();
    expect(shownOf(tester, leadOf(TrialStep.end)), 1);
    expect(shownOf(tester, headlineOf(TrialStep.end)), 1);
    expect(_reveal, findsNothing);
    expect(find.byType(TrialEnd), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('애니메이션을 줄였으면 할 일로 변환을 누른 첫 프레임에 보상 줄과 다음에 누를 것, 다 보통 모습으로 보인다', (
    tester,
  ) async {
    await openTrial(tester);
    await goToSchedule(tester);

    await tester.tap(find.text(convertLabel));
    await tester.pump();

    expect(shownOf(tester, convertedLead), 1);
    expect(shownOf(tester, convertedHeadline), 1);
    expect(_reveal, findsNothing);
  });

  testWidgets('애니메이션을 줄였으면 타이머를 시작한 첫 프레임과 끝 화면의 첫 프레임에 보상 줄이 다 보인다', (
    tester,
  ) async {
    await openTrial(tester);
    await goToTodo(tester);
    await tester.tap(find.byTooltip('${Terms.timer} 시작'));
    await tester.pumpAndSettle();

    await tester.tap(StartSheet.startButton);
    await tester.pump();
    expect(shownOf(tester, startedLead), 1);
    expect(shownOf(tester, startedHeadline), 1);
    expect(_reveal, findsNothing);

    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SnackBarAction, '${Terms.timer} 보기'));
    // 끝 화면이 처음 그려질 때까지
    while (leadOf(TrialStep.end).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(shownOf(tester, leadOf(TrialStep.end)), 1);
    expect(shownOf(tester, headlineOf(TrialStep.end)), 1);
    expect(_reveal, findsNothing);
  });

  testWidgets('달력·변환 전 일정·타이머 시작 전 할 일·타이머 단계의 앞 줄은 낱말마다 나타나지 않는다', (
    tester,
  ) async {
    const settle = Duration(seconds: 1);
    await openTrial(tester);
    await turnMotionOn(tester);
    expect(leadOf(TrialStep.calendar), findsOneWidget);
    expect(_reveal, findsNothing);

    await tester.tap(find.text(trialExamTitle));
    await pumpFrames(tester, settle);
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(trialExamTitle),
      ),
    );
    await pumpFrames(tester, const Duration(milliseconds: 100));
    expect(leadOf(TrialStep.schedule), findsOneWidget);
    expect(_reveal, findsNothing);
    await pumpFrames(tester, settle);

    await tester.tap(find.text(convertLabel));
    await pumpFrames(tester, const Duration(seconds: 3));
    await tester.tap(find.text(linkedLabel));
    await pumpFrames(tester, const Duration(milliseconds: 100));
    expect(leadOf(TrialStep.todo), findsOneWidget);
    expect(_reveal, findsNothing);
    await pumpFrames(tester, settle);

    await tester.tap(find.byTooltip('${Terms.timer} 시작'));
    await pumpFrames(tester, settle);
    await tester.tap(StartSheet.startButton);
    await pumpFrames(tester, const Duration(seconds: 3));
    await tester.tap(find.widgetWithText(SnackBarAction, '${Terms.timer} 보기'));
    await pumpFrames(tester, const Duration(milliseconds: 100));
    expect(leadOf(TrialStep.timer), findsOneWidget);
    expect(_reveal, findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
