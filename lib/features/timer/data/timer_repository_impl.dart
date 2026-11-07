import 'package:momeet/core/network/timer_request.dart';
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
}
