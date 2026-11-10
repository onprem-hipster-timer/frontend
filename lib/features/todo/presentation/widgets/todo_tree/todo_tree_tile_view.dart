import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_status_selector.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 들여쓰기 단위 (깊이당 픽셀)
const double kIndentWidth = 24.0;

/// 할 일 트리의 한 줄. 표시만 하고 조작은 [leading]·[status]·[trailing] 자리에 받는다.
///
/// 제목은 완료·취소면 취소선을 긋고, [meta]는 제목 아래에 자리가 모자라면 줄을 바꿔 둔다.
class TodoTreeTileView extends StatelessWidget {
  const TodoTreeTileView({
    super.key,
    required this.todo,
    this.depth = 0,
    this.leading,
    this.status,
    this.meta = const [],
    this.trailing,
    this.selected = false,
    this.onTap,
  });

  final TodoRead todo;
  final int depth;

  /// 펼침 버튼 자리. 없으면 정렬용 빈칸을 둔다.
  final Widget? leading;

  /// 상태 자리. 없으면 상태 아이콘만 보인다.
  final Widget? status;

  /// 제목 아래 줄(남은 시간·누적 시간·태그·하위 개수 등)
  final List<Widget> meta;

  /// 오른쪽 끝(버튼 등)
  final Widget? trailing;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = todo.description;
    final trailing = this.trailing;
    return Semantics(
      container: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer.withAlpha(77)
                : null,
            borderRadius: AppRadius.smAll,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: depth * kIndentWidth,
              right: 8,
              top: 8,
              bottom: 8,
            ),
            child: Row(
              children: [
                leading ?? const SizedBox(width: 24),
                status ??
                    Icon(todo.status.icon, color: todo.status.color(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TodoTitle(todo: todo),
                      if (description != null && description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (meta.isNotEmpty)
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: meta,
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 할 일 제목. 완료·취소면 취소선을 긋고 흐리게 쓴다.
class _TodoTitle extends StatelessWidget {
  const _TodoTitle({required this.todo});

  final TodoRead todo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (decoration, color) = switch (todo.status) {
      TodoStatus.done => (
        TextDecoration.lineThrough,
        scheme.onSurface.withAlpha(128),
      ),
      TodoStatus.cancelled => (
        TextDecoration.lineThrough,
        scheme.error.withAlpha(128),
      ),
      _ => (null, null),
    };
    return Text(
      todo.title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        decoration: decoration,
        color: color,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
