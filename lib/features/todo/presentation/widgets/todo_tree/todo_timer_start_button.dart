import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart'
    show defaultFocusDuration, timerControllerProvider;
import 'package:momeet/features/timer/presentation/widgets/start_timer_sheet.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/shared/domain/terms.dart';

/// [todo]를 연결해 새 타이머를 시작하는 버튼. Todo에 활성 타이머가 있으면 표시하지 않는다
///
/// 새 작업 시작 시트를 [todo]를 고른 채 열고, 시작해도 할 일 화면에 머문다.
/// 시작하면 떠 있던 알림을 닫고 '타이머 보기'(타이머 화면으로 이동)가 있는 알림을 띄운다.
/// 실패하면 알린다. 시트에서 할 일을 여럿 고르면 할 일마다 시작하고, 시작하지 못한 할 일만 알린다.
/// 새 타이머를 시작하는 동안에는 누를 수 없다.
///
/// 테스트: test/features/todo/presentation/widgets/todo_tree_tile_timer_test.dart
class TodoTimerStartButton extends ConsumerWidget {
  final TodoRead todo;

  const TodoTimerStartButton({super.key, required this.todo});

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final input = await showStartTimerSheet(
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
        error != null
            ? '${Terms.timer} 시작 실패: $error'
            : startFailureMessage(failed),
        kind: AppNoticeKind.error,
      );
      return;
    }
    // 알림이 떠 있는 사이 타일이 목록에서 빠져도 이동할 수 있게 라우터를 잡아 둔다
    final router = GoRouter.of(context);
    messenger.showAppSnackBar(
      '${Terms.timer.withJosa('을', '를')} 시작했습니다',
      actionLabel: '${Terms.timer} 보기',
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
      tooltip: '${Terms.timer} 시작',
      visualDensity: VisualDensity.compact,
      onPressed: starting ? null : () => _start(context, ref),
    );
  }
}
