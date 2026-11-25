import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_month_cell_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_view.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_status_selector_view.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/editable_todo_tree_tile_view.dart';
import 'package:momeet/features/trial/domain/trial_flow.dart';
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';
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
