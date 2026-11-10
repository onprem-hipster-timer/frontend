import 'package:momeet/shared/api/rest/export.dart';

/// 테스트용 [TimerRead] 인스턴스를 생성하는 팩토리.
TimerRead makeTimer({
  required String id,
  required TimerStatus status,
  DateTime? startedAt,
  DateTime? createdAt,
  int allocatedDuration = 3600,
  int elapsedTime = 0,
}) {
  final ca = createdAt ?? DateTime.utc(2026, 1, 1);
  return TimerRead(
    id: id,
    allocatedDuration: allocatedDuration,
    elapsedTime: elapsedTime,
    status: status,
    createdAt: ca,
    updatedAt: ca,
    startedAt: startedAt,
  );
}

/// 테스트용 타이머 공유 설정 [VisibilityRead]를 생성하는 팩토리.
VisibilityRead makeVisibility({
  String timerId = 'timer-1',
  required VisibilityLevel level,
  List<String> allowedUserIds = const [],
  List<String> allowedEmails = const [],
  List<String> allowedDomains = const [],
}) => VisibilityRead(
  id: 'visibility-$timerId',
  resourceType: ResourceType.timer,
  resourceId: timerId,
  ownerId: 'me',
  level: level,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
  allowedUserIds: allowedUserIds,
  allowedEmails: allowedEmails,
  allowedDomains: allowedDomains,
);

/// 테스트용 [FriendRead] 인스턴스를 생성하는 팩토리.
FriendRead makeFriend(String userId, {String? displayName}) => FriendRead(
  userId: userId,
  friendshipId: 'friendship-$userId',
  since: DateTime.utc(2026, 1, 1),
  displayName: displayName,
);

/// 테스트용 [TodoRead] 인스턴스를 생성하는 팩토리.
TodoRead makeTodo({String id = 'todo-1'}) => TodoRead(
  id: id,
  title: '테스트 할 일',
  tagGroupId: 'group-1',
  status: TodoStatus.unscheduled,
  createdAt: DateTime.utc(2026, 1, 1),
);
