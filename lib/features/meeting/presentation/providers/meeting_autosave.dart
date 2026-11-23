import 'dart:async';

/// 내 가능 시간의 저장 상태
enum MeetingSaveStatus {
  /// 이 화면에서 바꾼 것이 없다
  idle,

  /// 바꾼 뒤 저장을 기다리거나 저장하는 중이다
  saving,

  /// 마지막으로 바꾼 것까지 저장했다
  saved,

  /// 저장하지 못했다. 바꾼 것은 그대로 있고 [MeetingAutosave.flush]나 또 바꾸면 다시 보낸다
  failed,
}

/// 바뀔 때마다 [delay]만큼 기다렸다가 한 번 저장한다. 저장하는 사이 또 바뀌면 끝난 뒤 한 번 더 저장한다.
///
/// [save]는 부르는 때의 최신 값을 보낸다. 실패하면 바뀐 것을 남겨 두고 [flush]나 다음 [changed]가 다시 보낸다.
/// [flush]는 기다리지 않고 남은 것을 저장하고 그 결과를 돌려준다('저장하기').
///
/// 테스트: test/features/meeting/presentation/providers/meeting_autosave_test.dart
class MeetingAutosave {
  MeetingAutosave({
    required this.save,
    required this.onStatus,
    this.delay = const Duration(milliseconds: 600),
  });

  final Future<void> Function() save;
  final void Function(MeetingSaveStatus status) onStatus;
  final Duration delay;

  Timer? _timer;
  var _dirty = false;
  var _saving = false;
  var _disposed = false;

  /// [flush]를 부르고 결과를 기다리는 쪽
  final _waiters = <Completer<bool>>[];

  /// 아직 저장하지 않은 것이 있거나 저장하는 중이다
  bool get busy => _dirty || _saving;

  /// 값이 바뀌었다. [delay] 안에 또 바뀌면 기다림을 다시 시작한다
  void changed() {
    _dirty = true;
    _timer?.cancel();
    _timer = Timer(delay, _flush);
    onStatus(MeetingSaveStatus.saving);
  }

  /// 기다리지 않고 남은 것을 모두 저장한다. 보내는 중이면 그것을(그사이 또 바뀌었으면 그것까지) 기다리고,
  /// 저장하지 못한 것은 다시 보낸다. 모두 저장했으면 true, 저장하지 못했거나 그사이 닫혔으면 false다
  Future<bool> flush() {
    if (!busy) return Future.value(true);
    final waiter = Completer<bool>();
    _waiters.add(waiter);
    if (!_saving) {
      _timer?.cancel();
      unawaited(_flush());
    }
    return waiter.future;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _answer(false);
  }

  void _answer(bool saved) {
    for (final waiter in _waiters) {
      waiter.complete(saved);
    }
    _waiters.clear();
  }

  Future<void> _flush() async {
    _timer = null;
    if (_disposed || _saving || !_dirty) return;
    _dirty = false;
    _saving = true;
    onStatus(MeetingSaveStatus.saving);
    try {
      await save();
    } catch (_) {
      _saving = false;
      _dirty = true;
      // 저장하는 사이 또 바뀌었으면 곧 다시 보낸다
      if (!_disposed && _timer == null) {
        onStatus(MeetingSaveStatus.failed);
        _answer(false);
      }
      return;
    }
    _saving = false;
    if (_disposed) return;
    if (!_dirty) {
      onStatus(MeetingSaveStatus.saved);
      _answer(true);
    } else if (_timer == null) {
      unawaited(_flush());
    }
  }
}
