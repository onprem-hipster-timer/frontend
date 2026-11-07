import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/timer_fixtures.dart';

void main() {
  ProviderContainer boot(TimerRead? active) {
    final container = ProviderContainer(
      overrides: [
        activeTimerProvider.overrideWithValue(AsyncData(active)),
        serverClockProvider.overrideWithValue(
          ServerClock(deviceNow: () => DateTime.utc(2026, 11, 6, 10, 0, 30)),
        ),
      ],
    );
    container.listen(timerTickerProvider, (_, _) {});
    return container;
  }

  testWidgets('활성 타이머의 남은 시간을 서버 시각 기준으로 1초마다 낸다', (tester) async {
    final container = boot(
      makeTimer(
        id: 't1',
        status: TimerStatus.running,
        startedAt: DateTime.utc(2026, 11, 6, 10),
        allocatedDuration: 1500,
        elapsedTime: 100,
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(
      container.read(timerTickerProvider).value,
      const Duration(seconds: 1370),
    );
    container.dispose();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('활성 타이머가 없으면 0이다', (tester) async {
    final container = boot(null);

    await tester.pump(const Duration(seconds: 1));

    expect(container.read(timerTickerProvider).value, Duration.zero);
    container.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}
