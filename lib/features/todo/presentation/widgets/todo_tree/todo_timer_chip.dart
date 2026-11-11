import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/router.dart';

/// 남은 시간을 mm:ss로, 한 시간 이상이면 h:mm:ss로 쓴다
String _formatRemaining(Duration remaining) {
  final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = remaining.inHours;
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

/// Todo에 연결된 활성(RUNNING·PAUSED) 타이머의 남은 시간 칩. 누르면 타이머 화면으로 간다
///
/// [activeTimerStreamProvider]로 1초마다 갱신하고, 남은 시간이 0이면 에러 색이다. 활성 타이머가 없으면 표시하지 않는다.
///
/// 테스트: test/features/todo/presentation/widgets/todo_tree_tile_timer_test.dart
class TodoTimerChip extends ConsumerWidget {
  final String todoId;

  const TodoTimerChip({super.key, required this.todoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.watch(
      activeTimerStreamProvider.select(
        (states) => states.value?[todoId]?.remainingSeconds,
      ),
    );
    if (remaining == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final color = remaining == 0
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 8),
      child: ActionChip(
        avatar: Icon(Icons.timer_outlined, color: color),
        label: Text(_formatRemaining(Duration(seconds: remaining))),
        labelStyle: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
        tooltip: '타이머로 이동',
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: () => context.go(AppRoute.timer.path),
      ),
    );
  }
}
