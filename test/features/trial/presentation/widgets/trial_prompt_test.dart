import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/meeting.dart' show keepWords;
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_prompt.dart';

import '../../trial_harness.dart';

/// 체험하기 글과 그 아래 자리. [disableAnimations]면 애니메이션을 줄인 화면이다
Widget _app(TrialPrompt prompt, {bool disableAnimations = false}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              prompt,
              const SizedBox(key: _below, height: 40),
            ],
          ),
        ),
      ),
    );

const _below = ValueKey('below');
final _reveal = find.byKey(TrialPrompt.revealKey);
final _words = keepWords(trialConvertedLead).split(' ');
final _lead = find.text(keepWords(trialConvertedLead));
final _headline = find.text(keepWords(trialConvertedHeadline));
final _before = find.text(keepWords(trialScheduleLead));

/// 나타나는 중인 보상 줄의 [index]번째 낱말
Finder _word(int index) =>
    find.descendant(of: _reveal, matching: find.text(_words[index]));

const _reward = TrialPrompt(
  lead: trialConvertedLead,
  headline: trialConvertedHeadline,
  reward: true,
);

void main() {
  testWidgets('보상 줄은 낱말마다 차례로 흐림에서 또렷해지며 나타나고, 큰 한 줄은 그 뒤에 온다', (tester) async {
    await tester.pumpWidget(_app(_reward));
    expect(shownOf(tester, _word(0)), 0);

    await pumpFrames(tester, trialRewardLeave + trialRewardWord);
    expect(shownOf(tester, _word(0)), 1);
    expect(
      find.ancestor(of: _word(0), matching: find.byType(ImageFiltered)),
      findsNothing,
    );
    expect(shownOf(tester, _word(_words.length - 1)), lessThan(1));
    expect(
      find.ancestor(
        of: _word(_words.length - 1),
        matching: find.byType(ImageFiltered),
      ),
      findsOneWidget,
    );
    expect(shownOf(tester, _headline), 0);
  });

  testWidgets('보상 줄이 다 나타나면 보통 앞 줄과 같은 글과 모양으로 남고 움직임이 멈춘다', (tester) async {
    await tester.pumpWidget(_app(_reward));
    await tester.pump();
    final layout = tester.getRect(
      find.descendant(
        of: find.byType(TrialPrompt),
        matching: find.text(keepWords(trialConvertedLead)),
      ),
    );

    await tester.pumpAndSettle();
    expect(_reveal, findsNothing);
    expect(tester.getRect(_lead), layout);
    final theme = Theme.of(tester.element(_lead));
    expect(tester.widget<Text>(_lead).style, theme.textTheme.bodyLarge);
    expect(shownOf(tester, _lead), 1);
    expect(shownOf(tester, _headline), 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('좁은 화면에서도 낱말은 처음 프레임부터 다 나타난 글의 줄 바꿈 그대로의 자리에 놓인다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(_reward));
    await pumpFrames(tester, const Duration(milliseconds: 1000));
    final placed = [
      for (var i = 0; i < _words.length; i++) tester.getTopLeft(_word(i)),
    ];

    await tester.pumpAndSettle();
    final lead = tester.getTopLeft(_lead);
    expect(placed.first, lead);
    // 낱말은 줄 바꿈 그대로 놓여 두 줄 이상이면 다음 줄 첫 낱말이 앞 줄 첫 낱말 아래에 있다
    expect(placed.map((at) => at.dy).toSet().length, greaterThan(1));
    expect(
      placed.where((at) => at.dx == lead.dx).length,
      placed.map((at) => at.dy).toSet().length,
    );
  });

  testWidgets('보상 줄이 나타나는 동안에도 두 줄을 스크린 리더가 한 번씩 읽는다', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(_reward));

    expect(
      find.bySemanticsLabel(keepWords(trialConvertedLead)),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(_words.first), findsNothing);
    expect(
      find.bySemanticsLabel(keepWords(trialConvertedHeadline)),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    semantics.dispose();
  });

  testWidgets('애니메이션을 줄였으면 보상 줄과 큰 한 줄이 첫 프레임부터 보통 모습으로 다 보인다', (tester) async {
    await tester.pumpWidget(_app(_reward, disableAnimations: true));

    expect(_reveal, findsNothing);
    expect(shownOf(tester, _lead), 1);
    expect(shownOf(tester, _headline), 1);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('보상이 아닌 앞 줄은 낱말마다 나타나지 않는다', (tester) async {
    await tester.pumpWidget(
      _app(
        TrialPrompt(lead: trialScheduleLead, headline: trialScheduleHeadline),
      ),
    );

    expect(_before, findsOneWidget);
    expect(_reveal, findsNothing);
  });

  testWidgets('같은 자리에서 보상 줄로 바뀌면 앞 글은 짧게 흐려지며 사라지고 아래 자리는 움직이지 않는다', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        TrialPrompt(lead: trialScheduleLead, headline: trialScheduleHeadline),
      ),
    );

    await tester.pumpWidget(_app(_reward));
    final below = tester.getTopLeft(find.byKey(_below));
    expect(shownOf(tester, _before), 1);
    expect(shownOf(tester, _word(0)), 0);

    await tester.pump(trialRewardLeave);
    expect(shownOf(tester, _before), 0);

    await tester.pumpAndSettle();
    expect(_before, findsNothing);
    expect(shownOf(tester, _lead), 1);
    expect(shownOf(tester, _headline), 1);
    expect(tester.getTopLeft(find.byKey(_below)), below);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
