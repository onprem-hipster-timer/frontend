/// Domain 계층 템플릿 - 사용 예시
/// 이 파일은 참고용이며, 실제 구현시 해당 Feature 폴더에서 사용합니다.

/// 1. Entity 예시
class ScheduleEntity {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? description;

  ScheduleEntity({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
  });
}

/// 2. Repository (Abstract) 예시
abstract class ScheduleRepository {
  Future<List<ScheduleEntity>> getSchedules();
  Future<ScheduleEntity> getScheduleById(String id);
  Future<void> createSchedule(ScheduleEntity schedule);
  Future<void> updateSchedule(ScheduleEntity schedule);
  Future<void> deleteSchedule(String id);
}

/// 3. UseCase 예시 (선택사항)
class GetSchedulesUseCase {
  final ScheduleRepository repository;

  GetSchedulesUseCase(this.repository);

  Future<List<ScheduleEntity>> call() async {
    return repository.getSchedules();
  }
}
