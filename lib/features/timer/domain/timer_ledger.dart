import 'package:momeet/shared/api/rest/export.dart';

/// 앱이 가진 내 타이머
///
/// REST 응답과 실시간 이벤트를 같은 규칙으로 반영한다.
/// - `updated_at`이 본 적 있는 값보다 이전이면 버리고, 같거나 나중이면 반영한다.
///   다시 맞추기로 목록에서 뺀 타이머의 `updated_at`도 기억한다
/// - 삭제된 타이머 ID는 기록해 두고, 그 뒤에 오는 같은 ID는 버린다
/// - 실시간 이벤트의 타이머에는 관계 필드(`tags`·`schedule`·`todo`·`is_shared`·`visibility_level`)가 없다.
///   이벤트는 타이머 자체 필드만 바꾸고, 관계 필드는 관계를 포함해 읽은 REST 응답으로 채운다
///
/// 규칙: backend docs/development/realtime-adapter.ko.md 5장
/// 테스트: test/features/timer/domain/timer_ledger_test.dart
class TimerLedger {
  final _timers = <String, TimerRead>{};

  /// 타이머별로 본 가장 나중 `updated_at`
  final _updatedAt = <String, DateTime>{};
  final _deleted = <String>{};

  /// 관계 필드를 REST로 다시 읽어야 하는 타이머 ID
  final _needsRead = <String>{};

  /// 활성(RUNNING·PAUSED) 타이머. 최근에 시작한 순
  List<TimerRead> get active =>
      _timers.values.where(_isActive).toList()
        ..sort((a, b) => _startedOf(b).compareTo(_startedOf(a)));

  /// 가진 [timerId] 타이머. 없으면 null
  TimerRead? operator [](String timerId) => _timers[timerId];

  /// 가진 [timerId] 타이머를 관계를 포함해 다시 읽어 [apply]해야 하면 true
  bool needsRead(String timerId) =>
      _timers.containsKey(timerId) && _needsRead.contains(timerId);

  /// 관계를 포함해 읽은 REST 응답 [timer]를 반영한다.
  void apply(TimerRead timer) {
    if (!_accept(timer)) return;
    _timers[timer.id] = timer;
    _needsRead.remove(timer.id);
  }

  /// 명령 응답 전에 [timer]를 먼저 보인다.
  ///
  /// `updated_at` 기록을 바꾸지 않으므로 같거나 나중 `updated_at`의 응답·이벤트가 덮는다.
  /// 가진 적 없거나 지운 타이머면 무시한다.
  void showPending(TimerRead timer) {
    if (!_timers.containsKey(timer.id)) return;
    _timers[timer.id] = timer;
  }

  /// [showPending]한 [pending]이 아직 그대로면 [previous]로 되돌린다.
  ///
  /// 그 사이 응답·이벤트가 덮었으면 그 값을 둔다. 그 사이 [updateTodo]로 바뀐 todo는 둔다.
  void revertPending(TimerRead pending, TimerRead previous) {
    final shown = _timers[pending.id];
    if (shown == null || shown.copyWith(todo: pending.todo) != pending) return;
    _timers[pending.id] = shown.todo == pending.todo
        ? previous
        : previous.copyWith(todo: shown.todo);
  }

  /// 실시간 이벤트의 [timer]를 반영한다.
  ///
  /// 타이머 자체 필드만 바꾸고 가진 관계 필드는 둔다. `schedule_id`·`todo_id`가 바뀌었으면
  /// 가진 `schedule`·`todo`는 버린다. 처음 보는 타이머는 그대로 넣는다.
  /// [relationsChanged]면 ID가 같아도 가진 관계 필드가 낡았다고 본다.
  /// 관계 필드가 비었거나 낡아 그 타이머를 REST로 다시 읽어 [apply]해야 하면 true를 돌려준다.
  /// [apply]로 채우기 전까지는 이후 이벤트에도 true다.
  bool applyPartial(TimerRead timer, {bool relationsChanged = false}) {
    if (!_accept(timer)) return false;
    final held = _timers[timer.id];
    if (held == null) {
      _timers[timer.id] = timer;
      _needsRead.add(timer.id);
      return true;
    }
    final scheduleChanged = timer.scheduleId != held.scheduleId;
    final todoChanged = timer.todoId != held.todoId;
    _timers[timer.id] = timer.copyWith(
      tags: held.tags,
      isShared: held.isShared,
      visibilityLevel: held.visibilityLevel,
      schedule: scheduleChanged ? null : held.schedule,
      todo: todoChanged ? null : held.todo,
    );
    if (relationsChanged || scheduleChanged || todoChanged) {
      _needsRead.add(timer.id);
    }
    return _needsRead.contains(timer.id);
  }

  /// 바뀐 [todo]를 그 Todo에 연결된 타이머에 반영한다.
  ///
  /// 타이머가 바뀐 것이 아니라 `updated_at` 규칙을 거치지 않는다.
  void updateTodo(TodoRead todo) {
    _timers.updateAll(
      (_, timer) =>
          timer.todoId == todo.id ? timer.copyWith(todo: todo) : timer,
    );
  }

  /// 지운 타이머가 아니고 `updated_at`이 본 값보다 이전이 아니면 그 `updated_at`을 기억하고 true
  bool _accept(TimerRead timer) {
    if (_deleted.contains(timer.id)) return false;
    final seen = _updatedAt[timer.id];
    if (seen != null && timer.updatedAt.isBefore(seen)) return false;
    _updatedAt[timer.id] = timer.updatedAt;
    return true;
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
