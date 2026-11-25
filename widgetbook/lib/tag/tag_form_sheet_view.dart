import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncError, AsyncLoading, AsyncValue;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_form_sheet_view.dart';
import 'package:momeet/shared/domain/tag_group_with_tags.dart';
import 'package:momeet_widgetbook/calendar/samples_plan.dart';
import 'package:momeet_widgetbook/todo/samples_todo.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../shared/samples_shared.dart';

enum _Load { done, loading, failed }

@widgetbook.UseCase(name: '태그 입력 시트', type: TagFormSheetView, path: '[태그 관리]')
Widget tagFormSheetView(BuildContext context) {
  final knobs = context.knobs;
  final edit = knobs.boolean(
    label: '태그 수정',
    description: '끄면 새 태그 만들기. 수정은 지금 이름·색으로 채워 열고, 태그 그룹은 바꿀 수 없다',
  );
  final load = knobs.object.dropdown(
    label: '태그 그룹 상태',
    options: _Load.values,
    labelBuilder: (load) => switch (load) {
      _Load.done => '불러옴',
      _Load.loading => '불러오는 중',
      _Load.failed => '불러올 수 없음',
    },
  );
  final longGroup = knobs.boolean(
    label: '긴 태그 그룹 이름',
    description: '고른 태그 그룹의 이름이 길면 칸 안에서 줄인다',
  );
  final busy = knobs.boolean(
    label: '저장 중',
    description: '생성·수정을 누른 뒤 끝날 때까지 버튼에 진행 표시를 둔다',
  );
  final groups = [
    for (final group in sampleTagGroups)
      group.groupId == 'tag-group-life' && longGroup
          ? TagGroupWithTags(
              group: group.group.copyWith(name: '올해 꼭 챙기고 싶은 생활 습관과 취미 모음'),
              tags: group.tags,
            )
          : group,
  ];
  final AsyncValue<List<TagGroupWithTags>> value = switch (load) {
    _Load.done => AsyncData(groups),
    _Load.loading => const AsyncLoading(),
    _Load.failed => AsyncError(Exception('연결 시간 초과'), StackTrace.empty),
  };
  // 앱에서는 태그 관리 화면이나 할 일 입력 시트의 새 태그를 누르면 아래에서 올라온다.
  // 노브를 바꾸면 입력한 값을 버리고 처음부터 채운다
  return SheetPreview(
    child: TagFormSheetView(
      key: ValueKey((edit, load, longGroup)),
      tag: edit ? planTags[2].copyWith(groupId: 'tag-group-life') : null,
      defaultGroupId: 'tag-group-life',
      groups: value,
      busy: busy,
      onSubmit: (_, _, _) => Navigator.of(context).pop(),
    ),
  );
}
