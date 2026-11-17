import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/domain/meeting_runs.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../meeting_fixtures.dart';

/// 서울 2027년 3월 1일 [hour]시 [minute]분의 UTC 시각
DateTime seoul(int hour, [int minute = 0]) =>
    DateTime.utc(2027, 3, 1, hour - 9, minute);

/// 3월 1~5일 6~18시 30분 칸 미팅에서 [userId]로 본 화면
MeetingBoard boardOf(
  List<AvailabilityRead> availability, {
  String? userId = 'user-1',
  String ownerId = 'owner-1',
}) => MeetingBoard(
  meeting: makeMeeting(ownerId: ownerId),
  availability: availability,
  userId: userId,
  selfName: '지현',
);

void main() {
  setUpAll(tz.initializeTimeZones);

  test('주인을 맨 앞에 두고 나머지는 받은 순서다', () {
    final board = boardOf([
      availabilityOf('a'),
      availabilityOf('b'),
      availabilityOf('owner', userId: 'owner-1', owner: true),
    ]);

    expect([for (final p in board.participants) p.id], ['owner', 'a', 'b']);
  });

  test('주인은 is_owner로 가린다: 회원 id가 비어 있는 응답에서도 맨 앞이다', () {
    final board = MeetingBoard(
      meeting: makeMeeting().copyWith(ownerId: null),
      availability: [
        availabilityOf('g', guest: true),
        availabilityOf('a', userId: null),
        availabilityOf('owner', owner: true).copyWith.participant(userId: null),
      ],
      userId: null,
      selfName: '참여자',
    );

    expect([for (final p in board.participants) p.id], ['owner', 'g', 'a']);
  });

  test('회원 id가 주인 id와 같아도 is_owner가 아니면 주인으로 옮기지 않는다', () {
    final board = boardOf([
      availabilityOf('a'),
      availabilityOf('b', userId: 'owner-1'),
    ]);

    expect([for (final p in board.participants) p.id], ['a', 'b']);
  });

  test('주인이 참여하지 않았으면 받은 순서 그대로다', () {
    final board = boardOf([
      availabilityOf('b'),
      availabilityOf('g', guest: true),
      availabilityOf('a'),
    ]);

    expect([for (final p in board.participants) p.id], ['b', 'g', 'a']);
  });

  test('안 되는 구간은 되는 사람으로 세지 않고 안 되는 사람으로 센다', () {
    final board = boardOf([
      availabilityOf('a', unavailable: [(seoul(6), seoul(7))]),
      availabilityOf('b', slots: [(seoul(6), seoul(7))]),
    ]);
    final cell = board.grid.at(0, 0)!;

    expect(board.othersAt(cell), {'b'});
    expect(board.othersCountAt(cell), 1);
    expect(board.othersUnavailableAt(cell), {'a'});
    expect(board.othersUnavailableCountAt(cell), 1);
  });

  test('내 안 되는 구간은 불가능 칸이고 되는 사람에 들지 않는다', () {
    final board = boardOf([
      availabilityOf('a', slots: [(seoul(6), seoul(7))]),
      availabilityOf(
        'me',
        userId: 'user-1',
        slots: [(seoul(7), seoul(8))],
        unavailable: [(seoul(6), seoul(7))],
      ),
    ]);
    final cell = board.grid.at(0, 0)!;

    expect(board.answerAt(cell), MeetingAnswer.unavailable);
    expect(board.answerAt(board.grid.at(0, 2)!), MeetingAnswer.available);
    expect(board.peopleAt(cell), {'a'});
  });

  test('안 되는 사람이 바뀌는 곳에서 후보를 나누고, 후보마다 내내 안 되는 사람을 담는다(빼는 중인 참여자는 빼고)', () {
    final board = boardOf([
      availabilityOf('a', slots: [(seoul(6), seoul(7))]),
      availabilityOf('b', slots: [(seoul(6), seoul(7))]),
      availabilityOf('c', unavailable: [(seoul(6, 30), seoul(7))]),
      availabilityOf('d', unavailable: [(seoul(6), seoul(6, 30))]),
      availabilityOf('e', unavailable: [(seoul(9), seoul(10))]),
      availabilityOf(
        'me',
        userId: 'user-1',
        unavailable: [(seoul(6, 30), seoul(7))],
      ),
    ]).withRemoving({'d'});
    final runs = board.runs(MeetingRunOrder.date);

    expect(
      [for (final run in runs) run.people],
      [
        {'a', 'b'},
        {'a', 'b'},
      ],
    );
    expect(
      [for (final run in runs) run.unavailable],
      [
        <String>{},
        {'c', 'me'},
      ],
    );
  });

  test('로그인한 사람의 참여자가 나이고 그 가능 시간이 내 칸이다', () {
    final board = boardOf([
      availabilityOf('a', slots: [(seoul(6), seoul(7))]),
      availabilityOf('me', userId: 'user-1', slots: [(seoul(9), seoul(10))]),
    ]);

    expect(board.me?.id, 'me');
    expect(board.othersTotal, 1);
    expect(board.answerAt(board.grid.at(0, 6)!), MeetingAnswer.available);
    expect(board.answerAt(board.grid.at(0, 0)!), MeetingAnswer.unanswered);
  });

  test('칸마다 되는 다른 참여자는 칸을 모두 덮은 사람만이고 나는 빠진다', () {
    final board = boardOf([
      availabilityOf('a', slots: [(seoul(6), seoul(7))]),
      availabilityOf('b', slots: [(seoul(6, 10), seoul(7))]),
      availabilityOf('me', userId: 'user-1', slots: [(seoul(6), seoul(7))]),
    ]);

    expect(board.othersAt(board.grid.at(0, 0)!), {'a'});
    expect(board.othersAt(board.grid.at(0, 1)!), {'a', 'b'});
    expect(board.othersAt(board.grid.at(0, 2)!), isEmpty);
    expect(board.peopleAt(board.grid.at(0, 1)!), {'a', 'b', 'me'});
  });

  test('참여하지 않은 채 칠한 칸에는 아직 참여하지 않은 나로 들고 이름은 계정 이름이다', () {
    var board = boardOf([
      availabilityOf('a', slots: [(seoul(6), seoul(7))]),
    ]);
    final cell = board.grid.at(0, 0)!;
    board = board.withMine(
      board.mine.paint({cell.span: MeetingAnswer.available}),
    );

    expect(board.me, isNull);
    expect(board.peopleAt(cell), {'a', MeetingBoard.pendingSelfId});
    expect(board.nameOf(MeetingBoard.pendingSelfId), '지현');
    expect(board.isSelf(MeetingBoard.pendingSelfId), isTrue);
    expect(board.runs(MeetingRunOrder.people).single.people, hasLength(2));
  });

  test('참여자가 나 하나면 칸이 진해지지 않고 후보도 없다', () {
    var board = boardOf([availabilityOf('me', userId: 'user-1')]);
    board = board.withMine(
      board.mine.paint({
        for (final cell in board.grid.cells) cell.span: MeetingAnswer.available,
      }),
    );

    expect(board.othersTotal, 0);
    expect(board.runs(MeetingRunOrder.people), isEmpty);
  });

  test('아무도 없는 모임은 참여자도 후보도 없다', () {
    final board = boardOf([]);

    expect(board.participants, isEmpty);
    expect(board.othersTotal, 0);
    expect(board.runs(MeetingRunOrder.people), isEmpty);
  });

  test('참여하면 나를 맨 뒤에 넣고, 이름을 바꾸면 그 자리에서 바꾼다', () {
    final joined = ParticipantRead(
      id: 'me',
      meetingId: 'meeting-1',
      displayName: '지현',
      createdAt: DateTime.utc(2027),
      userId: 'user-1',
    );
    var board = boardOf([
      availabilityOf('owner', userId: 'owner-1', owner: true),
      availabilityOf('a'),
    ]);
    board = board.withSelf(joined);

    expect([for (final p in board.participants) p.id], ['owner', 'a', 'me']);
    expect(board.me, joined);

    board = board.withSelf(joined.copyWith(displayName: '지현2'));
    expect(
      [for (final p in board.participants) p.displayName],
      ['owner', 'a', '지현2'],
    );
    expect(board.nameOf('me'), '지현2');
  });

  test('내가 주인이면 참여하자마자 맨 앞이다', () {
    final board = boardOf([availabilityOf('a')], ownerId: 'user-1').withSelf(
      ParticipantRead(
        id: 'me',
        meetingId: 'meeting-1',
        displayName: '지현',
        createdAt: DateTime.utc(2027),
        isOwner: true,
        userId: 'user-1',
      ),
    );

    expect([for (final p in board.participants) p.id], ['me', 'a']);
  });

  test('가능 시간을 다시 받으면 다른 참여자를 새로 세고 칠하고 지운 칸은 그대로 덮는다', () {
    var board = boardOf([
      availabilityOf('me', userId: 'user-1', slots: [(seoul(6), seoul(7))]),
    ]);
    final first = board.grid.at(0, 0)!;
    final third = board.grid.at(0, 2)!;
    board = board.withMine(
      board.mine.paint({
        first.span: MeetingAnswer.unanswered,
        third.span: MeetingAnswer.available,
      }),
    );

    board = board.withAvailability([
      availabilityOf('me', userId: 'user-1', slots: [(seoul(6), seoul(7))]),
      availabilityOf('b', slots: [(seoul(6), seoul(8))]),
    ]);

    expect(board.othersTotal, 1);
    expect(board.othersAt(first), {'b'});
    expect(board.answerAt(first), MeetingAnswer.unanswered);
    expect(board.answerAt(board.grid.at(0, 1)!), MeetingAnswer.available);
    expect(board.answerAt(third), MeetingAnswer.available);
  });

  test('게스트는 회원 id 없이 참여해 받은 참여자 id로 나를 찾는다', () {
    final board = MeetingBoard(
      meeting: makeMeeting().copyWith(ownerId: null),
      availability: [
        availabilityOf('a', userId: null, slots: [(seoul(9), seoul(10))]),
        availabilityOf(
          'g',
          name: '민수',
          guest: true,
          slots: [(seoul(9), seoul(10))],
        ),
      ],
      userId: null,
      selfId: 'g',
      selfName: '민수',
    );

    expect(board.me?.id, 'g');
    expect(board.answerAt(board.grid.cells[6]), MeetingAnswer.available);
    expect(board.othersCountAt(board.grid.cells[6]), 1);
    expect(board.ownedByMe, isFalse);
    expect(
      board
          .withAvailability([availabilityOf('g', name: '민수', guest: true)])
          .me
          ?.id,
      'g',
    );
  });

  test('로그인하지 않았으면 나는 없고 모든 참여자가 다른 참여자다', () {
    final board = boardOf([
      availabilityOf('a'),
      availabilityOf('b'),
    ], userId: null);

    expect(board.me, isNull);
    expect(board.othersTotal, 2);
  });

  group('빼는 중인 참여자', () {
    List<AvailabilityRead> people() => [
      availabilityOf('a', slots: [(seoul(6), seoul(7))]),
      availabilityOf('g', guest: true, slots: [(seoul(6), seoul(7))]),
      availabilityOf('me', userId: 'user-1', slots: [(seoul(6), seoul(7))]),
    ];

    test('참여자·다른 참여자 수·칸·후보 어디에도 들지 않고, 비우면 돌아온다', () {
      final board = boardOf(people());
      final cell = board.grid.at(0, 0)!;
      expect(board.runs(MeetingRunOrder.people).single.people, hasLength(3));

      final removing = board.withRemoving({'g'});
      expect([for (final p in removing.participants) p.id], ['a', 'me']);
      expect(removing.othersTotal, 1);
      expect(removing.othersAt(cell), {'a'});
      expect(removing.peopleAt(cell), {'a', 'me'});
      expect(removing.runs(MeetingRunOrder.people).single.people, {'a', 'me'});

      final back = removing.withRemoving({});
      expect(back.participants, board.participants);
      expect(back.othersAt(cell), {'a', 'g'});
    });

    test('나만 남기고 모두 빼면 후보가 없다', () {
      final board = boardOf(people()).withRemoving({'a', 'g'});

      expect(board.othersTotal, 0);
      expect(board.runs(MeetingRunOrder.people), isEmpty);
    });

    test('가능 시간을 다시 받거나 내가 참여해도 빼는 중인 참여자는 빠진 채다', () {
      var board = boardOf([availabilityOf('a'), availabilityOf('b')]);
      board = board.withRemoving({'a'});

      board = board.withAvailability([
        availabilityOf('a'),
        availabilityOf('b'),
        availabilityOf('c'),
      ]);
      expect([for (final p in board.participants) p.id], ['b', 'c']);

      board = board.withSelf(
        ParticipantRead(
          id: 'me',
          meetingId: 'meeting-1',
          displayName: '지현',
          createdAt: DateTime.utc(2027),
          userId: 'user-1',
        ),
      );
      expect([for (final p in board.participants) p.id], ['b', 'c', 'me']);
      expect(board.withRemoving({}).participants, hasLength(4));
    });
  });

  group('내가 만든 모임인지', () {
    test('주인 id가 로그인한 나면 참여하지 않았어도 내 모임이다', () {
      expect(boardOf([], ownerId: 'user-1').ownedByMe, isTrue);
      expect(boardOf([], ownerId: 'someone').ownedByMe, isFalse);
    });

    test('주인 id를 받지 못했거나 로그인하지 않았으면 내 모임이 아니다', () {
      final hidden = MeetingBoard(
        meeting: makeMeeting().copyWith(ownerId: null),
        availability: const [],
        userId: 'user-1',
        selfName: '지현',
      );
      expect(hidden.ownedByMe, isFalse);
      expect(boardOf([], ownerId: 'user-1', userId: null).ownedByMe, isFalse);
    });

    test('내 모임인지는 주인 id로만 가리고 참여자의 is_owner는 보지 않는다', () {
      final board = boardOf([
        availabilityOf('me', userId: 'user-1', owner: true),
      ]);
      expect(board.ownedByMe, isFalse);
    });
  });
}
