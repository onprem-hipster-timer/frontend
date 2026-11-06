import 'package:momeet/shared/api/rest/export.dart';

/// 앱이 가진 내 타이머
///
/// REST 응답과 실시간 이벤트를 같은 규칙으로 반영한다.
/// - `updated_at`이 본 적 있는 값보다 이전이면 버리고, 같거나 나중이면 반영한다.
///   다시 맞추기로 목록에서 뺀 타이머의 `updated_at`도 기억한다
/// - 삭제된 타이머 ID는 기록해 두고, 그 뒤에 오는 같은 ID는 버린다
///
/// 규칙: backend docs/development/realtime-adapter.ko.md 5장
/// 테스트: test/features/timer/domain/timer_ledger_test.dart
class TimerLedger {
  final _timers = <String, TimerRead>{};

  /// 타이머별로 본 가장 나중 `updated_at`
  final _updatedAt = <String, DateTime>{};
  final _deleted = <String>{};

  /// 활성(RUNNING·PAUSED) 타이머. 최근에 시작한 순
  List<TimerRead> get active =>
      _timers.values.where(_isActive).toList()
        ..sort((a, b) => _startedOf(b).compareTo(_startedOf(a)));

  /// [timer]를 반영한다.
  void apply(TimerRead timer) {
    if (_deleted.contains(timer.id)) return;
    final seen = _updatedAt[timer.id];
    if (seen != null && timer.updatedAt.isBefore(seen)) return;
    _updatedAt[timer.id] = timer.updatedAt;
    _timers[timer.id] = timer;
  }

  /// [timerId]를 지운 것으로 기록한다.
  void delete(String timerId) {
    _deleted.add(timerId);
    _timers.remove(timerId);
  }

  /// REST로 받은 활성 타이머 목록 [active]로 다시 맞춘다.
  ///
  /// 가진 활성 타이머가 목록에 없으면 그 사이 끝났거나 지워진 것이라 버린다.
  void resync(List<TimerRead> active) {
    final ids = {for (final timer in active) timer.id};
    _timers.removeWhere((id, timer) => _isActive(timer) && !ids.contains(id));
    active.forEach(apply);
  }

  static bool _isActive(TimerRead timer) =>
      timer.status == TimerStatus.running || timer.status == TimerStatus.paused;

  static DateTime _startedOf(TimerRead timer) =>
      timer.startedAt ?? timer.createdAt;
}
