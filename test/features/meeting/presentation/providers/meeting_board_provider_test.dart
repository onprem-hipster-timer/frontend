import 'dart:async';

import 'package:dio/dio.dart'
    show DioException, DioExceptionType, RequestOptions, Response;
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_autosave.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../meeting_fixtures.dart';

/// 서울 2027년 3월 1일 [hour]시 [minute]분의 UTC 시각
DateTime seoul(int hour, [int minute = 0]) =>
    DateTime.utc(2027, 3, 1, hour - 9, minute);

const wait = Duration(seconds: 1);

final provider = meetingBoardProvider('meeting-1');

/// 받은 저장 본문을 (시작, 끝) 목록으로
List<(DateTime, DateTime)> slotsOf(List<TimeSlotCreate> body) => [
  for (final slot in body) (slot.startTime.toUtc(), slot.endTime.toUtc()),
];

/// 3월 1일 열의 [rows]줄 칸(6시부터 30분)
List<MeetingCell> cells(MeetingBoardState state, Iterable<int> rows) => [
  for (final row in rows) state.board.grid.at(0, row)!,
];

const available = MeetingAnswer.available;
const unavailable = MeetingAnswer.unavailable;
const unanswered = MeetingAnswer.unanswered;

/// 3월 1일 열의 [rows]줄 칸을 [answer]로
Map<MeetingCell, MeetingAnswer> answers(
  MeetingBoardState state,
  Iterable<int> rows,
  MeetingAnswer answer,
) => {for (final cell in cells(state, rows)) cell: answer};

void main() {
  setUpAll(tz.initializeTimeZones);

  late FakeMeetingsClient meetings;

  setUp(() {
    meetings = FakeMeetingsClient(meeting: makeMeeting())
      ..availability = [
        availabilityOf('a', name: '민수', slots: [(seoul(6), seoul(8))]),
      ];
  });

  /// 화면처럼 provider를 듣는 컨테이너와 그 구독을 만들고 불러올 때까지 기다린다
  (ProviderContainer, ProviderSubscription<AsyncValue<MeetingBoardState>>) open(
    FakeAsync async, {
    String? name = '지현',
  }) {
    final container = ProviderContainer(
      overrides: meetingOverrides(meetings: meetings, name: name),
    );
    final subscription = container.listen(provider, (_, _) {});
    async.flushMicrotasks();
    return (container, subscription);
  }

  MeetingBoardState read(ProviderContainer container) =>
      container.read(provider).requireValue;

  test('미팅과 모든 참여자의 가능 시간을 불러와 다른 참여자가 되는 칸을 센다', () {
    fakeAsync((async) {
      final (container, _) = open(async);
      final state = read(container);

      expect(state.status, MeetingSaveStatus.idle);
      expect(state.board.me, isNull);
      expect(state.board.othersAt(state.board.grid.at(0, 0)!), {'a'});
      expect(meetings.availabilityReads, 1);
      container.dispose();
    });
  });

  test('처음 칠하면 기다렸다가 계정 이름으로 참여하고 맞닿은 칸을 한 구간으로 저장한다', () {
    fakeAsync((async) {
      final (container, _) = open(async);
      final notifier = container.read(provider.notifier);
      notifier.paint(answers(read(container), [6, 7, 8], available));

      expect(read(container).status, MeetingSaveStatus.saving);
      expect(
        read(container).board.answerAt(read(container).board.grid.at(0, 7)!),
        available,
      );
      expect(meetings.participations, isEmpty);

      async.elapse(wait);
      expect(meetings.participations, ['지현']);
      expect(meetings.puts.single.$1, 'participant-user-1');
      expect(slotsOf(meetings.puts.single.$2), [(seoul(9), seoul(10, 30))]);
      expect(read(container).status, MeetingSaveStatus.saved);
      expect(read(container).board.me?.displayName, '지현');
      expect(meetings.availabilityReads, 2, reason: '저장한 뒤 다시 받는다');
      container.dispose();
    });
  });

  test('불가능으로 칠한 칸은 unavailable로, 가능 칸과 겹치지 않게 함께 저장한다', () {
    fakeAsync((async) {
      meetings.availability.add(
        availabilityOf(
          'participant-user-1',
          userId: 'user-1',
          slots: [(seoul(6), seoul(8))],
        ),
      );
      final (container, _) = open(async);
      container
          .read(provider.notifier)
          .paint(answers(read(container), [1, 2], unavailable));
      async.elapse(wait);

      final body = meetings.puts.single.$2;
      List<(DateTime, DateTime)> of(TimeSlotKind kind) => slotsOf([
        for (final slot in body)
          if (slot.kind == kind) slot,
      ]);
      expect(of(TimeSlotKind.available), [
        (seoul(6), seoul(6, 30)),
        (seoul(7, 30), seoul(8)),
      ]);
      expect(of(TimeSlotKind.unavailable), [(seoul(6, 30), seoul(7, 30))]);
      expect(body.map((slot) => slot.toJson()['kind']).toSet(), {
        'available',
        'unavailable',
      });
      container.dispose();
    });
  });

  test('겹친다고 거절되면(422) 저장하지 못한 상태로 두고 다시 시도하면 다시 보낸다', () {
    fakeAsync((async) {
      final request = RequestOptions(
        path: '/v1/meetings/meeting-1/availability',
      );
      meetings.putError = DioException(
        requestOptions: request,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: request, statusCode: 422),
      );
      final (container, _) = open(async);
      final notifier = container.read(provider.notifier);
      notifier.paint(answers(read(container), [0], unavailable));
      async.elapse(wait);

      expect(read(container).status, MeetingSaveStatus.failed);
      expect(
        read(container).board.answerAt(read(container).board.grid.at(0, 0)!),
        unavailable,
      );

      notifier.retrySave();
      async.flushMicrotasks();
      expect(meetings.puts, hasLength(2));
      expect(meetings.puts.last.$2, meetings.puts.first.$2);
      expect(read(container).status, MeetingSaveStatus.saved);
      container.dispose();
    });
  });

  test('계정 이름이 없으면 참여자로 참여한다', () {
    fakeAsync((async) {
      final (container, _) = open(async, name: null);
      container
          .read(provider.notifier)
          .paint(answers(read(container), [0], available));
      async.elapse(wait);

      expect(meetings.participations, ['참여자']);
      container.dispose();
    });
  });

  test('이미 참여했으면 다시 참여하지 않고 저장된 시각 위에 칠한 칸을 더해 보낸다', () {
    fakeAsync((async) {
      meetings.availability.add(
        availabilityOf(
          'participant-user-1',
          userId: 'user-1',
          slots: [(seoul(6), seoul(7)), (seoul(20), seoul(21))],
        ),
      );
      final (container, _) = open(async);
      container
          .read(provider.notifier)
          .paint(answers(read(container), [2], available));
      async.elapse(wait);

      expect(meetings.participations, isEmpty);
      expect(slotsOf(meetings.puts.single.$2), [
        (seoul(6), seoul(7, 30)),
        (seoul(20), seoul(21)),
      ], reason: '격자 밖(20시)의 저장된 시각은 그대로 둔다');
      container.dispose();
    });
  });

  test('잇달아 칠하고 지우면 마지막으로 바꾼 뒤 한 번만, 최종 칸으로 저장한다', () {
    fakeAsync((async) {
      final (container, _) = open(async);
      final notifier = container.read(provider.notifier);
      for (final row in [0, 1, 2, 3]) {
        notifier.paint(answers(read(container), [row], available));
        async.elapse(const Duration(milliseconds: 200));
      }
      notifier.paint(answers(read(container), [1], unanswered));
      async.elapse(wait);

      expect(meetings.participations, hasLength(1));
      expect(meetings.puts, hasLength(1));
      expect(slotsOf(meetings.puts.single.$2), [
        (seoul(6), seoul(6, 30)),
        (seoul(7), seoul(8)),
      ]);
      container.dispose();
    });
  });

  test('칠한 칸을 모두 지우면 빈 목록을 저장한다', () {
    fakeAsync((async) {
      meetings.availability.add(
        availabilityOf(
          'participant-user-1',
          userId: 'user-1',
          slots: [(seoul(6), seoul(7))],
        ),
      );
      final (container, _) = open(async);
      container
          .read(provider.notifier)
          .paint(answers(read(container), [0, 1], unanswered));
      async.elapse(wait);

      expect(meetings.puts.single.$2, isEmpty);
      container.dispose();
    });
  });

  test('저장하지 못하면 칠한 칸을 남겨 두고 다시 시도하면 참여부터 이어서 저장한다', () {
    fakeAsync((async) {
      meetings.participateError = StateError('끊김');
      final (container, _) = open(async);
      final notifier = container.read(provider.notifier);
      notifier.paint(answers(read(container), [0], available));
      async.elapse(wait);

      expect(read(container).status, MeetingSaveStatus.failed);
      expect(meetings.puts, isEmpty);
      expect(
        read(container).board.answerAt(read(container).board.grid.at(0, 0)!),
        available,
      );

      notifier.retrySave();
      async.flushMicrotasks();
      expect(meetings.participations, ['지현', '지현']);
      expect(slotsOf(meetings.puts.single.$2), [(seoul(6), seoul(6, 30))]);
      expect(read(container).status, MeetingSaveStatus.saved);
      container.dispose();
    });
  });

  test('참여한 뒤 저장만 실패하면 다시 시도할 때 다시 참여하지 않는다', () {
    fakeAsync((async) {
      meetings.putError = StateError('끊김');
      final (container, _) = open(async);
      final notifier = container.read(provider.notifier);
      notifier.paint(answers(read(container), [0], available));
      async.elapse(wait);
      expect(read(container).status, MeetingSaveStatus.failed);

      notifier.paint(answers(read(container), [1], available));
      async.elapse(wait);

      expect(meetings.participations, hasLength(1));
      expect(slotsOf(meetings.puts.last.$2), [(seoul(6), seoul(7))]);
      expect(read(container).status, MeetingSaveStatus.saved);
      container.dispose();
    });
  });

  test('다시 받기가 실패해도 저장은 저장됨이다', () {
    fakeAsync((async) {
      final (container, _) = open(async);
      meetings.availabilityError = Exception('끊김');
      container
          .read(provider.notifier)
          .paint(answers(read(container), [0], available));
      async.elapse(wait);

      expect(read(container).status, MeetingSaveStatus.saved);
      expect(read(container).board.me, isNotNull);
      container.dispose();
    });
  });

  test('저장하기 전에 화면을 떠나도 기다리던 저장을 보내고, 끝나면 값을 버린다', () {
    fakeAsync((async) {
      final (container, subscription) = open(async);
      container
          .read(provider.notifier)
          .paint(answers(read(container), [0], available));
      subscription.close();
      async.flushMicrotasks();
      expect(container.exists(provider), isTrue);

      async.elapse(wait);
      expect(meetings.puts, hasLength(1));
      async.elapse(wait);
      expect(container.exists(provider), isFalse);
      container.dispose();
    });
  });

  test('저장하지 못한 채 떠나면 값을 버리지 않고 돌아와서 다시 시도할 수 있다', () {
    fakeAsync((async) {
      meetings.putError = StateError('끊김');
      final (container, subscription) = open(async);
      container
          .read(provider.notifier)
          .paint(answers(read(container), [0], available));
      async.elapse(wait);
      subscription.close();
      async.elapse(wait);

      expect(container.exists(provider), isTrue);
      final back = container.listen(provider, (_, _) {});
      expect(back.read().requireValue.status, MeetingSaveStatus.failed);
      expect(meetings.availabilityReads, 1, reason: '다시 불러오지 않는다');

      container.read(provider.notifier).retrySave();
      async.flushMicrotasks();
      expect(meetings.puts, hasLength(2));
      expect(read(container).status, MeetingSaveStatus.saved);
      container.dispose();
    });
  });

  test('이 모임에서 이름을 바꾸면 참여 요청을 새 이름으로 다시 보내고 참여자 이름이 바뀐다', () {
    fakeAsync((async) {
      meetings.availability.add(
        availabilityOf('participant-user-1', name: '지현', userId: 'user-1'),
      );
      final (container, _) = open(async);
      unawaited(container.read(provider.notifier).rename('  새 이름 '));
      async.flushMicrotasks();

      expect(meetings.participations, ['새 이름']);
      final board = read(container).board;
      expect(board.me?.displayName, '새 이름');
      expect(board.nameOf('participant-user-1'), '새 이름');
      container.dispose();
    });
  });

  test('아직 참여하지 않았을 때 칠한 칸은 계정 이름으로 사람 수에 든다', () {
    fakeAsync((async) {
      final (container, _) = open(async);
      container
          .read(provider.notifier)
          .paint(answers(read(container), [0], available));

      final board = read(container).board;
      expect(board.peopleAt(board.grid.at(0, 0)!), {
        'a',
        MeetingBoard.pendingSelfId,
      });
      container.dispose();
    });
  });

  group('주인의 참여자 빼기', () {
    setUp(() {
      meetings.availability = [
        availabilityOf('a', name: '민수', slots: [(seoul(6), seoul(8))]),
        availabilityOf(
          'g',
          name: '하준',
          guest: true,
          slots: [(seoul(6), seoul(8))],
        ),
      ];
    });

    List<String> shown(ProviderContainer container) => [
      for (final p in read(container).board.participants) p.id,
    ];

    Set<String> others(ProviderContainer container) {
      final board = read(container).board;
      return board.othersAt(board.grid.at(0, 0)!);
    }

    test('빼면 바로 화면에서 빠지고 요청은 확정할 때까지 보내지 않는다', () {
      fakeAsync((async) {
        final (container, _) = open(async);
        container.read(provider.notifier).remove('a');

        expect(shown(container), ['g']);
        expect(others(container), {'g'});
        async.elapse(const Duration(minutes: 1));
        expect(meetings.removedParticipants, isEmpty);
        container.dispose();
      });
    });

    test('되돌리면 다시 보이고 요청을 보내지 않으며, 그 뒤 확정해도 보내지 않는다', () {
      fakeAsync((async) {
        final (container, _) = open(async);
        final notifier = container.read(provider.notifier)..remove('a');

        notifier.undoRemove('a');
        expect(shown(container), ['a', 'g']);
        unawaited(notifier.confirmRemove('a'));
        async.flushMicrotasks();

        expect(meetings.removedParticipants, isEmpty);
        container.dispose();
      });
    });

    test('확정하면 참여자 id로 한 번만 보내고 다시 받은 뒤에도 빠져 있다', () {
      fakeAsync((async) {
        final (container, _) = open(async);
        final notifier = container.read(provider.notifier)..remove('g');

        unawaited(notifier.confirmRemove('g'));
        unawaited(notifier.confirmRemove('g'));
        async.flushMicrotasks();

        expect(meetings.removedParticipants, ['g'], reason: '게스트도 참여자 id로 뺀다');
        expect(meetings.availabilityReads, 2, reason: '뺀 뒤 다시 받는다');
        expect(shown(container), ['a']);
        container.dispose();
      });
    });

    test('보내지 못하면 다시 보이고 오류를 넘긴다', () {
      fakeAsync((async) {
        meetings.removeError = StateError('끊김');
        final (container, _) = open(async);
        final notifier = container.read(provider.notifier)..remove('a');

        Object? error;
        notifier.confirmRemove('a').catchError((Object e) => error = e);
        async.flushMicrotasks();

        expect(error, isA<StateError>());
        expect(shown(container), ['a', 'g']);
        expect(others(container), {'a', 'g'});
        container.dispose();
      });
    });

    test('이미 없는 참여자(404)면 뺀 것으로 본다', () {
      fakeAsync((async) {
        meetings.removeError = notFound('MeetingParticipantNotFoundError');
        final (container, _) = open(async);
        final notifier = container.read(provider.notifier)..remove('a');

        Object? error;
        notifier.confirmRemove('a').catchError((Object e) => error = e);
        async.flushMicrotasks();

        expect(error, isNull);
        expect(shown(container), ['g']);
        container.dispose();
      });
    });

    test('둘을 잇달아 빼면 각각 되돌리거나 보낸다', () {
      fakeAsync((async) {
        final (container, _) = open(async);
        final notifier = container.read(provider.notifier)
          ..remove('a')
          ..remove('g');
        expect(shown(container), isEmpty);
        expect(read(container).board.othersTotal, 0);

        unawaited(notifier.confirmRemove('a'));
        notifier.undoRemove('g');
        async.flushMicrotasks();

        expect(meetings.removedParticipants, ['a']);
        expect(shown(container), ['g']);
        container.dispose();
      });
    });

    test('빼기를 기다리는 동안 화면을 떠나도 값을 버리지 않고, 확정해 보낸 뒤에 버린다', () {
      fakeAsync((async) {
        final gate = meetings.removeGate = Completer<void>();
        final (container, subscription) = open(async);
        final notifier = container.read(provider.notifier)..remove('a');
        subscription.close();
        async.elapse(const Duration(minutes: 1));
        expect(container.exists(provider), isTrue);

        unawaited(notifier.confirmRemove('a'));
        async.flushMicrotasks();
        expect(meetings.removedParticipants, ['a']);
        expect(container.exists(provider), isTrue, reason: '보내는 중');

        gate.complete();
        async.flushMicrotasks();
        async.elapse(wait);
        expect(container.exists(provider), isFalse);
        container.dispose();
      });
    });

    test('되돌린 뒤 떠나면 값을 버린다', () {
      fakeAsync((async) {
        final (container, subscription) = open(async);
        container.read(provider.notifier)
          ..remove('a')
          ..undoRemove('a');
        subscription.close();
        async.elapse(wait);

        expect(container.exists(provider), isFalse);
        container.dispose();
      });
    });

    test('빼기를 기다리는 동안 칠한 것을 저장해도 빼기는 그대로 기다린다', () {
      fakeAsync((async) {
        final (container, subscription) = open(async);
        final notifier = container.read(provider.notifier)
          ..remove('a')
          ..paint(answers(read(container), [0], available));
        subscription.close();
        async.elapse(wait);

        expect(meetings.puts, hasLength(1));
        expect(container.exists(provider), isTrue, reason: '빼기를 기다린다');
        expect(shown(container), ['g', 'participant-user-1']);
        unawaited(notifier.confirmRemove('a'));
        async.flushMicrotasks();
        expect(meetings.removedParticipants, ['a']);
        container.dispose();
      });
    });
  });
}
