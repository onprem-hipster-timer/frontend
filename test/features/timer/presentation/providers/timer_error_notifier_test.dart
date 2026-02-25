import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';

void main() {
  group('TimerWsLastErrorNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('초기 상태는 null이다', () {
      expect(container.read(timerWsLastErrorProvider), isNull);
    });

    test('setError로 에러를 설정할 수 있다', () {
      const error = TimerWsError(code: 'TIMER_NOT_FOUND', message: '타이머 없음');

      container.read(timerWsLastErrorProvider.notifier).setError(error);

      expect(container.read(timerWsLastErrorProvider), error);
      expect(container.read(timerWsLastErrorProvider)?.code, 'TIMER_NOT_FOUND');
      expect(container.read(timerWsLastErrorProvider)?.message, '타이머 없음');
    });

    test('setError(null)로 에러를 초기화할 수 있다', () {
      const error = TimerWsError(code: 'ERR', message: 'msg');
      container.read(timerWsLastErrorProvider.notifier).setError(error);
      expect(container.read(timerWsLastErrorProvider), isNotNull);

      container.read(timerWsLastErrorProvider.notifier).setError(null);
      expect(container.read(timerWsLastErrorProvider), isNull);
    });

    test('에러를 연속으로 설정하면 마지막 값이 유지된다', () {
      const err1 = TimerWsError(code: 'A', message: 'first');
      const err2 = TimerWsError(code: 'B', message: 'second');
      const err3 = TimerWsError(code: 'C', message: 'third');

      final notifier = container.read(timerWsLastErrorProvider.notifier);
      notifier.setError(err1);
      notifier.setError(err2);
      notifier.setError(err3);

      expect(container.read(timerWsLastErrorProvider), err3);
    });

    test('리스너가 에러 변경을 감지한다', () {
      final List<TimerWsError?> history = [];
      container.listen(
        timerWsLastErrorProvider,
        (prev, next) => history.add(next),
      );

      const err = TimerWsError(code: 'X', message: 'y');
      container.read(timerWsLastErrorProvider.notifier).setError(err);
      container.read(timerWsLastErrorProvider.notifier).setError(null);

      expect(history, [err, null]);
    });

    test('같은 에러를 다시 설정해도 리스너에 알린다', () {
      final List<TimerWsError?> history = [];
      container.listen(
        timerWsLastErrorProvider,
        (prev, next) => history.add(next),
      );

      const err = TimerWsError(code: 'SAME', message: 'same');
      container.read(timerWsLastErrorProvider.notifier).setError(err);
      container.read(timerWsLastErrorProvider.notifier).setError(err);

      // Riverpod은 값이 동일하면 알리지 않음 (Freezed equality)
      expect(history.length, 1);
    });
  });
}
