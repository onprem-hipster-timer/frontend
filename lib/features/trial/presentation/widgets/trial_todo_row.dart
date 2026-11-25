import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/timer.dart' show canLinkTimer;
import 'package:momeet/features/todo/todo.dart'
    show
        EditableTodoTreeTileView,
        TodoElapsedBadgeView,
        TodoStatusSelectorView,
        TodoTagIndicators,
        TodoTimerChipView,
        TodoTimerStartButtonView;
import 'package:momeet/features/trial/presentation/widgets/trial_inert.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 체험하기의 할 일 한 줄. 앱의 할 일 목록 줄([EditableTodoTreeTileView])에 [todo]를 앱처럼 담는다: 상태,
/// 진행 중인 [timer]의 남은 시간, 누적 집중 시간(끝난 [recordedSeconds]에 진행 중인 시간을 더한다), 태그,
/// 타이머를 이을 수 있으면 시작 버튼(진행 중이면 숨긴다).
///
/// 시작 버튼은 [onStartTimer]를, 남은 시간은 앱처럼 타이머로 가는 [onOpenTimer]를 부른다. 수정·삭제는 누를 수 없는
/// 모양이고, 상태는 포인터로도 키보드로도 스크린 리더로도 열리지 않으며([TrialInert]), 고르기·끌기는 반응하지 않는다
class TrialTodoRow extends StatelessWidget {
  const TrialTodoRow({
    super.key,
    required this.todo,
    this.timer,
    this.recordedSeconds = 0,
    this.onStartTimer,
    this.onOpenTimer,
  });

  final TodoRead todo;

  /// 할 일로 시작한 타이머. 진행 중일 때만 보인다
  final TimerRead? timer;
  final int recordedSeconds;
  final VoidCallback? onStartTimer;
  final VoidCallback? onOpenTimer;

  @override
  Widget build(BuildContext context) {
    final timer = this.timer;
    final running = timer != null && timer.status == TimerStatus.running;
    final linkable = canLinkTimer(todo);
    return EditableTodoTreeTileView(
      todo: todo,
      status: TrialInert(
        child: TodoStatusSelectorView(status: todo.status, onSelected: (_) {}),
      ),
      meta: [
        if (linkable && running)
          TodoTimerChipView(
            remainingSeconds: timer.allocatedDuration - timer.elapsedTime,
            onPressed: onOpenTimer ?? () {},
          ),
        TodoElapsedBadgeView(
          finishedSeconds: recordedSeconds,
          activeSeconds: running ? timer.elapsedTime : null,
        ),
        if (todo.tags.isNotEmpty) TodoTagIndicators(tags: todo.tags),
      ],
      // 앱처럼 타이머가 도는 할 일은 버튼 자리를 두되 버튼을 그리지 않는다
      timerButton: !linkable
          ? null
          : running
          ? const SizedBox.shrink()
          : TodoTimerStartButtonView(
              starting: false,
              onPressed: onStartTimer ?? () {},
            ),
      onEdit: null,
      onDelete: null,
      onTap: () {},
      canAccept: (_) => false,
      onAccept: (_) {},
      onDragStarted: () {},
      onDragEnd: () {},
    );
  }
}
