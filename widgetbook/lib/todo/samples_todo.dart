import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/tag_group_with_tags.dart';
import 'package:momeet_widgetbook/calendar/samples_plan.dart';

TodoGroupRead _todoGroup(
  String id,
  String name,
  String color, {
  bool isDefault = false,
}) => TodoGroupRead(
  id: id,
  name: name,
  color: color,
  isDefault: isDefault,
  createdAt: planStamp,
  updatedAt: planStamp,
);

/// 할 일 목록들. 서버처럼 기본 목록이 맨 앞이다
final sampleTodoGroups = [
  _todoGroup('todo-group-default', '기본 목록', '#607D8B', isDefault: true),
  _todoGroup('todo-group-1', '졸업 프로젝트', '#3F51B5'),
  _todoGroup('todo-group-2', '이사 준비', '#E64A19'),
  _todoGroup('todo-group-3', '운동 루틴', '#2E7D32'),
];

final sampleLongTodoGroup = _todoGroup(
  'todo-group-long',
  '4월 중간 발표 전까지 꼭 끝내야 하는 졸업 프로젝트 자료 정리',
  '#8E24AA',
);

TagGroupWithTags _tagGroup(
  String id,
  String name,
  String color,
  List<TagRead> tags,
) => TagGroupWithTags(
  group: TagGroupRead(
    id: id,
    name: name,
    color: color,
    createdAt: planStamp,
    updatedAt: planStamp,
  ),
  tags: [for (final tag in tags) tag.copyWith(groupId: id)],
);

/// 태그 그룹과 그 안의 태그들
final sampleTagGroups = [
  _tagGroup('tag-group-work', '일', '#3F51B5', planTags.sublist(0, 2)),
  _tagGroup('tag-group-life', '생활', '#00897B', planTags.sublist(2, 6)),
  _tagGroup('tag-group-free', '여가', '#8E24AA', planTags.sublist(6)),
];
