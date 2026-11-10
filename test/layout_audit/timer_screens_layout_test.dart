import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:layout_audit/layout_audit.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/timer/presentation/pages/timer_page.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/timer/presentation/widgets/start_timer_sheet.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_share_sheet.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';
import 'package:momeet/shared/providers/friend_providers.dart';

import '../helpers/fake_timer_repository.dart';
import '../helpers/layout_audit_app.dart';
import '../helpers/timer_fixtures.dart';

/// 타이머 화면과 시트를 화면 크기 × 글자 배율 × 긴 문구로 점검한다.
///
/// 사용자가 넣는 글자(타이머·할 일 제목, 친구 이름)에 [StressText]를 넣는다.
void main() {
  final now = DateTime.utc(2026, 11, 9, 10, 30);

  TimerRead timer(String id, String title, TimerStatus status) => makeTimer(
    id: id,
    status: status,
    startedAt: now.subtract(const Duration(minutes: 10)),
    createdAt: now.subtract(const Duration(minutes: 10)),
    allocatedDuration: 1500,
    elapsedTime: 600,
  ).copyWith(title: title);

  List<Override> overrides(String text, {List<TimerRead> active = const []}) {
    final history = [
      timer('done-1', text, TimerStatus.completed),
      timer('done-2', '짧은 작업', TimerStatus.completed),
      ...active,
    ];
    return [
      serverClockProvider.overrideWithValue(ServerClock(deviceNow: () => now)),
      currentUserProvider.overrideWithValue(null),
      timerWsClientProvider.overrideWithValue(null),
      timerRepositoryProvider.overrideWithValue(
        FakeTimerRepository()..listActive = () async => active,
      ),
      timerFriendActivityProvider.overrideWith(
        (ref) => const Stream<TimerWsTimerEvent>.empty(),
      ),
      myActiveTimersProvider.overrideWithBuild((ref, _) => active),
      timerHistoryProvider.overrideWith((ref) async => history),
      sharedTimersProvider.overrideWith(
        (ref) async => [timer('shared-1', text, TimerStatus.running)],
      ),
      allTodosProvider.overrideWith((ref) async => const <TodoRead>[]),
      friendsProvider.overrideWith(
        (ref) async => [
          makeFriend('friend-1', displayName: text),
          makeFriend('friend-2', displayName: '민수'),
        ],
      ),
    ];
  }

  testLayoutAudit(
    'timer_page_idle',
    subject: '대기 중 기록 제목',
    build: (text) =>
        wrapWithApp(overrides: overrides(text.value))(const TimerPage()),
  );

  testLayoutAudit(
    'timer_page_running',
    subject: '실행 중 타이머 제목',
    build: (text) => wrapWithApp(
      overrides: overrides(
        text.value,
        active: [timer('run-1', text.value, TimerStatus.running)],
      ),
    )(const TimerPage()),
  );

  testLayoutAudit(
    'timer_page_gallery',
    subject: '활성 타이머 둘의 제목',
    build: (text) => wrapWithApp(
      overrides: overrides(
        text.value,
        active: [
          timer('run-1', text.value, TimerStatus.running),
          timer('pause-1', text.value, TimerStatus.paused),
        ],
      ),
    )(const TimerPage()),
  );

  testLayoutAudit(
    'start_timer_sheet',
    subject: '작업 제목',
    build: (text) => wrapWithApp(overrides: overrides(text.value))(
      OpenOnStart(
        open: (context) => showStartTimerSheet(
          context,
          initialDuration: defaultFocusDuration,
          initialTodo: makeTodo().copyWith(title: text.value),
        ),
      ),
    ),
  );

  testLayoutAudit(
    'timer_share_sheet',
    subject: '친구 이름',
    build: (text) => wrapWithApp(overrides: overrides(text.value))(
      OpenOnStart(
        open: (context) => showTimerShareSheet(
          context,
          timer: timer('run-1', text.value, TimerStatus.running),
        ),
      ),
    ),
  );
}
