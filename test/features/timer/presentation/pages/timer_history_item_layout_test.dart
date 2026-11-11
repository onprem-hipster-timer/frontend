import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_history_item.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/layout_audit_app.dart';
import '../../../../helpers/timer_fixtures.dart';

TimerRead _paused(String title) => makeTimer(
  id: 'timer-1',
  status: TimerStatus.paused,
  startedAt: DateTime.utc(2026, 11, 6, 9),
  elapsedTime: 1200,
).copyWith(title: title);

Widget _app(TimerRead timer) =>
    wrapWithApp(
      overrides: [
        activeTimerProvider.overrideWithValue(const AsyncData(null)),
        timerTickerProvider.overrideWith((ref) => Stream.value(Duration.zero)),
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

void main() {
  testWidgets('좁은 화면에 글자가 커도 상태와 시작–끝 시각을 자르지 않고 줄을 나눠 보인다', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_app(_paused('집중')));
    await tester.pump();

    for (final text in [find.text('일시정지'), find.textContaining(' - ')]) {
      final paragraph = tester.renderObject<RenderParagraph>(text);
      expect(paragraph.didExceedMaxLines, isFalse);
    }
  });

  // 좁은 화면의 ListTile 폭 단언 뒤에는 파인더 평가가 던지므로 verify를 두지 않는다.
  testLayoutAudit(
    'timer_history_item',
    subject: '제목',
    within: find.byType(TimerHistoryItem),
    // 일시정지 상태가 상태 배지와 재개·완료 버튼을 함께 그려 가장 넓다.
    build: (text) => _app(_paused(text.value)),
  );
}
