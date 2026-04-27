import 'package:momeet/shared/api/rest/export.dart';

/// 테스트용 [ScheduleRead] 인스턴스를 생성하는 팩토리.
ScheduleRead makeSchedule({
  String id = 'schedule-1',
  String title = '테스트 일정',
  DateTime? startTime,
  DateTime? endTime,
  ScheduleState state = ScheduleState.planned,
  DateTime? createdAt,
  List<TagRead> tags = const [],
  String? description,
  String? tagGroupId,
  String? sourceTodoId,
  String? recurrenceRule,
}) {
  final now = DateTime.utc(2026, 4, 7, 10, 0);
  return ScheduleRead(
    id: id,
    title: title,
    startTime: startTime ?? now,
    endTime: endTime ?? now.add(const Duration(hours: 1)),
    state: state,
    createdAt: createdAt ?? now,
    tags: tags,
    description: description,
    tagGroupId: tagGroupId,
    sourceTodoId: sourceTodoId,
    recurrenceRule: recurrenceRule,
  );
}

/// 테스트용 [TagRead] 인스턴스를 생성하는 팩토리.
TagRead makeTag({
  String id = 'tag-1',
  String name = '테스트 태그',
  String color = '#FF5733',
  String groupId = 'group-1',
}) {
  final now = DateTime.utc(2026, 1, 1);
  return TagRead(
    id: id,
    name: name,
    color: color,
    groupId: groupId,
    createdAt: now,
    updatedAt: now,
  );
}
