import 'dart:async';

import 'package:momeet/features/timer/domain/timer_repository.dart';
import 'package:momeet/shared/api/rest/export.dart';

import 'timer_fixtures.dart';

/// 타이머 REST 호출을 기록하는 리포지토리
class FakeTimerRepository implements TimerRepository {
  /// 호출 순서 (`create`, `pause:<id>`, `list` 등)
  final calls = <String>[];
  TimerCreate? created;
  TimerUpdate? updated;

  /// 마지막으로 저장한 공유 설정 (setVisibility)
  VisibilityUpdate? visibilityUpdate;

  /// 설정하면 명령과 공유 설정 저장이 이 예외를 던진다
  Object? error;

  /// 설정하면 명령과 공유 설정 저장이 이 Future가 끝날 때까지 응답하지 않는다
  Future<void>? gate;

  /// 명령 응답. 기본은 `timer-1`이 명령에 맞는 상태가 된 것
  TimerRead Function(String timerId, TimerStatus status) respond =
      (timerId, status) => makeTimer(id: timerId, status: status);

  /// 활성 타이머 목록 조회(listTimers) 응답
  Future<List<TimerRead>> Function() listActive = () async => [];

  /// 타이머 하나 조회(getTimer) 응답. 기본은 실패
  Future<TimerRead> Function(String timerId) getOne = (timerId) async =>
      throw Exception('404');

  /// 공유 설정 조회(getVisibility) 응답. 기본은 설정 없음(비공개)
  Future<VisibilityRead?> Function(String timerId) visibilityOf =
      (timerId) async => null;

  /// 공유받은 타이머 목록 조회(listSharedTimers) 응답
  Future<List<TimerRead>> Function() listShared = () async => [];

  Future<TimerRead> _command(
    String call,
    String timerId,
    TimerStatus status,
  ) async {
    calls.add(call);
    await gate;
    if (error != null) throw error!;
    return respond(timerId, status);
  }

  @override
  Future<TimerRead> createTimer(TimerCreate data) async {
    created = data;
    return _command('create', 'timer-1', TimerStatus.running);
  }

  @override
  Future<TimerRead> pauseTimer(String timerId) =>
      _command('pause:$timerId', timerId, TimerStatus.paused);

  @override
  Future<TimerRead> resumeTimer(String timerId) =>
      _command('resume:$timerId', timerId, TimerStatus.running);

  @override
  Future<TimerRead> stopTimer(String timerId) =>
      _command('stop:$timerId', timerId, TimerStatus.completed);

  @override
  Future<List<TimerRead>> listTimers({
    List<String>? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    calls.add('list');
    return listActive();
  }

  @override
  Future<TimerRead> getTimer(String timerId) {
    calls.add('get:$timerId');
    return getOne(timerId);
  }

  @override
  Future<List<TimerRead>> getTimerHistory() async => [];

  @override
  Future<TimerRead> updateTimer(String timerId, TimerUpdate data) {
    updated = data;
    return _command('update:$timerId', timerId, TimerStatus.paused);
  }

  @override
  Future<void> deleteTimer(String timerId) => throw UnimplementedError();

  @override
  Future<VisibilityRead?> getVisibility(String timerId) {
    calls.add('visibility:$timerId');
    return visibilityOf(timerId);
  }

  @override
  Future<VisibilityRead> setVisibility(
    String timerId,
    VisibilityUpdate data,
  ) async {
    calls.add('setVisibility:$timerId');
    visibilityUpdate = data;
    await gate;
    if (error != null) throw error!;
    return makeVisibility(
      timerId: timerId,
      level: data.level,
      allowedUserIds: data.allowedUserIds ?? const [],
      allowedEmails: data.allowedEmails ?? const [],
      allowedDomains: data.allowedDomains ?? const [],
    );
  }

  @override
  Future<void> clearVisibility(String timerId) async {
    calls.add('clearVisibility:$timerId');
    await gate;
    if (error != null) throw error!;
  }

  @override
  Future<List<TimerRead>> listSharedTimers() {
    calls.add('listShared');
    return listShared();
  }
}
