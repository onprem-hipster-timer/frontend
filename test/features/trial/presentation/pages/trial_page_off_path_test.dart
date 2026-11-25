import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_month_cell_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_view.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_status_selector_view.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_timer_start_button_view.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/editable_todo_tree_tile_view.dart';
import 'package:momeet/features/trial/domain/trial_flow.dart';
import 'package:momeet/features/trial/presentation/utils/trial_samples.dart';
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_meeting_preview.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';

import '../../../../helpers/start_timer_sheet_driver.dart';
import '../../trial_harness.dart';

/// 만든 프로바이더를 모두 적는다
final class _Created extends ProviderObserver {
  final providers = <String>[];

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) =>
      providers.add('${context.provider}');
}

/// 시트·대화상자·메뉴·알림이 하나도 없다
void _expectNothingOpened() {
  expect(find.byType(BottomSheet), findsNothing);
  expect(find.byType(Dialog), findsNothing);
  expect(find.byType(PopupMenuItem<TodoStatus>), findsNothing);
  expect(find.byType(SnackBar), findsNothing);
}

/// 지금 키보드 포커스가 [finder] 안에 있다
bool _focusWithin(Finder finder) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  return find
      .ancestor(
        of: find.byElementPredicate((element) => identical(element, focused)),
        matching: finder,
      )
      .evaluate()
      .isNotEmpty;
}

/// 머리띠의 홈으로와 건너뛰기. 누르면 체험을 떠난다
bool _focusOnHeader() =>
    _focusWithin(find.byTooltip('홈으로')) ||
    _focusWithin(
      find.ancestor(
        of: find.text(trialSkip),
        matching: find.byType(TextButton),
      ),
    );

/// Tab(뒤로면 Shift+Tab)을 한 번 누른다
Future<void> _tab(WidgetTester tester, {bool reverse = false}) async {
  if (reverse) await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  if (reverse) await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  await tester.pump();
}

/// Enter와 Space를 누른다
Future<void> _press(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.sendKeyEvent(LogicalKeyboardKey.space);
  await tester.pump();
}

/// 스크린 리더가 읽는 [tooltip] 노드
SemanticsFinder _semanticsByTooltip(String tooltip) =>
    find.semantics.byPredicate((node) => node.tooltip == tooltip);

/// [node]가 누르기·길게 누르기 동작을 내놓는다
bool _pressable(SemanticsFinder node) {
  final data = node.evaluate().single.getSemanticsData();
  return data.hasAction(SemanticsAction.tap) ||
      data.hasAction(SemanticsAction.longPress);
}

/// 스크린 리더로 [node]를 누르고 길게 누른다
void _pressBySemantics(WidgetTester tester, SemanticsFinder node) {
  for (final action in [SemanticsAction.tap, SemanticsAction.longPress]) {
    tester.semantics.performAction(node, action, checkForAction: false);
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  group('길 밖의 것은 반응하지 않는다', () {
    testWidgets('달력에서 약속 날짜를 눌러도 시트가 열리지 않고 달력에 머문다', (tester) async {
      await openTrial(tester);

      await tapCalendarDay(tester, trialTestDinnerDay);
      _expectNothingOpened();
      // 앱처럼 누른 날을 고르고 월 보기에 머문다
      expect(find.byType(CalendarMonthCellView), findsWidgets);

      await tester.tap(find.text(trialDinnerTitle));
      await tester.pumpAndSettle();

      _expectNothingOpened();
      expect(find.byType(CalendarMonthCellView), findsWidgets);
      expect(headlineOf(TrialStep.calendar), findsOneWidget);
    });

    testWidgets('일정 상세 단계에서는 수정과 삭제를 누를 수 없다', (tester) async {
      await openTrial(tester);
      await goToSchedule(tester);

      for (final label in ['수정', '삭제']) {
        final button = find.ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate(
            (widget) => widget is ButtonStyleButton,
          ),
        );
        expect(
          tester.widget<ButtonStyleButton>(button).enabled,
          isFalse,
          reason: label,
        );
      }
      expect(find.text(convertLabel), findsOneWidget);
    });

    testWidgets('할 일 단계에서는 수정과 삭제를 누를 수 없다', (tester) async {
      await openTrial(tester);
      await goToTodo(tester);

      for (final label in ['수정', '삭제']) {
        final button = tester.widget<ButtonStyleButton>(
          find.ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate(
              (widget) => widget is ButtonStyleButton,
            ),
          ),
        );
        expect(button.enabled, isFalse, reason: label);
      }
    });

    testWidgets('할 일 단계에서 상태·수정·삭제·줄을 눌러도 아무것도 열리지 않는다', (tester) async {
      await openTrial(tester);
      await goToTodo(tester);

      await tester.tap(
        find.byType(TodoStatusSelectorView),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('수정'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(EditableTodoTreeTileView));
      await tester.pumpAndSettle();

      _expectNothingOpened();
      expect(headlineOf(TrialStep.todo), findsOneWidget);
    });

    testWidgets('타이머 단계에서 공유 설정이나 완료를 눌러도 시트가 열리지 않고 3초에 끝난다', (tester) async {
      await openTrial(tester);
      await goToTimer(tester);
      await tester.pump(const Duration(milliseconds: 500));

      for (final tooltip in ['공유 설정', Terms.complete]) {
        expect(find.byTooltip(tooltip), findsOneWidget);
        // 새 단계로 굴리는 동안은 누를 수 없으므로 다 굴린 뒤 누른다
        await tester.ensureVisible(find.byTooltip(tooltip));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.byTooltip(tooltip), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(BottomSheet), findsNothing, reason: tooltip);
      }
      expect(find.byType(TimerDashboardView), findsOneWidget);

      // 멈추지 않고 3초에 끝난다
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pumpAndSettle();
      expect(headlineOf(TrialStep.end), findsOneWidget);
    });

    testWidgets('끝 화면에서 펼친 모임 화면 그림의 글과 컨트롤을 누르거나 길게 눌러도 아무것도 열리지 않고 끝에 머문다', (
      tester,
    ) async {
      final created = _Created();
      await openTrial(tester, observers: [created]);
      await goToEnd(tester);
      await openMeetingAnswer(tester);
      final picture = find.byType(TrialMeetingPreview);
      final shown = Offset.zero & tester.view.physicalSize;
      final targets = [
        for (final element
            in find
                .descendant(
                  of: picture,
                  matching: find.byWidgetPredicate(
                    (w) => w is Text || w is Icon,
                  ),
                )
                .evaluate())
          tester
              .getRect(find.byElementPredicate((e) => identical(e, element)))
              .center,
        tester.getCenter(picture),
      ].where(shown.contains);
      expect(targets, isNotEmpty);

      for (final target in targets) {
        await tester.tapAt(target);
        await tester.longPressAt(target);
        await tester.pumpAndSettle();
      }

      _expectNothingOpened();
      expect(headlineOf(TrialStep.end), findsOneWidget);
      expect(find.text(meetingsScreen), findsNothing);
      expect(created.providers, isEmpty);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('키보드와 스크린 리더로도 길 밖의 것은 반응하지 않는다', () {
    final cases = {
      'Tab': (reverse: false, size: const Size(360, 800)),
      'Shift+Tab': (reverse: true, size: const Size(360, 800)),
      '작은 휴대폰(320×568)에서 Tab': (reverse: false, size: const Size(320, 568)),
    };
    for (final MapEntry(key: label, value: (:reverse, :size))
        in cases.entries) {
      testWidgets(
        '타이머 단계에서 $label으로 돌며 Enter·Space를 눌러도 대시보드에는 닿지 않고 아무것도 열리지 않은 채 3초에 끝난다',
        (tester) async {
          final created = _Created();
          await openTrial(tester, size: size, observers: [created]);
          await goToTimer(tester);
          await tester.pump(const Duration(milliseconds: 500));

          var reachedDashboard = 0;
          for (var i = 0; i < 12; i++) {
            await _tab(tester, reverse: reverse);
            if (_focusWithin(find.byType(TimerDashboardView))) {
              reachedDashboard++;
            }
            if (!_focusOnHeader()) await _press(tester);
          }
          expect(headlineOf(TrialStep.timer), findsOneWidget);

          await tester.pump(trialTimerSweep);
          await tester.pumpAndSettle();
          expect(headlineOf(TrialStep.end), findsOneWidget);
          _expectNothingOpened();
          expect(created.providers, isEmpty);
          expect(reachedDashboard, 0);
        },
      );
    }

    testWidgets('할 일 단계에서 Tab으로 돌면 상태는 건너뛰고 타이머 시작에 닿아 Enter로 새 작업 시트가 열린다', (
      tester,
    ) async {
      await openTrial(tester);
      await goToTodo(tester);
      final start = find.byType(TodoTimerStartButtonView);

      var reachedStatus = 0;
      var reachedStart = false;
      for (var i = 0; i < 10; i++) {
        await _tab(tester);
        if (_focusWithin(find.byType(TodoStatusSelectorView))) reachedStatus++;
        if (_focusWithin(start)) {
          reachedStart = true;
        } else if (!_focusOnHeader()) {
          await _press(tester);
          await tester.pumpAndSettle();
          _expectNothingOpened();
        }
      }
      expect(reachedStatus, 0);
      expect(reachedStart, isTrue);

      while (!_focusWithin(start)) {
        await _tab(tester);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(StartSheet.sheet, findsOneWidget);
    });

    testWidgets('타이머 단계의 공유 설정과 완료는 스크린 리더에 읽히지만 누르기 동작이 없고, 보내도 시트가 열리지 않는다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final created = _Created();
      await openTrial(tester, observers: [created]);
      await goToTimer(tester);
      await tester.pump(const Duration(milliseconds: 500));

      for (final tooltip in ['공유 설정', Terms.complete]) {
        final node = _semanticsByTooltip(tooltip);
        expect(node, findsOne, reason: tooltip);
        expect(_pressable(node), isFalse, reason: tooltip);
        _pressBySemantics(tester, node);
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(BottomSheet), findsNothing, reason: tooltip);
      }

      await tester.pump(trialTimerSweep);
      await tester.pumpAndSettle();
      expect(headlineOf(TrialStep.end), findsOneWidget);
      _expectNothingOpened();
      expect(created.providers, isEmpty);
      semantics.dispose();
    });

    testWidgets('할 일 단계의 상태는 스크린 리더로 눌러도 메뉴가 열리지 않고, 타이머 시작은 눌러 시트를 연다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await openTrial(tester);
      await goToTodo(tester);

      final status = _semanticsByTooltip(
        MaterialLocalizations.of(
          tester.element(find.byType(TodoStatusSelectorView)),
        ).showMenuTooltip,
      );
      // 상태는 줄의 노드에 합쳐 읽히고, 그 노드의 누르기는 줄의 것이다
      expect(status, findsOne);
      _pressBySemantics(tester, status);
      await tester.pumpAndSettle();
      _expectNothingOpened();

      final start = _semanticsByTooltip('${Terms.timer} 시작');
      expect(_pressable(start), isTrue);
      tester.semantics.tap(start);
      await tester.pumpAndSettle();
      expect(StartSheet.sheet, findsOneWidget);
      semantics.dispose();
    });

    const arrows = [
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
    ];

    testWidgets('타이머 단계에서 방향키로 포커스를 옮겨도 대시보드에 닿지 않는다', (tester) async {
      await openTrial(tester);
      await goToTimer(tester);
      await tester.pump(const Duration(milliseconds: 500));

      // 머리띠의 단추에서 시작한다
      await _tab(tester);
      for (final key in arrows) {
        await tester.sendKeyEvent(key);
        await tester.pump();
        expect(_focusWithin(find.byType(TimerDashboardView)), isFalse);
        if (!_focusOnHeader()) await _press(tester);
      }

      await tester.pump(trialTimerSweep);
      await tester.pumpAndSettle();
      _expectNothingOpened();
    });

    testWidgets('할 일 단계에서 방향키로 포커스를 옮겨도 상태에 닿지 않는다', (tester) async {
      await openTrial(tester);
      await goToTodo(tester);

      await _tab(tester);
      for (final key in arrows) {
        await tester.sendKeyEvent(key);
        await tester.pump();
        expect(_focusWithin(find.byType(TodoStatusSelectorView)), isFalse);
      }
      expect(find.byType(PopupMenuItem<TodoStatus>), findsNothing);
    });

    testWidgets(
      '끝 화면에서 Tab으로 물음에 닿아 Enter로 펼치고 Space로 접었다 펼치며, 돌아도 그림에는 닿지 않고 모임 만들기는 Enter로 열린다',
      (tester) async {
        await openTrial(tester);
        await goToEnd(tester);
        final picture = find.byType(TrialMeetingPreview);
        final question = find.ancestor(
          of: meetingQuestion,
          matching: find.byType(TextButton),
        );
        final action = find.ancestor(
          of: find.text(trialMeetingAction),
          matching: find.byType(TextButton),
        );

        while (!_focusWithin(question)) {
          await _tab(tester);
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(picture, findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(picture, findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(picture, findsOneWidget);

        var reachedAction = false;
        for (final reverse in [false, true]) {
          for (var i = 0; i < 12; i++) {
            await _tab(tester, reverse: reverse);
            expect(_focusWithin(picture), isFalse);
            if (_focusWithin(action)) reachedAction = true;
          }
        }
        for (final key in arrows) {
          await tester.sendKeyEvent(key);
          await tester.pump();
          expect(_focusWithin(picture), isFalse);
        }
        expect(reachedAction, isTrue);

        while (!_focusWithin(action)) {
          await _tab(tester);
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.text(meetingsScreen), findsOneWidget);
      },
    );

    testWidgets(
      '끝 화면의 물음은 스크린 리더로 눌러 펼치고, 펼친 그림은 한 줄로 읽히며 누르기 동작이 없고, 모임 만들기는 스크린 리더로 눌러 연다',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await openTrial(tester);
        await goToEnd(tester);

        // 물음의 버튼과 펼친 상태는 한 노드로 합쳐 읽힌다
        final question = find.semantics.byPredicate(
          (node) =>
              !node.isMergedIntoParent &&
              node.getSemanticsData().label == trialMeetingQuestion,
        );
        expect(_pressable(question), isTrue);
        expect(
          question
              .evaluate()
              .single
              .getSemanticsData()
              .flagsCollection
              .isExpanded,
          Tristate.isFalse,
        );
        expect(find.byType(TrialMeetingPreview), findsNothing);
        tester.semantics.tap(question);
        await tester.pumpAndSettle();
        expect(
          question
              .evaluate()
              .single
              .getSemanticsData()
              .flagsCollection
              .isExpanded,
          Tristate.isTrue,
        );

        final picture = find.semantics.byPredicate(
          (node) => node.getSemanticsData().label == trialMeetingPreviewLabel,
        );
        expect(picture, findsOne);
        expect(_pressable(picture), isFalse);
        _pressBySemantics(tester, picture);
        await tester.pumpAndSettle();
        _expectNothingOpened();
        expect(headlineOf(TrialStep.end), findsOneWidget);
        // 그림 속 모임 화면의 글(계정·참여자 이름)은 따로 읽히지 않는다. 물음은 약속 제목에 친구 이름이 들어 있어 뺀다
        final inPicture = [
          trialMeetingEmail,
          for (final participant in trialMeeting(
            trialStart(trialTestNow),
          ).participants)
            participant.displayName,
        ];
        for (final text in inPicture) {
          expect(
            find.semantics.byPredicate((node) {
              final label = node.getSemanticsData().label;
              return label != trialMeetingQuestion && label.contains(text);
            }),
            findsNothing,
            reason: text,
          );
        }

        final action = find.semantics.byPredicate(
          (node) => node.getSemanticsData().label == trialMeetingAction,
        );
        expect(_pressable(action), isTrue);
        tester.semantics.tap(action);
        await tester.pumpAndSettle();
        expect(find.text(meetingsScreen), findsOneWidget);
        semantics.dispose();
      },
    );

    final steps = <String, Future<void> Function(WidgetTester)>{
      '달력 단계': (_) async {},
      '일정 상세 단계': goToSchedule,
      '할 일 단계': goToTodo,
      '타이머 단계': goToTimer,
      '끝 화면': goToEnd,
    };
    for (final MapEntry(key: step, value: reach) in steps.entries) {
      for (final MapEntry(key: screen, value: size) in trialSizes.entries) {
        testWidgets(
          '$step($screen)부터 Tab으로 닿는 것을 모두 Enter·Space로 눌러도 공유 설정과 상태 메뉴가 열리지 않고 앱의 프로바이더가 만들어지지 않는다',
          (tester) async {
            final created = _Created();
            await openTrial(tester, size: size, observers: [created]);
            await reach(tester);

            // 누른 것이 체험을 앞으로 넘기면 넘어간 단계에서 이어 누른다
            for (var i = 0; i < 40; i++) {
              await _tab(tester);
              expect(_focusWithin(find.byType(TrialMeetingPreview)), isFalse);
              if (_focusOnHeader()) continue;
              await _press(tester);
              await tester.pump(const Duration(milliseconds: 400));
              expect(find.text('공유 설정'), findsNothing);
              expect(find.byType(PopupMenuItem<TodoStatus>), findsNothing);
            }
            expect(created.providers, isEmpty);
          },
        );
      }
    }
  });

  group('건너뛰기', () {
    final steps = <String, Future<void> Function(WidgetTester)>{
      '달력 단계': (_) async {},
      '일정 상세 단계': goToSchedule,
      '할 일 단계': goToTodo,
      '새 작업 시트를 취소한 할 일 단계': (tester) async {
        await goToTodo(tester);
        await tester.tap(find.byTooltip('${Terms.timer} 시작'));
        await tester.pumpAndSettle();
        await tester.tap(StartSheet.cancelButton);
        await tester.pumpAndSettle();
      },
      '타이머 단계': (tester) async {
        await goToTimer(tester);
        await tester.pump(const Duration(milliseconds: 500));
      },
    };
    for (final MapEntry(key: label, value: reach) in steps.entries) {
      testWidgets('$label에서 건너뛰기를 누르면 회원가입 화면으로 가고 알림이 남지 않는다', (tester) async {
        await openTrial(tester);
        await reach(tester);

        await tester.tap(find.text(trialSkip));
        await tester.pumpAndSettle();

        expect(find.text(signupScreen), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
      });
    }

    testWidgets('끝 화면에는 건너뛰기와 단계 표시가 없다', (tester) async {
      await openTrial(tester);
      await goToEnd(tester);

      expect(find.text(trialSkip), findsNothing);
      expect(find.textContaining('/$trialStepCount'), findsNothing);
    });
  });

  testWidgets('체험을 끝까지 따라가 가입하기를 눌러도 앱의 프로바이더는 하나도 만들어지지 않는다', (tester) async {
    // 체험은 프로바이더를 덮어쓰지 않으므로 허용 목록이 비어 있다
    const allowed = <String>{};
    final created = _Created();
    await openTrial(tester, observers: [created]);

    await goToEnd(tester);
    await tester.ensureVisible(find.text(trialSignUp));
    await tester.tap(find.text(trialSignUp));
    await tester.pumpAndSettle();

    expect(find.text(signupScreen), findsOneWidget);
    expect(created.providers.where((p) => !allowed.contains(p)), isEmpty);
  });
}
