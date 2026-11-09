import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/utils/time_formatters.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart'
    show defaultFocusDuration, timerControllerProvider;
import 'package:momeet/features/timer/presentation/widgets/start_timer_dialog.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/rest/export.dart';
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

/// [todo]를 연결해 새 타이머를 시작하는 버튼. Todo에 활성 타이머가 있으면 표시하지 않는다
///
/// 새 작업 시작 다이얼로그를 [todo]를 고른 채 열고, 시작해도 할 일 화면에 머문다.
/// 시작하면 떠 있던 알림을 닫고 '타이머 보기'(타이머 화면으로 이동)가 있는 알림을 띄운다.
/// 실패하면 알린다. 다이얼로그에서 할 일을 여럿 고르면 할 일마다 시작하고, 시작하지 못한 할 일만 알린다.
/// 새 타이머를 시작하는 동안에는 누를 수 없다.
///
/// 테스트: test/features/todo/presentation/widgets/todo_tree_tile_timer_test.dart
class TodoTimerStartButton extends ConsumerWidget {
  final TodoRead todo;

  const TodoTimerStartButton({super.key, required this.todo});

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final input = await showStartTimerDialog(
      context,
      initialDuration: defaultFocusDuration,
      initialTodo: todo,
    );
    if (input == null || !context.mounted) return;
    final controller = ref.read(timerControllerProvider.notifier);
    var failed = const <TodoRead>[];
    Object? error;
    if (input.todos.length >= 2) {
      failed = await controller.startTimers(
        todos: input.todos,
        duration: input.duration,
      );
    } else {
      try {
        await controller.startTimer(
          relatedTodoId: input.todos.firstOrNull?.id,
          title: input.title,
          allocatedDurationSeconds: input.duration.inSeconds,
        );
      } catch (e) {
        error = e;
      }
    }
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (error != null || failed.isNotEmpty) {
      messenger.showAppSnackBar(
        error != null ? '타이머 시작 실패: $error' : startFailureMessage(failed),
        kind: AppNoticeKind.error,
      );
      return;
    }
    // 알림이 떠 있는 사이 타일이 목록에서 빠져도 이동할 수 있게 라우터를 잡아 둔다
    final router = GoRouter.of(context);
    messenger.showAppSnackBar(
      '타이머를 시작했습니다',
      actionLabel: '타이머 보기',
      onAction: () => router.go(AppRoute.timer.path),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(
      activeTimerStreamProvider.select(
        (states) => states.value?.containsKey(todo.id) ?? false,
      ),
    );
    // 시작 요청이 끝날 때까지 컨트롤러(autoDispose)를 붙잡아 둔다
    final starting = ref.watch(
      timerControllerProvider.select((state) => state.isLoading),
    );
    if (active) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.play_circle_outline),
      tooltip: '타이머 시작',
      visualDensity: VisualDensity.compact,
      onPressed: starting ? null : () => _start(context, ref),
    );
  }
}
