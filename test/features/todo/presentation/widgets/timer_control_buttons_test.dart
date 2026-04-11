import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree_tile_with_timer.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/pump_app.dart';

/// startTimer / pauseTimer / resumeTimer / stopTimer 호출을 기록하는 Fake.
class FakeTimerController extends TimerController {
  final List<String> calls = [];
  Completer<void>? _completer;

  /// 호출 시 즉시 완료하지 않고 대기하게 만든다 (더블클릭 테스트용).
  void holdNextCall() {
    _completer = Completer<void>();
  }

  void releaseCall() {
    _completer?.complete();
    _completer = null;
  }

  bool shouldThrow = false;

  @override
  FutureOr<void> build() {}

  @override
  Future<void> startTimer({
    String? relatedTodoId,
    String? title,
    String? scheduleId,
    int? allocatedDurationSeconds,
  }) async {
    state = const AsyncValue.loading();
    calls.add('startTimer:$relatedTodoId');
    if (_completer != null) await _completer!.future;
    if (shouldThrow) {
      state = AsyncValue.error('fail', StackTrace.current);
      throw Exception('fail');
    }
    state = const AsyncValue.data(null);
  }

  @override
  Future<void> pauseTimer({String? timerId}) async {
    state = const AsyncValue.loading();
    calls.add('pauseTimer:$timerId');
    if (_completer != null) await _completer!.future;
    if (shouldThrow) {
      state = AsyncValue.error('fail', StackTrace.current);
      throw Exception('fail');
    }
    state = const AsyncValue.data(null);
  }

  @override
  Future<void> resumeTimer({String? timerId}) async {
    state = const AsyncValue.loading();
    calls.add('resumeTimer:$timerId');
    if (_completer != null) await _completer!.future;
    if (shouldThrow) {
      state = AsyncValue.error('fail', StackTrace.current);
      throw Exception('fail');
    }
    state = const AsyncValue.data(null);
  }

  @override
  Future<void> stopTimer({String? timerId}) async {
    state = const AsyncValue.loading();
    calls.add('stopTimer:$timerId');
    if (_completer != null) await _completer!.future;
    if (shouldThrow) {
      state = AsyncValue.error('fail', StackTrace.current);
      throw Exception('fail');
    }
    state = const AsyncValue.data(null);
  }
}

void main() {
  late FakeTimerController fakeController;

  const todoId = 'todo-1';
  const timerId = 'timer-1';

  const runningState = ActiveTimerState(
    timerId: timerId,
    elapsedSeconds: 120,
    status: TimerStatus.running,
  );

  const pausedState = ActiveTimerState(
    timerId: timerId,
    elapsedSeconds: 120,
    status: TimerStatus.paused,
  );

  setUp(() {
    fakeController = FakeTimerController();
  });

  Widget buildWidget({ActiveTimerState? activeTimerState}) {
    return pumpApp(
      Scaffold(
        body: TimerControlButtons(
          todoId: todoId,
          activeTimerState: activeTimerState,
        ),
      ),
      overrides: [timerControllerProvider.overrideWith(() => fakeController)],
    );
  }

  group('TimerControlButtons UI 상태', () {
    testWidgets('활성 타이머 없으면 시작 버튼만 표시', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('실행 중 타이머가 있으면 일시정지/정지 버튼 표시', (tester) async {
      await tester.pumpWidget(buildWidget(activeTimerState: runningState));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('일시정지 타이머가 있으면 재생/정지 버튼 표시', (tester) async {
      await tester.pumpWidget(buildWidget(activeTimerState: pausedState));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('로딩 중에는 스피너 표시', (tester) async {
      fakeController.holdNextCall();

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // 시작 버튼 탭 → 로딩 상태
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);

      fakeController.releaseCall();
      await tester.pumpAndSettle();
    });
  });

  group('타이머 시작', () {
    testWidgets('시작 버튼 탭 시 startTimer 호출', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      expect(fakeController.calls, ['startTimer:$todoId']);
    });

    testWidgets('startTimer 실패 시 에러 SnackBar 표시', (tester) async {
      fakeController.shouldThrow = true;

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      expect(find.textContaining('타이머 시작 실패'), findsOneWidget);
    });
  });

  group('타이머 토글', () {
    testWidgets('실행 중 일시정지 탭 시 pauseTimer 호출', (tester) async {
      await tester.pumpWidget(buildWidget(activeTimerState: runningState));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();

      expect(fakeController.calls, ['pauseTimer:$timerId']);
    });

    testWidgets('일시정지 상태에서 재생 탭 시 resumeTimer 호출', (tester) async {
      await tester.pumpWidget(buildWidget(activeTimerState: pausedState));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      expect(fakeController.calls, ['resumeTimer:$timerId']);
    });

    testWidgets('토글 실패 시 에러 SnackBar 표시', (tester) async {
      fakeController.shouldThrow = true;

      await tester.pumpWidget(buildWidget(activeTimerState: runningState));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();

      expect(find.textContaining('타이머 토글 실패'), findsOneWidget);
    });
  });

  group('타이머 정지', () {
    testWidgets('정지 확인 다이얼로그에서 확인 시 stopTimer 호출', (tester) async {
      await tester.pumpWidget(buildWidget(activeTimerState: runningState));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();

      // 확인 다이얼로그 표시 확인
      expect(find.text('타이머 정지'), findsOneWidget);

      // '정지' 버튼 탭 (FilledButton)
      await tester.tap(find.widgetWithText(FilledButton, '정지'));
      await tester.pumpAndSettle();

      expect(fakeController.calls, ['stopTimer:$timerId']);
    });

    testWidgets('정지 확인 다이얼로그에서 취소 시 stopTimer 미호출', (tester) async {
      await tester.pumpWidget(buildWidget(activeTimerState: runningState));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(fakeController.calls, isEmpty);
    });

    testWidgets('정지 실패 시 에러 SnackBar 표시', (tester) async {
      fakeController.shouldThrow = true;

      await tester.pumpWidget(buildWidget(activeTimerState: runningState));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '정지'));
      await tester.pumpAndSettle();

      expect(find.textContaining('타이머 정지 실패'), findsOneWidget);
    });
  });

  group('더블클릭 방지', () {
    testWidgets('로딩 중 시작 버튼 연타 시 중복 호출 방지', (tester) async {
      fakeController.holdNextCall();

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // 첫 번째 탭
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // 로딩 상태 → 버튼 숨김 → 스피너 표시
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 스피너에 탭 시도 (버튼이 없으므로 무시됨)
      expect(find.byIcon(Icons.play_arrow), findsNothing);

      fakeController.releaseCall();
      await tester.pumpAndSettle();

      expect(fakeController.calls, hasLength(1));
    });

    testWidgets('로딩 중 토글 버튼 연타 시 중복 호출 방지', (tester) async {
      fakeController.holdNextCall();

      await tester.pumpWidget(buildWidget(activeTimerState: runningState));
      await tester.pumpAndSettle();

      // 첫 번째 탭
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();

      // 로딩 → 버튼 사라짐
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      fakeController.releaseCall();
      await tester.pumpAndSettle();

      expect(fakeController.calls, hasLength(1));
    });
  });
}
