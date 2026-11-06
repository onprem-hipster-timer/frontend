import 'package:momeet/shared/api/rest/export.dart';

/// 타이머 데이터 접근을 위한 추상 리포지토리
///
/// Presentation 레이어는 이 인터페이스에만 의존하며,
/// 실제 데이터 소스(REST API, WebSocket, 캐시 등)는 Data 레이어에서 구현합니다.
abstract class TimerRepository {
  /// 타이머 히스토리 조회 (RUNNING, PAUSED, COMPLETED)
  Future<List<TimerRead>> getTimerHistory();

  /// 타이머 목록 조회 (필터 적용)
  Future<List<TimerRead>> listTimers({
    List<String>? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// 타이머 생성 및 시작. 시작된 타이머를 돌려준다.
  Future<TimerRead> createTimer(TimerCreate data);

  /// 타이머 일시정지 (RUNNING → PAUSED)
  Future<TimerRead> pauseTimer(String timerId);

  /// 타이머 재개 (PAUSED → RUNNING)
  Future<TimerRead> resumeTimer(String timerId);

  /// 타이머 종료 (RUNNING·PAUSED → COMPLETED)
  Future<TimerRead> stopTimer(String timerId);

  /// 타이머 메타데이터 업데이트
  Future<TimerRead> updateTimer(String timerId, TimerUpdate data);

  /// 타이머 삭제
  Future<void> deleteTimer(String timerId);
}
