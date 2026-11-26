import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/trial/presentation/utils/trial_samples.dart';
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_end.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 펼친 답의 모임 화면 그림 자리
const _picture = ValueKey('picture');

final _ended = trialStart(DateTime(2026, 11, 25, 10))
    .openExam()
    .convert()
    .openTodo()
    .startTimer(const Duration(minutes: 25))
    .openTimer()
    .finishTimer();

/// 끝 화면을 연다. [reduceMotion]이면 애니메이션을 줄인 기기다
Future<void> _open(WidgetTester tester, {bool reduceMotion = false}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduceMotion);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: TrialEnd(
            todo: _ended.todo!,
            recordedSeconds: _ended.recordedSeconds,
            onSignUp: () {},
            onOpenTrust: () {},
            onCreateMeeting: () {},
            meetingPreview: const ColoredBox(key: _picture, color: Colors.grey),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 펼친 답이 지금 차지하는 높이
double _answerHeight(WidgetTester tester) =>
    tester.getSize(find.byType(SizeTransition)).height;

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  testWidgets('처음에는 물음만 있고 답과 그림은 그리지 않는다', (tester) async {
    await _open(tester);

    expect(find.text(trialMeetingQuestion), findsOneWidget);
    expect(find.text(trialMeetingLead), findsNothing);
    expect(find.text(trialMeetingAction), findsNothing);
    expect(find.byKey(_picture), findsNothing);
  });

  testWidgets('물음을 누르면 답이 조금씩 펼쳐지고, 다 펼친 뒤에는 더 그릴 프레임을 남기지 않는다', (
    tester,
  ) async {
    await _open(tester);

    await tester.tap(find.text(trialMeetingQuestion));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final midway = _answerHeight(tester);
    await tester.pumpAndSettle();
    final full = _answerHeight(tester);

    expect(midway, greaterThan(0));
    expect(midway, lessThan(full));
    expect(find.byKey(_picture), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('애니메이션을 줄인 기기에서는 물음을 누른 다음 프레임에 답이 다 펼쳐진다', (tester) async {
    await _open(tester, reduceMotion: true);

    await tester.tap(find.text(trialMeetingQuestion));
    await tester.pump();
    final first = _answerHeight(tester);
    await tester.pumpAndSettle();

    expect(first, greaterThan(0));
    expect(first, _answerHeight(tester));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('펼친 물음을 다시 누르면 접히며 사라지고, 다 접힌 뒤에는 더 그릴 프레임을 남기지 않는다', (
    tester,
  ) async {
    await _open(tester);
    await tester.tap(find.text(trialMeetingQuestion));
    await tester.pumpAndSettle();
    final full = _answerHeight(tester);

    await tester.tap(find.text(trialMeetingQuestion));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_answerHeight(tester), lessThan(full));
    await tester.pumpAndSettle();

    expect(find.byKey(_picture), findsNothing);
    expect(find.text(trialMeetingLead), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('물음을 눌러 펼치면 스크린 리더가 답 한 줄을 한 번 읽고, 접을 때는 읽지 않는다', (tester) async {
    await _open(tester);
    tester.takeAnnouncements();

    await tester.tap(find.text(trialMeetingQuestion));
    await tester.pumpAndSettle();
    expect(tester.takeAnnouncements().map((a) => a.message), [
      trialMeetingLead,
    ]);

    await tester.tap(find.text(trialMeetingQuestion));
    await tester.pumpAndSettle();
    expect(tester.takeAnnouncements(), isEmpty);
  });
}
