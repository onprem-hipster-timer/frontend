import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_autosave.dart';

const delay = Duration(milliseconds: 600);

/// 보낸 값과 상태를 기록하는 저장 대역. [value]는 화면의 최신 값이다
class Harness {
  Harness() {
    autosave = MeetingAutosave(
      delay: delay,
      onStatus: statuses.add,
      save: () async {
        final sent = value;
        final gate = this.gate;
        if (gate != null) await gate.future;
        if (failNext) {
          failNext = false;
          throw StateError('저장 실패');
        }
        saved.add(sent);
      },
    );
  }

  late final MeetingAutosave autosave;
  var value = 0;
  final saved = <int>[];
  final statuses = <MeetingSaveStatus>[];
  var failNext = false;

  /// 설정하면 저장이 이것이 끝날 때까지 기다린다
  Completer<void>? gate;

  void change(int next) {
    value = next;
    autosave.changed();
  }
}

void main() {
  test('바꾸면 저장 중이고 기다린 뒤 한 번 저장해 저장됨이 된다', () {
    fakeAsync((async) {
      final h = Harness()..change(1);
      expect(h.statuses.last, MeetingSaveStatus.saving);
      expect(h.autosave.busy, isTrue);

      async.elapse(delay - const Duration(milliseconds: 1));
      expect(h.saved, isEmpty);

      async.elapse(const Duration(milliseconds: 1));
      expect(h.saved, [1]);
      expect(h.statuses.last, MeetingSaveStatus.saved);
      expect(h.autosave.busy, isFalse);
    });
  });

  test('잇달아 바꾸면 마지막으로 바꾼 뒤 기다렸다가 최신 값을 한 번만 저장한다', () {
    fakeAsync((async) {
      final h = Harness();
      for (var i = 1; i <= 5; i++) {
        h.change(i);
        async.elapse(const Duration(milliseconds: 300));
      }
      expect(h.saved, isEmpty);

      async.elapse(delay);
      expect(h.saved, [5]);
    });
  });

  test('저장하는 사이 바꾸면 끝난 뒤 최신 값으로 한 번 더 저장한다', () {
    fakeAsync((async) {
      final h = Harness()
        ..gate = Completer()
        ..change(1);
      async.elapse(delay);
      expect(h.saved, isEmpty, reason: '첫 저장이 응답을 기다린다');

      h.change(2);
      h.change(3);
      async.elapse(delay);
      expect(h.saved, isEmpty, reason: '저장 중에는 겹쳐 보내지 않는다');

      final first = h.gate!;
      h.gate = null;
      first.complete();
      async.flushMicrotasks();
      expect(h.saved, [1, 3]);
      expect(h.statuses.last, MeetingSaveStatus.saved);
    });
  });

  test('저장하는 사이 바꾸고 기다림이 남았으면 그 기다림이 끝날 때 저장한다', () {
    fakeAsync((async) {
      final h = Harness()
        ..gate = Completer()
        ..change(1);
      async.elapse(delay);
      h.change(2);
      final first = h.gate!;
      h.gate = null;
      first.complete();
      async.flushMicrotasks();
      expect(h.saved, [1]);
      expect(h.statuses.last, MeetingSaveStatus.saving);

      async.elapse(delay);
      expect(h.saved, [1, 2]);
    });
  });

  test('실패하면 바꾼 것을 남겨 두고 다시 시도하면 최신 값을 보낸다', () {
    fakeAsync((async) {
      final h = Harness()
        ..failNext = true
        ..change(1);
      async.elapse(delay);
      expect(h.saved, isEmpty);
      expect(h.statuses.last, MeetingSaveStatus.failed);
      expect(h.autosave.busy, isTrue);

      async.elapse(const Duration(minutes: 1));
      expect(h.saved, isEmpty, reason: '저절로 다시 보내지 않는다');

      h.value = 2;
      h.autosave.retry();
      async.flushMicrotasks();
      expect(h.saved, [2]);
      expect(h.statuses.last, MeetingSaveStatus.saved);
      expect(h.autosave.busy, isFalse);
    });
  });

  test('실패한 뒤 또 바꾸면 기다렸다가 함께 저장한다', () {
    fakeAsync((async) {
      final h = Harness()
        ..failNext = true
        ..change(1);
      async.elapse(delay);
      h.change(2);
      expect(h.statuses.last, MeetingSaveStatus.saving);

      async.elapse(delay);
      expect(h.saved, [2]);
      expect(h.statuses.last, MeetingSaveStatus.saved);
    });
  });

  test('저장하는 사이 바꾼 뒤 그 저장이 실패하면 남은 기다림이 끝날 때 다시 보낸다', () {
    fakeAsync((async) {
      final h = Harness()
        ..gate = Completer()
        ..failNext = true
        ..change(1);
      async.elapse(delay);
      h.change(2);
      final first = h.gate!;
      h.gate = null;
      first.complete();
      async.flushMicrotasks();
      expect(h.statuses.last, MeetingSaveStatus.saving, reason: '실패를 띄우지 않는다');

      async.elapse(delay);
      expect(h.saved, [2]);
      expect(h.statuses.last, MeetingSaveStatus.saved);
    });
  });

  test('저장할 것이 없거나 저장하는 중이면 다시 시도해도 보내지 않는다', () {
    fakeAsync((async) {
      final h = Harness()..autosave.retry();
      async.flushMicrotasks();
      expect(h.saved, isEmpty);
      expect(h.statuses, isEmpty);

      h
        ..gate = Completer()
        ..change(1);
      async.elapse(delay);
      h.autosave.retry();
      h.gate!.complete();
      h.gate = null;
      async.flushMicrotasks();
      expect(h.saved, [1]);
    });
  });

  test('다시 시도는 기다리지 않고 바로 보낸다', () {
    fakeAsync((async) {
      final h = Harness()..change(1);
      h.autosave.retry();
      async.flushMicrotasks();
      expect(h.saved, [1]);

      async.elapse(delay);
      expect(h.saved, [1], reason: '취소한 기다림이 또 보내지 않는다');
    });
  });

  test('버린 뒤에는 기다리던 저장을 보내지 않는다', () {
    fakeAsync((async) {
      final h = Harness()..change(1);
      h.autosave.dispose();
      async.elapse(delay);
      expect(h.saved, isEmpty);
    });
  });

  group('저장 마치기(flush)', () {
    test('저장할 것이 없으면 바로 끝났다고 한다', () {
      fakeAsync((async) {
        final h = Harness();
        bool? done;
        h.autosave.flush().then((value) => done = value);
        async.flushMicrotasks();
        expect(done, isTrue);
        expect(h.saved, isEmpty);
      });
    });

    test('기다리던 저장을 기다리지 않고 바로 보내고 끝나면 true다', () {
      fakeAsync((async) {
        final h = Harness()..change(1);
        bool? done;
        h.autosave.flush().then((value) => done = value);
        async.flushMicrotasks();
        expect(h.saved, [1], reason: '600ms를 기다리지 않는다');
        expect(done, isTrue);
        expect(h.statuses.last, MeetingSaveStatus.saved);
      });
    });

    test('보내는 중인 저장을 기다리고, 그사이 또 바꿨으면 그것까지 저장한 뒤 true다', () {
      fakeAsync((async) {
        final h = Harness()..gate = Completer<void>();
        h.change(1);
        async.elapse(delay);
        expect(h.autosave.busy, isTrue);

        bool? done;
        h.autosave.flush().then((value) => done = value);
        h.change(2);
        async.flushMicrotasks();
        expect(done, isNull, reason: '아직 보내는 중');

        final gate = h.gate!;
        h.gate = null;
        gate.complete();
        async.flushMicrotasks();
        expect(done, isNull, reason: '2를 아직 보내지 않았다');
        async.elapse(delay);
        expect(h.saved, [1, 2]);
        expect(done, isTrue);
      });
    });

    test('저장하지 못한 것을 다시 보내고, 또 실패하면 false다', () {
      fakeAsync((async) {
        final h = Harness()..failNext = true;
        h.change(1);
        async.elapse(delay);
        expect(h.statuses.last, MeetingSaveStatus.failed);

        h.failNext = true;
        bool? first;
        h.autosave.flush().then((value) => first = value);
        async.flushMicrotasks();
        expect(first, isFalse);
        expect(h.statuses.last, MeetingSaveStatus.failed);

        bool? second;
        h.autosave.flush().then((value) => second = value);
        async.flushMicrotasks();
        expect(second, isTrue);
        expect(h.saved, [1]);
      });
    });

    test('기다리는 동안 화면을 닫으면 false로 끝난다', () {
      fakeAsync((async) {
        final h = Harness()..gate = Completer<void>();
        h.change(1);
        async.elapse(delay);
        bool? done;
        h.autosave.flush().then((value) => done = value);
        h.autosave.dispose();
        async.flushMicrotasks();
        expect(done, isFalse);
      });
    });
  });
}
