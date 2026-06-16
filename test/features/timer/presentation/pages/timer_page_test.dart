import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/pages/timer_page.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/timer_fixtures.dart';

const _confirmTitle = '타이머 종료';
const _confirmContent = '정말 종료하시겠습니까?\n정지할 경우 다시 시작이 불가합니다.\n일시 정지를 이용해 주세요.';

void main() {
  group('TimerPage stop confirmation', () {
    testWidgets('정지 버튼을 탭하면 확인 다이얼로그를 표시한다', (tester) async {
      final timer = makeTimer(id: 'timer-1', status: TimerStatus.running);
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: timer, controller: controller);

      await tester.tap(_dashboardFabByIcon(Icons.stop));
      await tester.pumpAndSettle();

      expect(find.text(_confirmTitle), findsOneWidget);
      expect(find.text(_confirmContent), findsOneWidget);
      expect(find.widgetWithText(TextButton, '취소'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '종료'), findsOneWidget);
    });

    testWidgets('취소를 탭하면 다이얼로그를 닫고 정지하지 않는다', (tester) async {
      final timer = makeTimer(id: 'timer-1', status: TimerStatus.running);
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: timer, controller: controller);

      await tester.tap(_dashboardFabByIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await tester.pumpAndSettle();

      expect(find.text(_confirmTitle), findsNothing);
      expect(controller.stopCalled, isFalse);
    });

    testWidgets('종료를 탭하면 정지하고 새 타이머 시작 액션을 표시한다', (tester) async {
      final timer = makeTimer(id: 'timer-1', status: TimerStatus.running);
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: timer, controller: controller);

      await tester.tap(_dashboardFabByIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '종료'));
      await tester.pumpAndSettle();

      expect(controller.stopCalled, isTrue);
      expect(controller.stoppedTimerId, isNull);
      expect(find.text('타이머가 정지되었습니다'), findsOneWidget);
      expect(find.text('새 타이머 시작'), findsOneWidget);
    });

    testWidgets('RUNNING 상태에서 일시정지는 큰 FAB이고 정지는 작은 FAB이다', (tester) async {
      final timer = makeTimer(id: 'timer-1', status: TimerStatus.running);
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: timer, controller: controller);

      final stopSize = tester.getSize(_dashboardFabByIcon(Icons.stop));
      final pauseSize = tester.getSize(_dashboardFabByIcon(Icons.pause));

      expect(pauseSize.width, greaterThan(stopSize.width));
      expect(pauseSize.height, greaterThan(stopSize.height));
    });

    testWidgets('PAUSED 상태에서 재개는 큰 FAB이고 정지는 작은 FAB이다', (tester) async {
      final timer = makeTimer(id: 'timer-1', status: TimerStatus.paused);
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: timer, controller: controller);

      final stopSize = tester.getSize(_dashboardFabByIcon(Icons.stop));
      final resumeSize = tester.getSize(_dashboardFabByIcon(Icons.play_arrow));

      expect(resumeSize.width, greaterThan(stopSize.width));
      expect(resumeSize.height, greaterThan(stopSize.height));
    });

    testWidgets('히스토리 목록 정지 버튼도 확인 다이얼로그를 거친다', (tester) async {
      final timer = makeTimer(id: 'timer-1', status: TimerStatus.running);
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: timer, controller: controller);

      await tester.tap(_historyStopButton());
      await tester.pumpAndSettle();

      expect(find.text(_confirmTitle), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await tester.pumpAndSettle();

      expect(controller.stopCalled, isFalse);
    });

    testWidgets('히스토리 목록 정지 실패 시 SnackBar를 표시한다', (tester) async {
      final timer = makeTimer(id: 'timer-1', status: TimerStatus.running);
      final controller = _FakeTimerController(stopError: Exception('failed'));

      await _pumpTimerPage(tester, timer: timer, controller: controller);

      await tester.tap(_historyStopButton());
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '종료'));
      await tester.pumpAndSettle();

      expect(controller.stopCalled, isTrue);
      expect(controller.stoppedTimerId, timer.id);
      expect(find.text('타이머 정지 실패: Exception: failed'), findsOneWidget);
    });
  });
}

Future<void> _pumpTimerPage(
  WidgetTester tester, {
  required TimerRead timer,
  required _FakeTimerController controller,
}) async {
  await tester.pumpWidget(
    pumpApp(
      const TimerPage(),
      overrides: _timerOverrides(timer: timer, controller: controller),
    ),
  );
  await tester.pumpAndSettle();
}

List<Override> _timerOverrides({
  required TimerRead timer,
  required _FakeTimerController controller,
}) {
  return [
    activeTimerProvider.overrideWith((ref) => Stream<TimerRead?>.value(timer)),
    timerHistoryProvider.overrideWith(
      (ref) => Future.value(<TimerRead>[timer]),
    ),
    timerTickerProvider.overrideWith((ref) => Stream.value(Duration.zero)),
    timerControllerProvider.overrideWith(() => controller),
  ];
}

Finder _dashboardFabByIcon(IconData icon) {
  final iconInFab = find.descendant(
    of: find.byType(FloatingActionButton),
    matching: find.byIcon(icon),
  );
  return find.ancestor(
    of: iconInFab,
    matching: find.byType(FloatingActionButton),
  );
}

Finder _historyStopButton() {
  final iconInButton = find.descendant(
    of: find.byType(IconButton),
    matching: find.byIcon(Icons.stop),
  );
  return find.ancestor(of: iconInButton, matching: find.byType(IconButton));
}

class _FakeTimerController extends TimerController {
  _FakeTimerController({this.stopError});

  final Object? stopError;
  bool stopCalled = false;
  String? stoppedTimerId;

  @override
  FutureOr<void> build() {}

  @override
  Future<void> stopTimer({String? timerId}) async {
    stopCalled = true;
    stoppedTimerId = timerId;
    final error = stopError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> pauseTimer({String? timerId}) async {}

  @override
  Future<void> resumeTimer({String? timerId}) async {}

  @override
  Future<void> startTimer({
    String? relatedTodoId,
    String? title,
    String? scheduleId,
    int? allocatedDurationSeconds,
  }) async {}
}
