import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/timer/presentation/widgets/shared_timer_item_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';

/// 친구가 공유한 타이머 항목. 모양은 [SharedTimerItemView]
///
/// RUNNING/PAUSED면 남은 시간을, 끝난 타이머는 경과 시간을 보입니다.
/// 실행 중이면 서버 기준 시각으로 1초마다 다시 셉니다.
class SharedTimerItem extends ConsumerWidget {
  const SharedTimerItem({
    super.key,
    required this.timer,
    required this.ownerName,
  });

  final TimerRead timer;
  final String ownerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive =
        timer.status == TimerStatus.running ||
        timer.status == TimerStatus.paused;
    final ticked = timer.status == TimerStatus.running
        ? ref.watch(serverNowProvider).value
        : null;
    final now = ticked ?? ref.watch(serverClockProvider).now();
    final duration = isActive
        ? displayRemaining(timer, now)
        : displayElapsed(timer, now);

    return SharedTimerItemView(
      timer: timer,
      ownerName: ownerName,
      duration: duration,
    );
  }
}
