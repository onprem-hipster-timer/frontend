import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 2027년 3월의 [day]일 (3월 1일은 월요일)
DateTime march(int day) => DateTime.utc(2027, 3, day);

/// 3월 [from]일~[to]일에서 [excluded]일을 뺀 날짜의 폼
MeetingDraft over(
  int from,
  int to, {
  List<int> excluded = const [],
  MeetingDraft draft = const MeetingDraft(),
}) => draft.withDates(
  MeetingDates.range(
    march(from),
    march(to),
    excluded: [for (final day in excluded) march(day)],
  ),
);

void main() {
  group('시간별을 고를 수 있는 기간', () {
    test('5일까지는 고를 수 있다', () {
      expect(over(1, 5).hourlyAvailable, isTrue);
      expect(over(1, 1).hourlyAvailable, isTrue);
    });

    test('이어진 6일이면 고를 수 없다', () {
      expect(over(1, 6).hourlyAvailable, isFalse);
    });

    test('7일 기간에서 가운데 주말을 빼 5일이면 고를 수 있다', () {
      // 3월 4일(목)~10일(수)
      expect(over(4, 10).hourlyAvailable, isFalse);
      expect(over(4, 10, excluded: [6]).hourlyAvailable, isFalse);
      expect(over(4, 10, excluded: [6, 7]).hourlyAvailable, isTrue);
    });

    test('월~일은 마지막 날인 일요일을 뺄 수 없어 토요일만 빼면 6일이다', () {
      expect(over(1, 7, excluded: [6, 7]).hourlyAvailable, isFalse);
    });

    test('남은 날이 5일 이하여도 기간이 7일을 넘으면 고를 수 없다', () {
      expect(over(1, 8, excluded: [2, 3, 4]).hourlyAvailable, isFalse);
      expect(over(1, 7, excluded: [2, 3, 4]).hourlyAvailable, isTrue);
    });

    test('고를 수 없는 기간이면 시간별로 바꾸지 않는다', () {
      final daily = over(
        1,
        6,
        draft: const MeetingDraft(mode: MeetingMode.daily),
      );
      expect(daily.withMode(MeetingMode.hourly).mode, MeetingMode.daily);
    });
  });

  group('요일별', () {
    test('요일별로 바꾸면 첫날부터 7일로 맞추고 뺀 날을 되돌린다', () {
      final weekly = over(2, 5, excluded: [3]).withMode(MeetingMode.weekly);
      expect(weekly.dates.first, march(2));
      expect(weekly.dates.last, march(8));
      expect(weekly.dates.isWeek, isTrue);
    });

    test('고른 날이 없으면 비워 둔다', () {
      expect(
        const MeetingDraft().withMode(MeetingMode.weekly).dates.isEmpty,
        isTrue,
      );
    });
  });

  group('공개와 게스트 로그인', () {
    test('공개를 끄면 게스트 로그인도 꺼진다', () {
      final draft = const MeetingDraft().withPublic(false);
      expect(draft.isPublic, isFalse);
      expect(draft.allowGuests, isFalse);
    });

    test('공개가 아니면 게스트 로그인을 켤 수 없다', () {
      final draft = const MeetingDraft().withPublic(false).withGuests(true);
      expect(draft.allowGuests, isFalse);
    });

    test('공개를 다시 켜도 게스트 로그인은 꺼진 채로 두고, 그 뒤에는 켤 수 있다', () {
      final reopened = const MeetingDraft().withPublic(false).withPublic(true);
      expect(reopened.isPublic, isTrue);
      expect(reopened.allowGuests, isFalse);
      expect(reopened.withGuests(true).allowGuests, isTrue);
    });

    test('공개인 채로 게스트 로그인만 끌 수 있다', () {
      final draft = const MeetingDraft().withGuests(false);
      expect(draft.isPublic, isTrue);
      expect(draft.allowGuests, isFalse);
    });
  });

  group('하루 시간 범위', () {
    test('시작을 끝과 같거나 늦게 옮기면 끝을 한 시간 뒤로 민다', () {
      final draft = const MeetingDraft().withStartHour(18);
      expect(draft.startHour, 18);
      expect(draft.endHour, 19);
      expect(const MeetingDraft().withStartHour(23).endHour, 24);
    });

    test('시작이 끝보다 이르면 끝은 그대로다', () {
      expect(const MeetingDraft().withStartHour(9).endHour, 18);
    });
  });

  group('만들기 요청', () {
    const timezone = 'Asia/Seoul';

    test('시간별은 방식, 고른 기간과 그 사이 고르지 않은 날, 하루 시간 범위를 보낸다', () {
      final body = over(
        1,
        5,
        excluded: [2, 4],
        draft: const MeetingDraft(startHour: 9, endHour: 18),
      ).toMeetingCreate(title: '회의', timezone: timezone);
      expect(body.title, '회의');
      expect(body.timezone, timezone);
      expect(body.startDate, march(1));
      expect(body.endDate, march(5));
      expect(body.excludedDates, [march(2), march(4)]);
      expect(body.mode, MeetingMode.hourly);
      expect(body.startTime, '09:00:00');
      expect(body.endTime, '18:00:00');
      expect(body.timeSlotMinutes, 30);
    });

    test('시간별 끝이 24시면 하루의 끝인 00:00으로 보낸다', () {
      final body = over(
        2,
        2,
        draft: const MeetingDraft(startHour: 22, endHour: 24),
      ).toMeetingCreate(title: '야간', timezone: timezone);
      expect(body.startTime, '22:00:00');
      expect(body.endTime, '00:00:00');
    });

    test('날짜별은 하루 전체(00:00~00:00)로 보낸다', () {
      final body = over(
        1,
        6,
        draft: const MeetingDraft(
          mode: MeetingMode.daily,
          startHour: 9,
          endHour: 12,
        ),
      ).toMeetingCreate(title: '여행', timezone: timezone);
      expect(body.startTime, '00:00:00');
      expect(body.endTime, '00:00:00');
      expect(body.startDate, march(1));
      expect(body.endDate, march(6));
      expect(body.excludedDates, isEmpty);
      expect(body.mode, MeetingMode.daily);
    });

    test('요일별은 7일 기간과 모든 요일을 하루 전체로 보낸다', () {
      final body = over(4, 4)
          .withMode(MeetingMode.weekly)
          .toMeetingCreate(title: '정기 모임', timezone: timezone);
      expect(body.startDate, march(4));
      expect(body.endDate, march(10));
      expect(body.excludedDates, isEmpty);
      expect(body.mode, MeetingMode.weekly);
      expect(body.startTime, '00:00:00');
      expect(body.endTime, '00:00:00');
    });

    test('긴 기간에서 뺀 날을 제외 날짜로 보낸다', () {
      final body = over(
        1,
        15,
        excluded: [6, 7, 13, 14],
        draft: const MeetingDraft(mode: MeetingMode.daily),
      ).toMeetingCreate(title: '격주', timezone: timezone);
      expect(body.mode, MeetingMode.daily);
      expect(body.startDate, march(1));
      expect(body.endDate, march(15));
      expect(body.excludedDates, [march(6), march(7), march(13), march(14)]);
    });

    test('날짜는 시각 없는 자정 값으로 직렬화한다', () {
      final json = over(
        1,
        1,
      ).toMeetingCreate(title: '회의', timezone: timezone).toJson();
      expect(json['start_date'], '2027-03-01T00:00:00.000Z');
      expect(json['end_date'], '2027-03-01T00:00:00.000Z');
    });

    test('게스트 로그인을 허용해도 만들기 요청의 allow_guests는 false다(만든 뒤 켠다)', () {
      final allowed = over(1, 1);
      expect(allowed.allowGuests, isTrue);
      final json = allowed.toMeetingCreate(title: 't', timezone: timezone);
      expect(json.toJson()['allow_guests'], isFalse);
    });
  });

  test('고른 날짜 값은 [MeetingDates]로 다시 만들어도 같다', () {
    final draft = over(1, 3, excluded: [2]);
    expect(MeetingDates.of(draft.dates.days).days, draft.dates.days);
  });
}
