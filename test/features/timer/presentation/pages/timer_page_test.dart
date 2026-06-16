import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/pages/timer_page.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/timer_fixtures.dart';

const _confirmTitle = '타이머 종료';
const _confirmContent = '정말 종료하시겠습니까?\n정지할 경우 다시 시작이 불가합니다.\n일시 정지를 이용해 주세요.';

void main() {
  TimerWsFriendActivity activity({
    String action = 'start',
    String? displayName,
    String? timerTitle,
  }) {
    return TimerWsFriendActivity(
      friendId: 'friend-1',
      action: action,
      timerId: 'timer-1',
      timerTitle: timerTitle,
      displayName: displayName,
    );
  }

  // ============================================================
  // friendActivityMessage — 문구 매핑 (순수 함수)
  // ============================================================
  group('friendActivityMessage', () {
    group('displayName 처리', () {
      test('displayName이 있으면 이름이 문구에 반영된다', () {
        final msg = friendActivityMessage(activity(displayName: '홍길동'));
        expect(msg, contains('홍길동님이'));
      });

      test('displayName이 null이면 "친구" fallback을 쓴다', () {
        final msg = friendActivityMessage(activity());
        expect(msg, startsWith('친구님이'));
      });

      test('displayName이 빈 문자열이면 "친구" fallback을 쓴다', () {
        final msg = friendActivityMessage(activity(displayName: '   '));
        expect(msg, startsWith('친구님이'));
      });
    });

    group('action별 문구', () {
      test('start', () {
        expect(
          friendActivityMessage(activity(action: 'start', displayName: '철수')),
          '철수님이 타이머를 시작했습니다',
        );
      });

      test('pause', () {
        expect(
          friendActivityMessage(activity(action: 'pause', displayName: '철수')),
          '철수님이 타이머를 일시정지했습니다',
        );
      });

      test('resume', () {
        expect(
          friendActivityMessage(activity(action: 'resume', displayName: '철수')),
          '철수님이 타이머를 재개했습니다',
        );
      });

      test('stop', () {
        expect(
          friendActivityMessage(activity(action: 'stop', displayName: '철수')),
          '철수님이 타이머를 정지했습니다',
        );
      });
    });

    group('미정의 action — generic fallback', () {
      test('공식 스펙에서 제거된 create는 generic fallback으로 처리된다', () {
        expect(
          friendActivityMessage(activity(action: 'create', displayName: '철수')),
          '철수님의 타이머 상태가 변경되었습니다',
        );
      });

      test('공식 스펙에서 제거된 complete는 generic fallback으로 처리된다', () {
        expect(
          friendActivityMessage(
            activity(action: 'complete', displayName: '철수'),
          ),
          '철수님의 타이머 상태가 변경되었습니다',
        );
      });

      test('알 수 없는 action은 generic fallback으로 처리된다', () {
        expect(
          friendActivityMessage(
            activity(action: 'whatever', displayName: '철수'),
          ),
          '철수님의 타이머 상태가 변경되었습니다',
        );
      });
    });

    test('timerTitle이 있으면 "<제목> 타이머"로 표시된다', () {
      final msg = friendActivityMessage(
        activity(displayName: '철수', timerTitle: '집중'),
      );
      expect(msg, '철수님이 집중 타이머를 시작했습니다');
    });
  });

  // ============================================================
  // TimerPage — 친구 활동 수신 시 SnackBar 표시 (provider 동작)
  // ============================================================
  group('친구 활동 SnackBar', () {
    late StreamController<TimerWsFriendActivity> controller;

    setUp(() => controller = StreamController<TimerWsFriendActivity>());
    tearDown(() => controller.close());

    Widget buildPage() {
      return pumpApp(
        const TimerPage(),
        overrides: [
          // UI-scoped 알림 스트림을 제어 가능한 컨트롤러로 대체
          timerFriendActivityProvider.overrideWith((ref) => controller.stream),
          // 실제 REST/WS·주기 타이머 호출을 막기 위한 대체
          activeTimerProvider.overrideWith(
            (ref) => Stream<TimerRead?>.value(null),
          ),
          timerHistoryProvider.overrideWith(
            (ref) => Future.value(<TimerRead>[]),
          ),
          timerTickerProvider.overrideWith(
            (ref) => Stream.value(Duration.zero),
          ),
        ],
      );
    }

    testWidgets('친구 활동 이벤트 수신 시 SnackBar가 문구와 함께 표시된다', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pump();

      controller.add(activity(action: 'start', displayName: '영희'));
      await tester.pump(); // 스트림 이벤트 전달
      await tester.pump(); // SnackBar 등장 프레임

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('영희님이 타이머를 시작했습니다'), findsOneWidget);
    });

    testWidgets('displayName이 없으면 SnackBar에 "친구" fallback이 표시된다', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pump();

      controller.add(activity(action: 'pause'));
      await tester.pump();
      await tester.pump();

      expect(find.text('친구님이 타이머를 일시정지했습니다'), findsOneWidget);
    });
  });

  // ============================================================
  // TimerPage — 정지 확인 모달 (대시보드 + 히스토리)
  // ============================================================
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
      // 확인 시점에 캡처한 활성 타이머 id로 정지해야 한다 (async race 방지).
      expect(controller.stoppedTimerId, 'timer-1');
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
    // 친구 활동 리스너가 실제 WS/auth 체인을 건드리지 않도록 빈 스트림으로 격리
    timerFriendActivityProvider.overrideWith(
      (ref) => const Stream<TimerWsFriendActivity>.empty(),
    ),
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
  bool stopCalled = false;
  String? stoppedTimerId;

  @override
  FutureOr<void> build() {}

  @override
  Future<void> stopTimer({String? timerId}) async {
    stopCalled = true;
    stoppedTimerId = timerId;
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
