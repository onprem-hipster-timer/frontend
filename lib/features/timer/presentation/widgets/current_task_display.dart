import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_share_sheet.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_status_selector.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 현재 작업 표시 위젯
///
/// 연결된 Todo가 있으면 제목 옆에 Todo 상태를 표시하고, 일시정지 중에는 그 자리에서 바꿀 수 있습니다.
/// 바꾼 뒤 서버가 돌려준 Todo로 [onTodoChanged]를 부릅니다.
/// 내 타이머면 제목 뒤에 공유 범위 버튼([TimerShareButton])을 둡니다.
class CurrentTaskDisplay extends StatelessWidget {
  final TimerRead? timer;
  final ValueChanged<TodoRead>? onTodoChanged;

  const CurrentTaskDisplay({
    super.key,
    required this.timer,
    this.onTodoChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (timer == null) {
      return Text(
        '진행 중인 작업이 없습니다',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      );
    }

    final taskName =
        timer!.title ??
        timer!.todo?.title ??
        timer!.schedule?.title ??
        '알 수 없는 작업';
    final todo = timer!.todo;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (todo != null) ...[
          if (timer!.status == TimerStatus.paused)
            TodoStatusSelector(todo: todo, onChanged: onTodoChanged)
          else
            Icon(
              todo.status.icon,
              color: todo.status.color(context),
              semanticLabel: todo.status.label,
            ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            taskName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!timer!.isShared) TimerShareButton(timer: timer!),
      ],
    );
  }
}
