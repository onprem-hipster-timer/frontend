/// WebSocket 서버 → 클라이언트 이벤트 공통 타입
abstract class TimerWsEvent {
  const TimerWsEvent();
}

/// 알 수 없는 타입 또는 파싱 실패
class TimerWsUnknown extends TimerWsEvent {
  const TimerWsUnknown({required this.rawType, this.payload});
  final String rawType;
  final Map<String, dynamic>? payload;
}
