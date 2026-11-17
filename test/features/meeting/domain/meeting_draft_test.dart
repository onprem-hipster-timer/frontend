import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 2027년 3월의 [day]일 (3월 1일은 월요일)
DateTime march(int day) => DateTime.utc(2027, 3, day);

MeetingDraft tapAll(MeetingDraft draft, Iterable<int> days) =>
    days.fold(draft, (draft, day) => draft.tapDay(march(day)));

void main() {
  group('시간별의 기간', () {
    test('5일째 날까지는 시간별로 남는다', () {
      final draft = tapAll(const MeetingDraft(), [1, 2, 3, 4, 5]);
      expect(draft.mode, MeetingMode.hourly);
      expect(draft.dates.span, 5);
      expect(draft.hourlyAvailable, isTrue);
    });

    test('6번째 날을 고르면 묻지 않고 날짜별로 바뀐다', () {
      final draft = tapAll(const MeetingDraft(), [1, 2, 3, 4, 5, 6]);
      expect(draft.mode, MeetingMode.daily);
      expect(draft.dates.days, hasLength(6));
      expect(draft.hourlyAvailable, isFalse);
    });

    test('떨어진 두 날이라도 기간이 6일이면 날짜별로 바뀐다', () {
      final draft = tapAll(const MeetingDraft(), [1, 6]);
      expect(draft.mode, MeetingMode.daily);
      expect(draft.dates.days, [march(1), march(6)]);
    });

    test('날짜별에서 기간을 5일 안으로 줄여도 날짜별에 머물고 시간별을 다시 고를 수 있다', () {
      final wide = tapAll(const MeetingDraft(), [1, 6]);
      final narrowed = wide.tapDay(march(6));
      expect(narrowed.mode, MeetingMode.daily);
      expect(narrowed.hourlyAvailable, isTrue);
      expect(narrowed.withMode(MeetingMode.hourly).mode, MeetingMode.hourly);
    });

    test('기간이 5일을 넘으면 시간별로 바꾸지 않는다', () {
      final wide = tapAll(const MeetingDraft(), [1, 6]);
      expect(wide.withMode(MeetingMode.hourly).mode, MeetingMode.daily);
    });

    test('날짜별에서는 6일 넘게 골라도 방식이 그대로다', () {
      final draft = tapAll(const MeetingDraft(mode: MeetingMode.daily), [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
      ]);
      expect(draft.mode, MeetingMode.daily);
    });
  });

  group('요일별', () {
    test('누른 날부터 7일을 고른다', () {
      final draft = const MeetingDraft(
        mode: MeetingMode.weekly,
      ).tapDay(march(3));
      expect(draft.dates.first, march(3));
      expect(draft.dates.last, march(9));
      expect(draft.dates.days, hasLength(7));
    });

    test('다른 날을 누르면 그날부터 7일로 옮긴다', () {
      final draft = const MeetingDraft(
        mode: MeetingMode.weekly,
      ).tapDay(march(3)).tapDay(march(5));
      expect(draft.dates.first, march(5));
      expect(draft.dates.span, 7);
    });

    test('요일별로 바꾸면 첫날부터 7일로 맞추고, 고른 날이 없으면 비워 둔다', () {
      final picked = tapAll(const MeetingDraft(), [2, 4]);
      final weekly = picked.withMode(MeetingMode.weekly);
      expect(weekly.dates.first, march(2));
      expect(weekly.dates.span, 7);

      expect(
        const MeetingDraft().withMode(MeetingMode.weekly).dates.isEmpty,
        isTrue,
      );
    });

    test('요일별에서 날짜별로 바꾸면 7일을 그대로 두고 시간별은 고를 수 없다', () {
      final daily = const MeetingDraft(
        mode: MeetingMode.weekly,
      ).tapDay(march(3)).withMode(MeetingMode.daily);
      expect(daily.mode, MeetingMode.daily);
      expect(daily.dates.span, 7);
      expect(daily.withMode(MeetingMode.hourly).mode, MeetingMode.daily);
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

  group('날짜 칸 상태', () {
    final today = march(2);

    test('지난 날은 고를 수 없고 오늘은 고를 수 있다', () {
      const draft = MeetingDraft();
      expect(
        draft.dayState(march(1), today: today),
        MeetingDayState.unavailable,
      );
      expect(draft.dayState(march(2), today: today), MeetingDayState.open);
    });

    test('시간별에서 기간을 5일 넘게 만드는 날은 고르면 날짜별로 바뀌는 칸이다', () {
      final draft = const MeetingDraft().tapDay(march(3));
      expect(draft.dayState(march(3), today: today), MeetingDayState.selected);
      expect(draft.dayState(march(7), today: today), MeetingDayState.open);
      expect(
        draft.dayState(march(8), today: today),
        MeetingDayState.leavesHourly,
      );
    });

    test('날짜별에서는 기간 상한 밖의 날만 고를 수 없다', () {
      final draft = const MeetingDraft(
        mode: MeetingMode.daily,
      ).tapDay(march(3));
      expect(draft.dayState(march(20), today: today), MeetingDayState.open);
      expect(
        draft.dayState(DateTime.utc(2027, 6, 3), today: today),
        MeetingDayState.open,
      );
      expect(
        draft.dayState(DateTime.utc(2027, 6, 4), today: today),
        MeetingDayState.unavailable,
      );
    });

    test('요일별은 지난 날 밖에는 모두 고를 수 있다', () {
      final draft = const MeetingDraft(
        mode: MeetingMode.weekly,
      ).tapDay(march(3));
      expect(
        draft.dayState(DateTime.utc(2027, 9, 1), today: today),
        MeetingDayState.open,
      );
      expect(draft.dayState(march(9), today: today), MeetingDayState.selected);
    });
  });

  group('만들기 요청', () {
    const timezone = 'Asia/Seoul';

    test('시간별은 방식, 고른 기간과 그 사이 고르지 않은 날, 하루 시간 범위를 보낸다', () {
      final body = tapAll(const MeetingDraft(startHour: 9, endHour: 18), [
        1,
        3,
        5,
      ]).toMeetingCreate(title: '회의', timezone: timezone);
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
      final body = tapAll(const MeetingDraft(startHour: 22, endHour: 24), [
        2,
      ]).toMeetingCreate(title: '야간', timezone: timezone);
      expect(body.startTime, '22:00:00');
      expect(body.endTime, '00:00:00');
    });

    test('날짜별은 하루 전체(00:00~00:00)로 보낸다', () {
      final body = tapAll(const MeetingDraft(startHour: 9, endHour: 12), [
        1,
        2,
        3,
        4,
        5,
        6,
      ]).toMeetingCreate(title: '여행', timezone: timezone);
      expect(body.startTime, '00:00:00');
      expect(body.endTime, '00:00:00');
      expect(body.startDate, march(1));
      expect(body.endDate, march(6));
      expect(body.excludedDates, isEmpty);
      expect(body.mode, MeetingMode.daily);
    });

    test('요일별은 7일 기간과 모든 요일을 하루 전체로 보낸다', () {
      final body = const MeetingDraft(
        mode: MeetingMode.weekly,
      ).tapDay(march(4)).toMeetingCreate(title: '정기 모임', timezone: timezone);
      expect(body.startDate, march(4));
      expect(body.endDate, march(10));
      expect(body.excludedDates, isEmpty);
      expect(body.mode, MeetingMode.weekly);
      expect(body.startTime, '00:00:00');
      expect(body.endTime, '00:00:00');
    });

    test('떨어진 날을 고르면 그 날들만 미팅 날짜가 되게 사이의 날을 모두 제외 날짜로 보낸다', () {
      final body = tapAll(const MeetingDraft(), [
        1,
        15,
      ]).toMeetingCreate(title: '격주', timezone: timezone);
      expect(body.mode, MeetingMode.daily);
      expect(body.startDate, march(1));
      expect(body.endDate, march(15));
      expect(body.excludedDates, [
        for (var day = 2; day <= 14; day++) march(day),
      ]);
    });

    test('날짜는 시각 없는 자정 값으로 직렬화한다', () {
      final json = tapAll(const MeetingDraft(), [
        1,
      ]).toMeetingCreate(title: '회의', timezone: timezone).toJson();
      expect(json['start_date'], '2027-03-01T00:00:00.000Z');
      expect(json['end_date'], '2027-03-01T00:00:00.000Z');
    });

    test('게스트 로그인을 허용해도 만들기 요청의 allow_guests는 false다(만든 뒤 켠다)', () {
      final allowed = tapAll(const MeetingDraft(), [1]);
      expect(allowed.allowGuests, isTrue);
      final json = allowed.toMeetingCreate(title: 't', timezone: timezone);
      expect(json.toJson()['allow_guests'], isFalse);
    });
  });

  test('고른 날짜 값은 [MeetingDates]로 다시 만들어도 같다', () {
    final draft = tapAll(const MeetingDraft(), [1, 3]);
    expect(MeetingDates.of(draft.dates.days).days, draft.dates.days);
  });
}
