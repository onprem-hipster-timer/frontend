import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/domain/meeting_runs.dart';
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
      availabilityOf('owner', userId: 'owner-1'),
    ]);

    expect([for (final p in board.participants) p.id], ['owner', 'a', 'b']);
    expect(board.isOwner(board.participants.first), isTrue);
    expect(board.isOwner(board.participants.last), isFalse);
  });

  test('로그인한 사람의 참여자가 나이고 그 가능 시간이 내 칸이다', () {
    final board = boardOf([
      availabilityOf('a', slots: [(seoul(6), seoul(7))]),
      availabilityOf('me', userId: 'user-1', slots: [(seoul(9), seoul(10))]),
    ]);

    expect(board.me?.id, 'me');
    expect(board.othersTotal, 1);
    expect(board.isMine(board.grid.at(0, 6)!), isTrue);
    expect(board.isMine(board.grid.at(0, 0)!), isFalse);
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
    board = board.withMine(board.mine.paint([cell.span], available: true));

    expect(board.me, isNull);
    expect(board.peopleAt(cell), {'a', MeetingBoard.pendingSelfId});
    expect(board.nameOf(MeetingBoard.pendingSelfId), '지현');
    expect(board.isSelf(MeetingBoard.pendingSelfId), isTrue);
    expect(board.runs(MeetingRunOrder.people).single.people, hasLength(2));
  });

  test('참여자가 나 하나면 칸이 진해지지 않고 후보도 없다', () {
    var board = boardOf([availabilityOf('me', userId: 'user-1')]);
    board = board.withMine(
      board.mine.paint([
        for (final cell in board.grid.cells) cell.span,
      ], available: true),
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
      availabilityOf('owner', userId: 'owner-1'),
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
      board.mine.paint([first.span], available: false).paint([
        third.span,
      ], available: true),
    );

    board = board.withAvailability([
      availabilityOf('me', userId: 'user-1', slots: [(seoul(6), seoul(7))]),
      availabilityOf('b', slots: [(seoul(6), seoul(8))]),
    ]);

    expect(board.othersTotal, 1);
    expect(board.othersAt(first), {'b'});
    expect(board.isMine(first), isFalse);
    expect(board.isMine(board.grid.at(0, 1)!), isTrue);
    expect(board.isMine(third), isTrue);
  });

  test('로그인하지 않았으면 나는 없고 모든 참여자가 다른 참여자다', () {
    final board = boardOf([
      availabilityOf('a'),
      availabilityOf('b'),
    ], userId: null);

    expect(board.me, isNull);
    expect(board.othersTotal, 2);
  });
}
