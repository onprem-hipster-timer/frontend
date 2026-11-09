import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/features/timer/presentation/pages/timer_page.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/layout_audit_app.dart';
import '../../../../helpers/timer_fixtures.dart';

void main() {
  // 좁은 화면의 ListTile 폭 단언 뒤에는 파인더 평가가 던지므로 verify를 두지 않는다.
  testLayoutAudit(
    'timer_history_item',
    subject: '제목',
    within: find.byType(TimerHistoryItem),
    build: (text) {
      // 일시정지 상태가 상태 배지와 재개·완료 버튼을 함께 그려 가장 넓다.
      final timer = makeTimer(
        id: 'timer-1',
        status: TimerStatus.paused,
        startedAt: DateTime.utc(2026, 11, 6, 9),
        elapsedTime: 1200,
      ).copyWith(title: text.value);
      return wrapWithApp(
        overrides: [
          activeTimerProvider.overrideWithValue(const AsyncData(null)),
          timerTickerProvider.overrideWith(
            (ref) => Stream.value(Duration.zero),
          ),
          serverClockProvider.overrideWithValue(
            ServerClock(deviceNow: () => DateTime.utc(2026, 11, 6, 10)),
          ),
        ],
      )(
        // TimerHistoryList와 같은 바깥 여백으로 둔다.
        ListView(
          padding: const EdgeInsets.all(16),
          children: [TimerHistoryItem(timer: timer)],
        ),
      );
    },
  );
}
