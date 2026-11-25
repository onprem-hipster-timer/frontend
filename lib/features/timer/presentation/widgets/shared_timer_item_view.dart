import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/utils/time_formatters.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_status_chip.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 친구가 공유한 타이머 항목. 보기만 하고 버튼을 두지 않습니다
///
/// 작업 제목, 상태, 주인 이름([ownerName])과 [duration]을 보입니다.
class SharedTimerItemView extends StatelessWidget {
  const SharedTimerItemView({
    super.key,
    required this.timer,
    required this.ownerName,
    required this.duration,
  });

  final TimerRead timer;
  final String ownerName;

  /// RUNNING/PAUSED면 남은 시간, 끝난 타이머는 경과 시간
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = timerStatusStyle(context, timer.status);
    final isActive =
        timer.status == TimerStatus.running ||
        timer.status == TimerStatus.paused;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: style.bg,
          child: Icon(style.icon, color: style.fg),
        ),
        title: Text(
          timer.title ?? timer.todo?.title ?? '제목 없는 ${Terms.timer}',
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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
