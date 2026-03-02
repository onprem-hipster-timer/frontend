import 'package:dio/dio.dart';
import 'package:momeet/features/timer/domain/timer_repository.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// [TimerRepository]의 REST API 기반 구현
///
/// [TimersClient]를 래핑하여 도메인 레이어에 데이터를 제공합니다.
/// HTTP 에러 처리, 기본 파라미터 설정 등을 캡슐화합니다.
class TimerRepositoryImpl implements TimerRepository {
  final TimersClient _client;

  TimerRepositoryImpl(this._client);

  @override
  Future<TimerRead?> getActiveTimer() async {
    try {
      return await _client.getUserActiveTimerV1TimersActiveGet(
        includeTodo: true,
        includeSchedule: true,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<TimerRead>> getTimerHistory() async {
    return _client.listTimersV1TimersGet(
      status: [
        TimerStatus.running.json!,
        TimerStatus.paused.json!,
        TimerStatus.completed.json!,
      ],
      includeTodo: true,
      includeSchedule: true,
    );
  }

  @override
  Future<List<TimerRead>> listTimers({
    List<String>? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _client.listTimersV1TimersGet(
      status: status,
      type: type,
      startDate: startDate,
      endDate: endDate,
      includeTodo: true,
      includeSchedule: true,
    );
  }

  @override
  Future<TimerRead> updateTimer(String timerId, TimerUpdate data) async {
    return _client.updateTimerV1TimersTimerIdPatch(
      timerId: timerId,
      body: data,
    );
  }

  @override
  Future<void> deleteTimer(String timerId) async {
    await _client.deleteTimerV1TimersTimerIdDelete(timerId: timerId);
  }
}
