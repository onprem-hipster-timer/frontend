import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_tree_tile_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 끄는 동안 원래 자리의 투명도
const double kDraggingOpacity = 0.5;

/// 고칠 수 있는 할 일 트리 한 줄. 펼친 하위 줄 [children]을 그 아래에 이어 둔다.
///
/// 하위가 있으면([onToggleExpand]) 펼침 버튼을 두고, [status]·[meta]·타이머 시작([timerButton])·수정·삭제를 둔다.
/// 버튼을 옆에 두면 제목 칸이 너무 좁아지는 폭이면 버튼을 제목 아래로 내린다.
/// 길게 눌러 끌 수 있고, 다른 줄을 끌어 이 줄 위에 올리면 놓을 수 있는지([canAccept])에 따라
/// 주색·오류색 테두리를 두른다.
class EditableTodoTreeTileView extends StatelessWidget {
  const EditableTodoTreeTileView({
    super.key,
    required this.todo,
    this.depth = 0,
    this.expanded = false,
    this.onToggleExpand,
    required this.status,
    this.meta = const [],
    this.timerButton,
    required this.onEdit,
    required this.onDelete,
    this.selected = false,
    required this.onTap,
    required this.canAccept,
    required this.onAccept,
    required this.onDragStarted,
    required this.onDragEnd,
    this.children = const [],
  });

  final TodoRead todo;
  final int depth;
  final bool expanded;

  /// 하위를 펼치고 접는다. 하위가 없으면 null이고 펼침 버튼이 없다
  final VoidCallback? onToggleExpand;

  /// 상태 자리
  final Widget status;

  /// 제목 아래 줄(남은 시간·누적 시간·태그·하위 개수 등)
  final List<Widget> meta;

  /// 수정·삭제 앞의 타이머 시작 버튼. 타이머를 연결할 수 없는 할 일이면 null
  final Widget? timerButton;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool selected;
  final VoidCallback onTap;

  /// 끌고 온 할 일을 이 줄 위에 놓을 수 있는지
  final bool Function(TodoRead dragged) canAccept;

  /// 끌고 온 할 일을 이 줄 위에 놓았다
  final ValueChanged<TodoRead> onAccept;
  final VoidCallback onDragStarted;

  /// 끌기를 마치거나 취소했다
  final VoidCallback onDragEnd;

  /// 펼친 하위 줄들
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final onToggleExpand = this.onToggleExpand;
    final actions = _TileActions(
      timerButton: timerButton,
      onEdit: onEdit,
      onDelete: onDelete,
    );
    Widget view(bool narrow) => TodoTreeTileView(
      todo: todo,
      depth: depth,
      leading: onToggleExpand != null
          ? _ExpandButton(expanded: expanded, onPressed: onToggleExpand)
          : null,
      status: status,
      meta: meta,
      trailing: narrow ? null : actions,
      footer: narrow ? actions : null,
      selected: selected,
      onTap: onTap,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DropOnto(
          canAccept: canAccept,
          onAccept: onAccept,
          child: _DragHandle(
            todo: todo,
            onDragStarted: onDragStarted,
            onDragEnd: onDragEnd,
            // 버튼을 옆에 두면 제목 칸이 너무 좁아지는 폭이면 버튼을 제목 아래로 내린다
            child: LayoutBuilder(
              builder: (context, constraints) => view(
                _TileActions.crowds(
                  context,
                  timerButton != null,
                  constraints.maxWidth - depth * kIndentWidth,
                ),
              ),
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// 다른 할 일을 이 줄 위에 놓을 수 있게 하고, 끌고 온 동안 테두리를 두른다
class _DropOnto extends StatelessWidget {
  const _DropOnto({
    required this.canAccept,
    required this.onAccept,
    required this.child,
  });

  final bool Function(TodoRead dragged) canAccept;
  final ValueChanged<TodoRead> onAccept;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DragTarget<TodoRead>(
      onWillAcceptWithDetails: (details) => canAccept(details.data),
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final scheme = Theme.of(context).colorScheme;
        final border = candidateData.isNotEmpty
            ? scheme.primary
            : rejectedData.isNotEmpty
            ? scheme.error
            : null;
        return Container(
          decoration: BoxDecoration(
            border: border == null ? null : Border.all(color: border, width: 2),
            borderRadius: AppRadius.smAll,
          ),
          child: child,
        );
      },
    );
  }
}

/// 길게 눌러 끌 수 있게 한다
class _DragHandle extends StatelessWidget {
  const _DragHandle({
    required this.todo,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.child,
  });

  final TodoRead todo;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LongPressDraggable<TodoRead>(
      data: todo,
      delay: const Duration(milliseconds: 200),
      hapticFeedbackOnStart: true,
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnd(),
      onDraggableCanceled: (_, _) => onDragEnd(),
      feedback: Material(
        elevation: 4,
        borderRadius: AppRadius.mdAll,
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.8,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: AppRadius.mdAll,
          ),
          child: Text(
            todo.title,
            style: theme.textTheme.bodyLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: kDraggingOpacity, child: child),
      child: child,
    );
  }
}

/// 하위를 펼치고 접는 버튼
class _ExpandButton extends StatelessWidget {
  const _ExpandButton({required this.expanded, required this.onPressed});

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedRotation(
        turns: expanded ? 0.25 : 0,
        duration: const Duration(milliseconds: 200),
        child: const Icon(Icons.chevron_right, size: 24),
      ),
    );
  }
}

/// 타이머 시작·수정·삭제 버튼
class _TileActions extends StatelessWidget {
  const _TileActions({
    required this.timerButton,
    required this.onEdit,
    required this.onDelete,
  });

  final Widget? timerButton;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// [width] 폭의 줄에 버튼을 옆에 두면 제목 칸이 글자 배율을 반영한 최소 폭(140)보다 좁아지는지
  ///
  /// 타이머 버튼([timerButton])은 40, 왼쪽 펼침·상태 칸과 여백은 64, 제목과 버튼 사이는 8이다.
  static bool crowds(BuildContext context, bool timerButton, double width) {
    final buttons =
        (timerButton ? 40 : 0) + AppEditDeleteButtons.widthOf(context) + 8;
    return width - 64 - buttons < MediaQuery.textScalerOf(context).scale(140);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ?timerButton,
        AppEditDeleteButtons(onEdit: onEdit, onDelete: onDelete),
      ],
    );
  }
}
