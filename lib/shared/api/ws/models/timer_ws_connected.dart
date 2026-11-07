import 'timer_ws_event.dart';

/// 연결됨 (connected). (재)연결마다 한 번 온다. 받으면 REST로 다시 맞춘다.
class TimerWsConnected extends TimerWsEvent {
  const TimerWsConnected();
}
