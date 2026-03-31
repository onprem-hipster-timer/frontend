import 'package:momeet/shared/api/rest/export.dart';

/// 타이머 데이터 접근을 위한 추상 리포지토리
///
/// Presentation 레이어는 이 인터페이스에만 의존하며,
/// 실제 데이터 소스(REST API, WebSocket, 캐시 등)는 Data 레이어에서 구현합니다.
abstract class TimerRepository {
  /// 현재 사용자의 활성 타이머 조회 (RUNNING 또는 PAUSED)
  ///
  /// 활성 타이머가 없으면 null 반환.
  Future<TimerRead?> getActiveTimer();

  /// 타이머 히스토리 조회 (RUNNING, PAUSED, COMPLETED)
  Future<List<TimerRead>> getTimerHistory();

  /// 타이머 목록 조회 (필터 적용)
  Future<List<TimerRead>> listTimers({
    List<String>? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// 타이머 메타데이터 업데이트
  Future<TimerRead> updateTimer(String timerId, TimerUpdate data);

  /// 타이머 삭제
  Future<void> deleteTimer(String timerId);
}
