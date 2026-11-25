import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:momeet/features/meeting/meeting.dart';
import 'package:momeet/features/trial/presentation/utils/trial_samples.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  setUpAll(tz.initializeTimeZones);

  /// [now]에 시작한 체험의 견본 모임이 모임 만들기의 규칙을 지키고, 약속 날 저녁 7시~9시에 모두가 되는 것을
  /// 첫 추천 시간으로 보인다
  void expectValidMeeting(DateTime now) {
    final flow = trialStart(now);
    final board = trialMeeting(flow);
    final meeting = board.meeting;
    final dinner = calendarDay(flow.dinner.startTime);
    final days = board.grid.columnDays;
    final reason = '$now';

    expect(meeting.title, flow.dinner.title, reason: reason);
    expect(meeting.mode, MeetingMode.hourly, reason: reason);
    expect(days, hasLength(hourlyMaxDays), reason: reason);
    expect(days, [
      for (var i = -2; i <= 2; i++) dinner.add(Duration(days: i)),
    ], reason: reason);
    final draft = MeetingDraft.restore(
      mode: meeting.mode,
      days: days,
      startHour: 18,
      endHour: 22,
      isPublic: true,
      allowGuests: meeting.allowGuests,
      today: now,
    );
    expect(draft, isNotNull, reason: reason);
    expect(draft!.dates.days, days, reason: reason);

    // 나는 모임을 만들었고 칠한 참여자다
    expect(board.ownedByMe, isTrue, reason: reason);
    expect(board.me?.isOwner, isTrue, reason: reason);
    expect(board.mine.available, isNotEmpty, reason: reason);
    expect(board.participants, hasLength(4), reason: reason);

    final runs = board.runs(MeetingRunOrder.recommended);
    expect(runs.length, greaterThan(1), reason: reason);
    final best = runs.first;
    expect(best.first.day, dinner, reason: reason);
    expect((best.first.startMinute, best.last.endMinute), (19 * 60, 21 * 60));
    expect(best.people, hasLength(board.participants.length), reason: reason);
  }

  group('견본 모임은 약속 날을 가운데 둔 닷새의 시간별 모임이다', () {
    final cases = {
      '약속이 다음 달 5일': DateTime(2026, 11, 25, 10),
      '약속이 달의 첫날이라 앞 이틀이 앞 달': DateTime(2026, 11, 27, 10),
      '약속이 새해 첫날이라 앞 이틀이 지난해': DateTime(2026, 12, 28, 10),
      '약속이 달의 끝 무렵': DateTime(2026, 3, 24, 10),
      '자정 직전에 시작': DateTime(2026, 6, 10, 23, 59),
    };
    for (final MapEntry(key: label, value: now) in cases.entries) {
      test('$label이어도 날짜가 모임 만들기의 규칙을 지키고 약속 날 저녁에 모두가 된다', () {
        expectValidMeeting(now);
      });
    }

    test('어느 날 시작해도 날짜가 모임 만들기의 규칙을 지키고 약속 날 저녁에 모두가 된다', () {
      for (
        var day = DateTime(2026, 1, 1, 10);
        day.year < 2029;
        day = DateTime(day.year, day.month, day.day + 1, 10)
      ) {
        expectValidMeeting(day);
      }
    });
  });

  test('견본 모임의 참여자는 이름이 서로 다르고 게스트도 있다', () {
    final flow = trialStart(DateTime(2026, 11, 25, 10));
    final board = trialMeeting(flow);
    final names = board.participants.map((p) => p.displayName).toList();

    expect(names.toSet(), hasLength(names.length));
    expect(board.participants.where((p) => p.isGuest), isNotEmpty);
  });
}
