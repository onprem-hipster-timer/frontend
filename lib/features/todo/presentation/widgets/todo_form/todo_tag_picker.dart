import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/providers/tag_providers.dart' as tag_providers;
import 'package:momeet/features/tag/presentation/widgets/tag_form_sheet.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_group_form_sheet.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form/todo_tag_picker_view.dart';

/// 할 일 폼의 태그 고르기. 고른 태그를 위에 모아 보이고, 태그 그룹별로 태그 칩을 늘어놓는다.
/// 할 일에는 어느 태그 그룹의 태그든 붙일 수 있다.
class TodoTagPicker extends ConsumerWidget {
  const TodoTagPicker({
    super.key,
    required this.selectedTagIds,
    required this.onToggle,
  });

  final Set<String> selectedTagIds;
  final void Function(String tagId, bool selected) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TodoTagPickerView(
      tagGroups: ref.watch(tag_providers.tagTreeProvider),
      selectedTagIds: selectedTagIds,
      onToggle: onToggle,
      onCreateTag: (groupId) => _createTag(context, ref, groupId: groupId),
    );
  }
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
