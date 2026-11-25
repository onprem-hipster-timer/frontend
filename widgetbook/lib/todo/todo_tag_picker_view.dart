import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncError, AsyncLoading, AsyncValue;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form/todo_tag_picker_view.dart';
import 'package:momeet/shared/domain/tag_group_with_tags.dart';
import 'package:momeet_widgetbook/calendar/samples_plan.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_todo.dart';

enum _Load { done, empty, loading, failed }

@widgetbook.UseCase(name: '할 일 태그 고르기', type: TodoTagPickerView, path: '[할 일]')
Widget todoTagPickerView(BuildContext context) {
  final knobs = context.knobs;
  final load = knobs.object.dropdown(
    label: '상태',
    options: _Load.values,
    labelBuilder: (load) => switch (load) {
      _Load.done => '불러옴',
      _Load.empty => '아직 태그가 없음',
      _Load.loading => '불러오는 중',
      _Load.failed => '불러올 수 없음',
    },
  );
  final longTag = knobs.boolean(
    label: '긴 태그 이름',
    description: '첫 태그 그룹 맨 앞에 긴 이름의 태그를 둔다',
  );
  final AsyncValue<List<TagGroupWithTags>> tagGroups = switch (load) {
    _Load.done => AsyncData([
      for (final (i, group) in sampleTagGroups.indexed)
        i == 0 && longTag
            ? TagGroupWithTags(
                group: group.group,
                tags: [
                  planLongTag.copyWith(groupId: group.groupId),
                  ...group.tags,
                ],
              )
            : group,
    ]),
    _Load.empty => const AsyncData([]),
    _Load.loading => const AsyncLoading(),
    _Load.failed => AsyncError(Exception('연결 시간 초과'), StackTrace.empty),
  };
  // 할 일 입력 시트의 칸 여백. 칩을 누르면 고른 태그가 위에 모인다.
  // 새 태그·첫 태그 만들기를 누르면 앱에서는 태그 입력 시트가 열린다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: _TagDemo(key: ValueKey(longTag), tagGroups: tagGroups),
  );
}

/// 칩을 누르면 바로 골라지도록 고른 태그를 들고 있는다
class _TagDemo extends StatefulWidget {
  const _TagDemo({super.key, required this.tagGroups});

  final AsyncValue<List<TagGroupWithTags>> tagGroups;

  @override
  State<_TagDemo> createState() => _TagDemoState();
}

class _TagDemoState extends State<_TagDemo> {
  final _selected = {'tag-work', 'tag-health'};

  @override
  Widget build(BuildContext context) {
    return TodoTagPickerView(
      tagGroups: widget.tagGroups,
      selectedTagIds: _selected,
      onToggle: (id, selected) =>
          setState(() => selected ? _selected.add(id) : _selected.remove(id)),
      onCreateTag: (_) {},
    );
  }
}
