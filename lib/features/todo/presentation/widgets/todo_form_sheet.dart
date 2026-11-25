import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/providers/todo_group_providers.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form_sheet_view.dart';
import 'package:momeet/shared/providers/tag_providers.dart' as tag_providers;
import 'package:momeet/features/tag/presentation/widgets/tag_form_sheet.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_group_form_sheet.dart';
import 'package:momeet/features/todo/presentation/utils/todo_form_submit.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/domain/terms.dart';

/// Todo 생성/수정 폼 시트
///
/// Modal Bottom Sheet로 표시되며, Todo의 제목, 설명, 태그, 상태를 편집할 수 있습니다.
/// 새로 만들면 알림에 '할 일 보기'(새 할 일이 든 할 일 그룹 화면으로 이동)를 둔다. 지금 그 그룹 화면이면 새 할 일이 이미 보이므로 두지 않는다.
///
/// 테스트: test/features/todo/presentation/pages/todo_dashboard_page_test.dart,
/// test/features/todo/presentation/pages/todo_group_detail_page_test.dart
class TodoFormSheet extends ConsumerStatefulWidget {
  /// 수정할 Todo (null인 경우 생성 모드)
  final TodoRead? todo;

  /// 기본 상위 Todo ID (생성 시 사용)
  final String? defaultParentId;

  /// 새 할 일의 할 일 그룹 칸에 미리 고를 그룹 ID. 없으면 기본 그룹을 보이고 보내지 않는다(서버가 기본 그룹에 넣는다).
  /// [defaultParentId]와 함께 주면 상위 할 일의 그룹이어야 하고, 칸은 바꿀 수 없다
  final String? defaultTodoGroupId;

  const TodoFormSheet({
    super.key,
    this.todo,
    this.defaultParentId,
    this.defaultTodoGroupId,
  });

  @override
  ConsumerState<TodoFormSheet> createState() => _TodoFormSheetState();
}

class _TodoFormSheetState extends ConsumerState<TodoFormSheet> {
  late final _isEditMode = widget.todo != null;

  @override
  Widget build(BuildContext context) {
    final isLoading = _isEditMode
        ? ref.watch(updateTodoMutation).isPending
        : ref.watch(createTodoMutation).isPending;

    return TodoFormSheetView(
      todo: widget.todo,
      defaultTodoGroupId: widget.defaultTodoGroupId,
      groupLocked: widget.defaultParentId != null,
      todoGroups: ref.watch(todoGroupsProvider),
      tagGroups: ref.watch(tag_providers.tagTreeProvider),
      busy: isLoading,
      onSubmit: _handleSubmit,
      onCreateTag: (groupId) => _createTag(context, ref, groupId: groupId),
    );
  }

  /// 폼 제출 처리
  Future<void> _handleSubmit(TodoFormValues values) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    VoidCallback? openGroup;

    try {
      if (_isEditMode) {
        if (!mounted) return;
        final sent = await updateTodoFromForm(
          context,
          ref,
          widget.todo!,
          values,
        );
        if (!sent) return;
      } else {
        // 시트를 닫은 뒤에도 알림에서 이동할 수 있게 라우터를 잡아 둔다
        final router = GoRouter.of(context);
        final created = await createTodoFromForm(
          ref,
          values,
          parentId: widget.defaultParentId,
        );
        openGroup = _openGroupAction(router, created.todoGroupId);
      }
      if (mounted) {
        navigator.pop();
        scaffoldMessenger.showAppSnackBar(
          _isEditMode
              ? todoUpdatedMessage(
                  widget.todo!,
                  values,
                  ref.read(todoGroupsProvider).value,
                )
              : '${Terms.todo.withJosa('이', '가')} 생성되었습니다',
          kind: AppNoticeKind.success,
          actionLabel: openGroup == null ? null : '${Terms.todo} 보기',
          onAction: openGroup,
        );
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          _isEditMode
              ? '${Terms.todo} 수정에 실패했습니다: $error'
              : '${Terms.todo} 생성에 실패했습니다: $error',
          kind: AppNoticeKind.error,
        );
      }
    }
  }
}

/// [groupId] 할 일 그룹 화면으로 가는 동작. 지금 그 화면이면 null
VoidCallback? _openGroupAction(GoRouter router, String groupId) {
  final state = router.state;
  if (state.name == AppRoute.todoGroupDetail.name &&
      state.pathParameters['groupId'] == groupId) {
    return null;
  }
  return () => router.goNamed(
    AppRoute.todoGroupDetail.name,
    pathParameters: {'groupId': groupId},
  );
}

/// Todo 폼 시트를 표시하는 헬퍼 함수
///
/// 사용 예:
/// ```dart
/// showTodoFormSheet(
///   context,
///   defaultTodoGroupId: groupId,
/// );
/// ```
Future<void> showTodoFormSheet(
  BuildContext context, {
  TodoRead? todo,
  String? defaultParentId,
  String? defaultTodoGroupId,
}) {
  return showAppSheet<void>(
    context,
    builder: (context) => TodoFormSheet(
      todo: todo,
      defaultParentId: defaultParentId,
      defaultTodoGroupId: defaultTodoGroupId,
    ),
  );
}

/// 새 태그 만들기. [groupId]를 주면 그 그룹을 기본으로 고른다.
///
/// 태그 그룹이 없으면 태그 그룹 폼을 먼저 열고, 태그 그룹이 생기면 그 그룹을 고른 채 태그 폼으로 잇는다.
/// 태그 그룹 폼을 닫으면 아무것도 하지 않는다. 태그 목록을 아직 받지 못했으면 열지 않는다.
/// 태그 목록 조회가 실패한 상태면 목록을 다시 받아 이어 가고, 또 실패하면 목록 자리의 오류 안내로 둔다.
Future<void> _createTag(
  BuildContext context,
  WidgetRef ref, {
  String? groupId,
}) async {
  final tree = ref.read(tag_providers.tagTreeProvider);
  var groups = tree.value;
  try {
    if (tree.hasError) {
      ref.invalidate(tag_providers.tagGroupsRawProvider);
      groups = await ref.read(tag_providers.tagTreeProvider.future);
      if (!context.mounted) return;
    }
    if (groups == null) return;
    if (groups.isEmpty) {
      await showTagGroupFormSheet(context);
      if (!context.mounted) return;
      groups = await ref.read(tag_providers.tagTreeProvider.future);
      if (!context.mounted || groups.isEmpty) return;
    }
  } catch (_) {
    return;
  }
  await showTagFormSheet(
    context,
    defaultGroupId: groupId ?? groups.first.group.id,
  );
  // 새로 만든 태그를 목록에 반영한다
  if (context.mounted) ref.invalidate(tag_providers.tagTreeProvider);
}
