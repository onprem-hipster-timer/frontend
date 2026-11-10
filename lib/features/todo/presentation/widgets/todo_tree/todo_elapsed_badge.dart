import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/utils/time_formatters.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';
import 'package:momeet/shared/ui/ui.dart';

/// Todo의 누적 집중 시간 배지 (하위 Todo 포함)
///
/// 끝난 타이머 시간([todoTimerAggregationProvider])에 활성 타이머의 표시 경과 시간
/// ([activeTimerStreamProvider])을 더해 1초마다 갱신한다. 시간이 없으면 표시하지 않는다.
///
/// 테스트: test/features/todo/presentation/widgets/todo_tree_tile_elapsed_test.dart
class TodoElapsedBadge extends ConsumerWidget {
  final TodoTreeNode node;

  const TodoElapsedBadge({super.key, required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final finished =
        ref
            .watch(todoTimerAggregationProvider(node.id))
            .value
            ?.totalElapsedSeconds ??
        0;

    final subtreeIds = <String>{};
    void collect(TodoTreeNode current) {
      subtreeIds.add(current.id);
      for (final child in current.children) {
        collect(child);
      }
    }

    collect(node);

    // 하위 Todo까지의 활성 타이머 경과 시간 합. 활성 타이머가 없으면 null
    final active = ref.watch(
      activeTimerStreamProvider.select((states) {
        final seconds = <int>[
          for (final MapEntry(:key, :value) in (states.value ?? {}).entries)
            if (subtreeIds.contains(key)) value.elapsedSeconds,
        ];
        return seconds.isEmpty ? null : seconds.reduce((a, b) => a + b);
      }),
    );

    if (finished == 0 && active == null) return const SizedBox.shrink();

    final isActive = active != null;
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadius.mdAll,
        ),
        child: Text(
          formatDuration(Duration(seconds: finished + (active ?? 0))),
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
