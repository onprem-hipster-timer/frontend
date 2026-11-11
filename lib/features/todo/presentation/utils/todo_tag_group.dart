import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/tag_group_with_tags.dart';
import 'package:momeet/shared/providers/tag_providers.dart' as tag_providers;

/// 새 할 일이 들어갈 태그 그룹 id
///
/// 그룹이 하나도 없으면 '기본 그룹'을 만들어 그 그룹을 쓴다(만들지 못하면 예외).
/// [selected]가 비었거나 목록에 없으면 첫 그룹을 쓴다.
Future<String> ensureTodoTagGroup(WidgetRef ref, String selected) async {
  var tagGroups = ref
      .read(tag_providers.tagTreeProvider)
      .when(
        data: (groups) => groups,
        loading: () => <TagGroupWithTags>[],
        error: (_, _) => <TagGroupWithTags>[],
      );
  if (tagGroups.isEmpty) {
    await tag_providers.createTagGroupMutation.run(
      ref,
      (tsx) => tsx
          .get(tag_providers.tagGroupsRawProvider.notifier)
          .createGroup(
            const TagGroupCreate(
              name: '기본 그룹',
              color: '#2196F3',
              description: '할 일을 위한 기본 태그 그룹입니다.',
            ),
          ),
    );
    tagGroups = await ref.refresh(tag_providers.tagTreeProvider.future);
    return tagGroups.isEmpty ? selected : tagGroups.first.group.id;
  }
  if (selected.isEmpty || !tagGroups.any((g) => g.group.id == selected)) {
    return tagGroups.first.group.id;
  }
  return selected;
}
