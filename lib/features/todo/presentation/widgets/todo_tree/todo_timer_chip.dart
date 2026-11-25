import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_timer_chip_view.dart';

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

    return TodoTimerChipView(remainingSeconds: remaining);
  }
}
