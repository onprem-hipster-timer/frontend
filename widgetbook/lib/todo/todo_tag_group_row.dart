import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form/todo_tag_group_row.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/tag_group_with_tags.dart';
import 'package:momeet_widgetbook/calendar/samples_plan.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '태그 그룹 줄', type: TodoTagGroupRow, path: '[할 일]')
Widget todoTagGroupRow(BuildContext context) {
  final knobs = context.knobs;
  final count = knobs.int.slider(
    label: '태그 수',
    description: '한 줄에 다 들어가지 않으면 옆으로 민다',
    initialValue: 4,
    min: 1,
    max: planTags.length,
  );
  final longGroup = knobs.boolean(label: '긴 그룹 이름');
  final longTag = knobs.boolean(label: '긴 태그 이름');
  final group = TagGroupWithTags(
    group: TagGroupRead(
      id: 'tag-group-life',
      name: longGroup ? '올해 꼭 챙기고 싶은 생활 습관과 취미 모음' : '생활',
      color: '#00897B',
      createdAt: planStamp,
      updatedAt: planStamp,
    ),
    tags: [if (longTag) planLongTag, ...planTags.take(count)],
  );
  // 할 일 폼 시트의 태그 칸 여백. 노브를 바꾸면 처음 고른 태그로 다시 시작한다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: _TagGroupDemo(
      key: ValueKey((count, longGroup, longTag)),
      group: group,
    ),
  );
}

/// 태그 칩을 누르면 바로 골라지도록 고른 태그를 들고 있는다
class _TagGroupDemo extends StatefulWidget {
  const _TagGroupDemo({super.key, required this.group});

  final TagGroupWithTags group;

  @override
  State<_TagGroupDemo> createState() => _TagGroupDemoState();
}

class _TagGroupDemoState extends State<_TagGroupDemo> {
  final _selected = {'tag-work', 'tag-health'};

  @override
  Widget build(BuildContext context) {
    return TodoTagGroupRow(
      group: widget.group,
      selectedTagIds: _selected,
      onToggle: (id, selected) =>
          setState(() => selected ? _selected.add(id) : _selected.remove(id)),
      onAdd: () {},
    );
  }
}
