import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/meeting.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_section.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_name_chip.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slots_panel.dart';
import 'package:momeet/features/trial/presentation/utils/trial_samples.dart';
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_meeting_preview.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:timezone/data/latest.dart' as tz;

final _board = trialMeeting(trialStart(DateTime(2026, 11, 25, 10)));

/// [size] 칸에 견본 모임의 그림을 둔다
Future<void> _open(
  WidgetTester tester, {
  Size size = const Size(180, 450),
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox.fromSize(
            size: size,
            child: TrialMeetingPreview(board: _board, email: trialMeetingEmail),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('ko');
  });

  testWidgets('모임 화면을 앱의 위젯으로 그려 칸의 폭에 맞게 줄인다', (tester) async {
    await _open(tester);

    for (final type in [
      MeetingGlassBar,
      MeetingPageTitle,
      MeetingMemberBodyView,
      MeetingAvailabilitySection,
      MeetingSlotsPanel,
      MeetingParticipantsPanel,
      MeetingLinkPanelView,
    ]) {
      expect(find.byType(type), findsOneWidget, reason: '$type');
    }
    expect(find.text(_board.meeting.title), findsOneWidget);
    // 주인에게만 있는 모임 설정 연필
    expect(
      find.descendant(
        of: find.byType(MeetingPageTitle),
        matching: find.byIcon(Icons.edit_outlined),
      ),
      findsOneWidget,
    );
    for (final participant in _board.participants) {
      expect(
        find.text(participant.displayName),
        findsWidgets,
        reason: participant.displayName,
      );
    }
    expect(find.text('$trialMeetingEmail 계정으로 진행 중입니다'), findsOneWidget);
    expect(tester.getRect(find.byType(MeetingGlassBar)).width, 180);
    expect(tester.takeException(), isNull);
  });

  testWidgets('첫 추천 시간을 누른 채로 두어 함께 되는 사람의 이름을 카드에 펼친다', (tester) async {
    await _open(tester);

    final chips = find.descendant(
      of: find.byType(MeetingSlotsPanel),
      matching: find.byType(MeetingNameChip),
    );
    expect(chips, findsNWidgets(_board.participants.length));
  });

  testWidgets('칸이 낮으면 화면의 위쪽만 넘치지 않게 보인다', (tester) async {
    await _open(tester, size: const Size(240, 200));

    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.byType(MeetingGlassBar)).width, 240);
  });

  testWidgets('그림 속 글과 컨트롤을 누르거나 길게 눌러도 그림이 바뀌지 않는다', (tester) async {
    await _open(tester);
    final chips = find.byType(MeetingNameChip).evaluate().length;
    final picture = tester.getRect(find.byType(TrialMeetingPreview));
    final targets = [
      for (final element in [
        ...find.byType(Text).evaluate(),
        ...find.byType(Icon).evaluate(),
      ])
        tester.getRect(find.byElementPredicate((e) => identical(e, element))),
    ].where((rect) => picture.contains(rect.center));

    for (final rect in targets) {
      await tester.tapAt(rect.center);
      await tester.longPressAt(rect.center);
      await tester.pumpAndSettle();
    }

    // 펼친 첫 추천 시간이 그대로고, 일정 참여자의 편집도 열리지 않았다
    expect(find.byType(MeetingNameChip).evaluate(), hasLength(chips));
    expect(find.text('완료'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Tab·Shift+Tab으로 그림 안에 포커스가 들어가지 않는다', (tester) async {
    await _open(tester);

    for (final reverse in [false, true]) {
      for (var i = 0; i < 6; i++) {
        if (reverse) await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        if (reverse) await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pump();
        final focused = FocusManager.instance.primaryFocus?.context;
        expect(
          focused != null &&
              find
                  .ancestor(
                    of: find.byElementPredicate((e) => identical(e, focused)),
                    matching: find.byType(TrialMeetingPreview),
                  )
                  .evaluate()
                  .isNotEmpty,
          isFalse,
        );
      }
    }
  });

  testWidgets('스크린 리더에는 그림 한 줄로만 읽히고 누르기 동작이 없다', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);

    expect(
      find.semantics.byPredicate(
        (node) => node.getSemanticsData().label == trialMeetingPreviewLabel,
      ),
      findsOne,
    );
    expect(
      find.semantics.byPredicate(
        (node) => node.getSemanticsData().label.contains(_board.meeting.title),
      ),
      findsNothing,
    );
    expect(
      find.semantics.byPredicate((node) {
        final data = node.getSemanticsData();
        return data.hasAction(SemanticsAction.tap) ||
            data.hasAction(SemanticsAction.longPress);
      }),
      findsNothing,
    );
    semantics.dispose();
  });

  testWidgets('다 그린 뒤에는 더 그릴 프레임을 남기지 않는다', (tester) async {
    await _open(tester);

    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
