import 'package:dio/dio.dart';
import 'package:momeet/core/network/timer_request.dart';
import 'package:momeet/features/timer/domain/timer_repository.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// [TimerRepository]의 REST API 기반 구현
///
/// [TimersClient]와 공유 설정용 [VisibilityClient]를 래핑하여 도메인 레이어에 데이터를 제공합니다.
/// HTTP 에러 처리, 기본 파라미터 설정 등을 캡슐화합니다.
///
/// 테스트: test/features/timer/data/timer_repository_impl_test.dart
class TimerRepositoryImpl implements TimerRepository {
  final TimersClient _client;
  final VisibilityClient _visibility;

  TimerRepositoryImpl(this._client, this._visibility);

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
      options: timerRequest(),
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
      options: timerRequest(),
    );
  }

  @override
  Future<TimerRead> getTimer(String timerId) async {
    return _client.getTimerV1TimersTimerIdGet(
      timerId: timerId,
      includeTodo: true,
      includeSchedule: true,
      options: timerRequest(),
    );
  }

  @override
  Future<TimerRead> createTimer(TimerCreate data) async {
    return _client.createTimerV1TimersPost(
      body: data,
      includeTodo: true,
      includeSchedule: true,
      options: timerRequest(),
    );
  }

  @override
  Future<TimerRead> pauseTimer(String timerId) async {
    return _client.pauseTimerV1TimersTimerIdPausePatch(
      timerId: timerId,
      includeTodo: true,
      includeSchedule: true,
      options: timerRequest(),
    );
  }

  @override
  Future<TimerRead> resumeTimer(String timerId) async {
    return _client.resumeTimerV1TimersTimerIdResumePatch(
      timerId: timerId,
      includeTodo: true,
      includeSchedule: true,
      options: timerRequest(),
    );
  }

  @override
  Future<TimerRead> stopTimer(String timerId) async {
    return _client.stopTimerV1TimersTimerIdStopPost(
      timerId: timerId,
      includeTodo: true,
      includeSchedule: true,
      options: timerRequest(),
    );
  }

  @override
  Future<TimerRead> updateTimer(String timerId, TimerUpdate data) async {
    return _client.updateTimerV1TimersTimerIdPatch(
      timerId: timerId,
      body: data,
      includeTodo: true,
      includeSchedule: true,
      options: timerRequest(),
    );
  }

  @override
  Future<void> deleteTimer(String timerId) async {
    await _client.deleteTimerV1TimersTimerIdDelete(
      timerId: timerId,
      options: timerRequest(),
    );
  }

  @override
  Future<VisibilityRead?> getVisibility(String timerId) async {
    try {
      return await _visibility
          .getVisibilityV1VisibilityResourceTypeResourceIdGet(
            resourceType: ResourceType.timer,
            resourceId: timerId,
          );
    } on DioException catch (error) {
      // 설정이 없으면 서버가 404로 답한다
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<VisibilityRead> setVisibility(String timerId, VisibilityUpdate data) {
    return _visibility.setVisibilityV1VisibilityResourceTypeResourceIdPut(
      resourceType: ResourceType.timer,
      resourceId: timerId,
      body: data,
    );
  }

  @override
  Future<void> clearVisibility(String timerId) {
    return _visibility.deleteVisibilityV1VisibilityResourceTypeResourceIdDelete(
      resourceType: ResourceType.timer,
      resourceId: timerId,
    );
  }

  @override
  Future<List<TimerRead>> listSharedTimers() async {
    return _client.listTimersV1TimersGet(
      scope: ResourceScope.shared,
      includeTodo: true,
      includeSchedule: true,
      options: timerRequest(),
    );
  }
}
