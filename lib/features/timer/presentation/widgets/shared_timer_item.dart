import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/core/utils/time_formatters.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_status_chip.dart';

/// 친구가 공유한 타이머 항목. 보기만 하고 버튼을 두지 않습니다
///
/// 작업 제목, 상태, 주인 이름([ownerName])을 보이고, RUNNING/PAUSED면 남은 시간을, 끝난 타이머는 경과 시간을 보입니다.
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
    final theme = Theme.of(context);
    final style = timerStatusStyle(context, timer.status);
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: style.bg,
          child: Icon(style.icon, color: style.fg),
        ),
        title: Text(
          timer.title ?? timer.todo?.title ?? '알 수 없는 작업',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        // 이름이 한 줄에 안 들어가면 상태 아래 줄로 내린다
        subtitle: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TimerStatusChip(style),
            Text(ownerName, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Text(
          formatDuration(duration),
          style: theme.textTheme.titleSmall?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            color: isActive ? style.fg : theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
