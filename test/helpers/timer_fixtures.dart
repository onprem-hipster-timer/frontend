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
