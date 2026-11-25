import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view_view.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_detail_body.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_list_sheet.dart';
import 'package:momeet/features/timer/presentation/widgets/start_timer_sheet_view.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_view.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_status_selector_view.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/editable_todo_tree_tile_view.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_elapsed_badge_view.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_tag_indicators.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_tree_tile_view.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_timer_chip_view.dart';
import 'package:momeet/features/meeting/meeting.dart'
    show MeetingMemberBodyView, MeetingParticipantsPanel;
import 'package:momeet/features/meeting/presentation/widgets/meeting_slots_panel.dart';
import 'package:momeet/features/trial/domain/trial_flow.dart';
import 'package:momeet/features/trial/presentation/utils/trial_samples.dart';
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_meeting_preview.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_timer_dashboard.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';

import '../../../../helpers/start_timer_sheet_driver.dart';
import '../../trial_harness.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  for (final MapEntry(key: label, value: size) in trialSizes.entries) {
    group(label, () {
      testWidgets('달력부터 앱의 위젯을 차례로 누르면 끝까지 간다', (tester) async {
        await openTrial(tester, size: size);

        // 1. 달력: 시험과 약속이 든 앱의 달력
        expect(headlineOf(TrialStep.calendar), findsOneWidget);
        expect(find.text(trialStepLabel(1)), findsOneWidget);
        expect(find.byType(CalendarViewWidgetView), findsOneWidget);
        expect(find.text(trialExamTitle), findsOneWidget);
        expect(find.text(trialDinnerTitle), findsOneWidget);

        // 시험 날짜를 누르면 앱의 그날 일정 목록 시트
        await tapCalendarDay(tester, trialTestExamDay);
        expect(find.byType(ScheduleListSheet), findsOneWidget);
        expect(find.text('12월 2일 (수)'), findsOneWidget);

        // 2. 시트의 시험을 누르면 시트를 닫고 일정 상세
        await tester.tap(
          find.descendant(
            of: find.byType(ScheduleListSheet),
            matching: find.text(trialExamTitle),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ScheduleListSheet), findsNothing);
        expect(headlineOf(TrialStep.schedule), findsOneWidget);
        expect(find.text(trialStepLabel(2)), findsOneWidget);
        expect(find.byType(ScheduleDetailBody), findsOneWidget);
        expect(find.text(trialExamDescription), findsOneWidget);
        expect(find.text(linkedLabel), findsNothing);

        // 변환하면 앱의 알림이 뜨고 버튼이 '연결된 할 일 보기'로 바뀌며, 한 줄이 다음에 누를 것을 말한다
        tester.takeAnnouncements();
        await tester.tap(find.text(convertLabel));
        await tester.pumpAndSettle();
        expect(
          find.widgetWithText(
            SnackBar,
            '${Terms.todo.withJosa('으로', '로')} 변환되었습니다',
          ),
          findsOneWidget,
        );
        expect(find.text(linkedLabel), findsOneWidget);
        expect(find.text(convertLabel), findsNothing);
        expect(headlineOf(TrialStep.schedule), findsNothing);
        expect(convertedHeadline, findsOneWidget);
        expect(
          tester.takeAnnouncements().map((a) => a.message),
          contains(trialConvertedHeadline),
        );

        // 3. 알림의 '할 일 보기'를 누르면 바꾼 할 일
        await tester.tap(
          find.widgetWithText(SnackBarAction, '${Terms.todo} 보기'),
        );
        await tester.pumpAndSettle();
        expect(headlineOf(TrialStep.todo), findsOneWidget);
        expect(find.text(trialStepLabel(3)), findsOneWidget);
        expect(
          find.widgetWithText(EditableTodoTreeTileView, trialExamTitle),
          findsOneWidget,
        );
        expect(find.byType(SnackBar), findsNothing);

        // ▶를 누르면 이 할 일을 고르고 기본 집중 시간을 채운 앱의 새 작업 시트
        await tester.tap(find.byTooltip('${Terms.timer} 시작'));
        await tester.pumpAndSettle();
        expect(find.byType(StartTimerSheetView), findsOneWidget);
        expect(StartSheet.todoShows(trialExamTitle), findsOneWidget);
        expect(
          tester.widget<TextField>(StartSheet.minutesField).controller!.text,
          '25',
        );

        // 시작하면 할 일에 머물며 남은 시간을 보이고 앱의 알림을 띄우며, 한 줄이 다음에 누를 것을 말한다
        tester.takeAnnouncements();
        await tester.tap(StartSheet.startButton);
        await tester.pumpAndSettle();
        expect(find.byType(StartTimerSheetView), findsNothing);
        expect(headlineOf(TrialStep.todo), findsNothing);
        expect(startedHeadline, findsOneWidget);
        expect(
          tester.takeAnnouncements().map((a) => a.message),
          contains(trialStartedHeadline),
        );
        expect(
          find.widgetWithText(SnackBar, '${Terms.timer}를 시작했습니다'),
          findsOneWidget,
        );
        expect(
          tester.widget<TodoTimerChipView>(find.byType(TodoTimerChipView)),
          isA<TodoTimerChipView>().having(
            (chip) => chip.remainingSeconds,
            '남은 초',
            1500,
          ),
        );
        expect(find.byTooltip('${Terms.timer} 시작'), findsNothing);

        // 4. 알림의 '타이머 보기'를 누르면 앱의 타이머 대시보드. 25분이 3초 만에 지나간다
        await tester.tap(
          find.widgetWithText(SnackBarAction, '${Terms.timer} 보기'),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1500));
        expect(headlineOf(TrialStep.timer), findsOneWidget);
        expect(find.text(trialStepLabel(4)), findsOneWidget);
        expect(find.byType(TimerDashboardView), findsOneWidget);
        final half = tester
            .widget<TrialTimerDashboard>(find.byType(TrialTimerDashboard))
            .remaining;
        expect(half.inSeconds, inInclusiveRange(700, 800));

        await tester.pump(const Duration(milliseconds: 1400));
        expect(headlineOf(TrialStep.timer), findsOneWidget);

        // 3초가 다 지나면 스스로 끝으로 간다
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        expect(headlineOf(TrialStep.end), findsOneWidget);
        expect(find.text(trialStepLabel(4)), findsNothing);
        expect(find.text(trialSkip), findsNothing);

        // 끝: 완료한 할 일이 읽기만 하는 줄로 남고 집중한 25분을 보인다
        expect(find.byType(EditableTodoTreeTileView), findsNothing);
        expect(
          find.widgetWithText(TodoTreeTileView, trialExamTitle),
          findsOneWidget,
        );
        expect(find.text('수정'), findsNothing);
        expect(find.text('삭제'), findsNothing);
        expect(find.byType(TodoTagIndicators), findsOneWidget);
        final badge = tester.widget<TodoElapsedBadgeView>(
          find.byType(TodoElapsedBadgeView),
        );
        expect(badge.finishedSeconds, 1500);
        expect(badge.activeSeconds, isNull);
        expect(find.text('00:25:00'), findsOneWidget);
        expect(find.byIcon(TodoStatus.done.icon), findsOneWidget);
        expect(find.text(trialSignUp), findsOneWidget);
        expect(find.text(trialMeetingAction), findsOneWidget);
      });

      testWidgets('끝에서 가입하기를 누르면 회원가입 화면으로 간다', (tester) async {
        await openTrial(tester, size: size);
        await goToEnd(tester);

        await tester.ensureVisible(find.text(trialSignUp));
        await tester.tap(find.text(trialSignUp));
        await tester.pumpAndSettle();
        expect(find.text(signupScreen), findsOneWidget);
      });

      testWidgets('끝에서 모임 만들기를 누르면 모임 만들기 화면으로 간다', (tester) async {
        await openTrial(tester, size: size);
        await goToEnd(tester);

        expectShown(tester, find.text(trialMeetingAction));
        await tester.tap(find.text(trialMeetingAction));
        await tester.pumpAndSettle();
        expect(find.text(meetingsScreen), findsOneWidget);
      });
    });
  }

  testWidgets('변환한 뒤 연결된 할 일 보기를 누르면 할 일 단계로 가고 떠 있던 알림이 닫힌다', (tester) async {
    await openTrial(tester);
    await goToSchedule(tester);
    await tester.tap(find.text(convertLabel));
    await tester.pumpAndSettle();

    await tester.tap(find.text(linkedLabel));
    await tester.pumpAndSettle();

    expect(headlineOf(TrialStep.todo), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('달력에서 시험 막대를 누르면 앱처럼 그날의 일정 목록이 열린다', (tester) async {
    await openTrial(tester);

    await tester.tap(find.text(trialExamTitle));
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleListSheet), findsOneWidget);
    expect(headlineOf(TrialStep.calendar), findsOneWidget);
  });

  testWidgets('새 작업 시트에서 취소를 누르면 타이머 없이 할 일 단계에 머문다', (tester) async {
    await openTrial(tester);
    await goToTodo(tester);
    await tester.tap(find.byTooltip('${Terms.timer} 시작'));
    await tester.pumpAndSettle();

    await tester.tap(StartSheet.cancelButton);
    await tester.pumpAndSettle();

    expect(headlineOf(TrialStep.todo), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byTooltip('${Terms.timer} 시작'), findsOneWidget);
  });

  testWidgets('타이머 시작 알림이 사라진 뒤에도 할 일 줄의 남은 시간을 누르면 타이머로 간다', (tester) async {
    await openTrial(tester);
    await goToTodo(tester);
    await startTimer(tester);
    // 이동 단추가 있는 알림은 저절로 닫히지 않으므로 아래로 밀어 닫는다
    await tester.drag(find.byType(SnackBar), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.byType(TodoTimerChipView));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(headlineOf(TrialStep.timer), findsOneWidget);
    await tester.pump(trialTimerSweep);
    await tester.pumpAndSettle();
    expect(headlineOf(TrialStep.end), findsOneWidget);
  });

  testWidgets('그날 일정 목록을 닫으면 달력에 머물고, 다시 열어 이어 갈 수 있다', (tester) async {
    await openTrial(tester);
    await tapCalendarDay(tester, trialTestExamDay);
    expect(find.byType(ScheduleListSheet), findsOneWidget);

    // 시트 바깥을 눌러 닫는다
    await tester.tapAt(const Offset(180, 40));
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleListSheet), findsNothing);
    expect(headlineOf(TrialStep.calendar), findsOneWidget);

    await goToSchedule(tester);
    expect(headlineOf(TrialStep.schedule), findsOneWidget);
  });

  testWidgets('작은 휴대폰(320×568)에서도 끝까지 따라갈 수 있다', (tester) async {
    await openTrial(tester, size: const Size(320, 568));
    await goToEnd(tester);

    expect(headlineOf(TrialStep.end), findsOneWidget);
    expectShown(tester, find.text(trialSignUp));
    await tester.tap(find.text(trialSignUp));
    await tester.pumpAndSettle();
    expect(find.text(signupScreen), findsOneWidget);
  });

  testWidgets('가로로 눕힌 휴대폰(844×390)에서는 새 작업 시트를 굴려 시작하고 끝까지 따라갈 수 있다', (
    tester,
  ) async {
    await openTrial(tester, size: const Size(844, 390));
    await goToTodo(tester);
    await tester.tap(find.byTooltip('${Terms.timer} 시작'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(StartSheet.startButton);
    await tester.pumpAndSettle();
    await tester.tap(StartSheet.startButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SnackBarAction, '${Terms.timer} 보기'));
    await tester.pump();
    await tester.pump(trialTimerSweep);
    await tester.pumpAndSettle();

    expect(headlineOf(TrialStep.end), findsOneWidget);
    expectShown(tester, find.text(trialSignUp));
    await tester.tap(find.text(trialSignUp));
    await tester.pumpAndSettle();
    expect(find.text(signupScreen), findsOneWidget);
  });

  testWidgets('끝 화면에서 모임 만들기는 가입하기 아래 구분선 밑의 글자 버튼이다', (tester) async {
    await openTrial(tester);
    await goToEnd(tester);

    expect(find.widgetWithText(FilledButton, trialSignUp), findsOneWidget);
    expect(find.widgetWithText(TextButton, trialMeetingAction), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, trialMeetingAction),
      findsNothing,
    );
    // 모임 화면 그림 속 구분선보다 앞에 있다
    final divider = tester.getTopLeft(find.byType(Divider).first).dy;
    expect(tester.getBottomLeft(find.text(trialSignUp)).dy, lessThan(divider));
    expect(
      tester.getTopLeft(find.text(trialMeetingAction)).dy,
      greaterThan(divider),
    );
  });

  group('끝 화면은 모임 만들기 줄과 함께 모임 화면 그림을 둔다', () {
    final sizes = {
      ...trialSizes,
      '작은 휴대폰': const Size(320, 568),
      '가로로 눕힌 휴대폰': const Size(844, 390),
    };
    for (final MapEntry(key: label, value: size) in sizes.entries) {
      testWidgets(
        '$label에서는 가입하기와 모임 만들기 줄이 굴리지 않아도 보이고, 줄 밑이나 옆에 앱의 모임 화면 그림이 있다',
        (tester) async {
          await openTrial(tester, size: size);
          await goToEnd(tester);

          expect(tester.takeException(), isNull);
          final board = trialMeeting(trialStart(trialTestNow));
          final lead = find.text(trialMeetingLead);
          final action = find.text(trialMeetingAction);
          expectShown(tester, find.text(trialSignUp));
          expectShown(tester, lead);
          expectShown(tester, action);

          final picture = find.byType(TrialMeetingPreview);
          expect(picture, findsOneWidget);
          for (final type in [
            MeetingMemberBodyView,
            MeetingSlotsPanel,
            MeetingParticipantsPanel,
          ]) {
            expect(
              find.descendant(of: picture, matching: find.byType(type)),
              findsOneWidget,
              reason: '$type',
            );
          }
          final inPicture = [
            trialDinnerTitle,
            for (final participant in board.participants)
              participant.displayName,
          ];
          for (final text in inPicture) {
            expect(
              find.descendant(of: picture, matching: find.text(text)),
              findsWidgets,
              reason: text,
            );
          }

          // 가입하기 아래 구분선 밑에서 줄과 같은 높이부터 시작하고, 넓은 화면에서도 작은 그림이다
          final rect = tester.getRect(picture);
          expect(
            rect.top,
            greaterThan(tester.getBottomLeft(find.text(trialSignUp)).dy),
          );
          expect(rect.top, greaterThanOrEqualTo(tester.getTopLeft(lead).dy));
          expect(rect.width, lessThanOrEqualTo(200));
          expect(tester.binding.hasScheduledFrame, isFalse);

          await tester.tap(action);
          await tester.pumpAndSettle();
          expect(find.text(meetingsScreen), findsOneWidget);
        },
      );
    }
  });

  testWidgets('변환한 뒤 1분이 지나도 할 일 보기가 있는 알림이 남아 있다', (tester) async {
    await openTrial(tester);
    await goToSchedule(tester);
    await tester.tap(find.text(convertLabel));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(SnackBarAction, '${Terms.todo} 보기'),
      findsOneWidget,
    );
  });

  testWidgets('타이머를 시작한 뒤 1분이 지나도 타이머 보기가 있는 알림이 남아 있다', (tester) async {
    await openTrial(tester);
    await goToTodo(tester);
    await startTimer(tester);

    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(SnackBarAction, '${Terms.timer} 보기'),
      findsOneWidget,
    );
  });
}
