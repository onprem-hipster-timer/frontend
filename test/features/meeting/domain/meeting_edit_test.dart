import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_access.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_edit.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../meeting_fixtures.dart';

/// 2027년 3월의 [day]일 (3월 1일은 월요일)
DateTime march(int day) => DateTime.utc(2027, 3, day);

const public = MeetingAudience(VisibilityLevel.public);

MeetingEditBase baseOf({
  MeetingRead? meeting,
  MeetingAudience audience = public,
}) => MeetingEditBase(
  meeting: meeting ?? makeMeeting(ownerId: 'user-1'),
  audience: audience,
);

/// 요청을 '보내는 곳 본문' 글로 적는다
List<String> sent(List<MeetingEditStep>? steps) => [
  for (final step in steps!)
    switch (step) {
      MeetingFieldsStep(:final body) => 'PATCH ${body.toJson()}',
      MeetingVisibilityStep(:final body) => 'PUT ${body.toJson()}',
    },
];

String day(int value) => march(value).toIso8601String();

MeetingDraft withEntries(MeetingDraft draft, List<String> entries) => entries
    .map(parseMeetingAccessEntry)
    .nonNulls
    .fold(draft, (draft, entry) => draft.withAccessEntry(entry));

void main() {
  group('처음 값', () {
    test('시간별 모임은 날짜, 방식, 하루 범위, 공개, 게스트를 그대로 담는다', () {
      final draft = baseOf(
        meeting: makeMeeting(
          excludedDates: [march(3)],
        ).copyWith(allowGuests: true),
      ).draft;
      expect(draft.mode, MeetingMode.hourly);
      expect(draft.dates.days, [march(1), march(2), march(4), march(5)]);
      expect((draft.startHour, draft.endHour), (6, 18));
      expect(draft.isPublic, isTrue);
      expect(draft.allowGuests, isTrue);
    });

    test('끝이 00:00이면 하루의 끝(24시)이다', () {
      final draft = baseOf(
        meeting: makeMeeting(startTime: '09:00:00', endTime: '00:00:00'),
      ).draft;
      expect((draft.startHour, draft.endHour), (9, 24));
    });

    test('날짜별·요일별은 시간별로 바꿀 때 쓸 처음 범위(6~18시)를 담는다', () {
      for (final mode in [MeetingMode.daily, MeetingMode.weekly]) {
        final draft = baseOf(
          meeting: makeMeeting(
            mode: mode,
            endDate: march(7),
            startTime: '00:00:00',
            endTime: '00:00:00',
          ),
        ).draft;
        expect(draft.mode, mode);
        expect(draft.dates.span, 7);
        expect((draft.startHour, draft.endHour), (6, 18));
      }
    });

    test('나만 보기, 정한 이메일·도메인, 친구 공개를 담는다', () {
      final onlyMe = baseOf(
        audience: const MeetingAudience(VisibilityLevel.private),
      ).draft;
      expect((onlyMe.isPublic, onlyMe.onlyMe), (false, true));

      final listed = baseOf(
        audience: const MeetingAudience(
          VisibilityLevel.allowedEmails,
          emails: ['kim@example.com'],
          domains: ['corp.com'],
        ),
      ).draft;
      expect(listed.isPublic, isFalse);
      expect(listed.emails, ['kim@example.com']);
      expect(listed.domains, ['corp.com']);
      expect(listed.accessReady, isTrue);

      final friends = baseOf(
        audience: const MeetingAudience(
          VisibilityLevel.friends,
          emails: ['old@example.com'],
        ),
      ).draft;
      expect(friends.isPublic, isFalse);
      expect(friends.onlyMe, isFalse);
      expect(friends.emails, isEmpty);
    });

    test('비공개인데 게스트가 켜진 예전 모임은 게스트를 꺼진 것으로 보인다', () {
      final draft = baseOf(
        meeting: makeMeeting().copyWith(allowGuests: true),
        audience: const MeetingAudience(VisibilityLevel.private),
      ).draft;
      expect(draft.allowGuests, isFalse);
    });

    test('규칙에 맞지 않는 예전 모임(10일 시간별, 30분 시작)도 맞추지 않고 그대로 담는다', () {
      final base = baseOf(
        meeting: makeMeeting(
          endDate: march(10),
          startTime: '06:30:00',
          endTime: '18:30:00',
        ),
      );
      final draft = base.draft;
      expect(draft.mode, MeetingMode.hourly);
      expect(draft.hourlyAvailable, isFalse);
      expect(draft.dates.span, 10);
      expect((draft.startHour, draft.endHour), (6, 18));
      expect(sent(base.plan(draft, title: '팀 회의')), isEmpty);
      expect(sent(base.plan(draft, title: '새 이름')), ['PATCH {title: 새 이름}']);
    });
  });

  group('보낼 요청', () {
    final base = baseOf();

    test('바꾼 것이 없으면 보내지 않는다', () {
      expect(sent(base.plan(base.draft, title: '팀 회의')), isEmpty);
    });

    test('제목만 바꾸면 제목만 보낸다', () {
      expect(sent(base.plan(base.draft, title: '주간 회의')), [
        'PATCH {title: 주간 회의}',
      ]);
    });

    test('시간별을 날짜별로 바꾸면 방식과 하루 전체 시각을 보낸다', () {
      final next = base.draft.withMode(MeetingMode.daily);
      expect(sent(base.plan(next, title: '팀 회의')), [
        'PATCH {mode: daily, start_time: 00:00:00, end_time: 00:00:00}',
      ]);
    });

    test('날짜별을 시간별로 바꾸면 방식과 고른 시각을 보낸다', () {
      final daily = baseOf(
        meeting: makeMeeting(
          mode: MeetingMode.daily,
          startTime: '00:00:00',
          endTime: '00:00:00',
        ),
      );
      final next = daily.draft.withMode(MeetingMode.hourly).withStartHour(9);
      expect(sent(daily.plan(next, title: '팀 회의')), [
        'PATCH {mode: hourly, start_time: 09:00:00, end_time: 18:00:00}',
      ]);
    });

    test('날짜별에서 시간별로 갔다가 돌아오면 보내지 않는다', () {
      final daily = baseOf(
        meeting: makeMeeting(
          mode: MeetingMode.daily,
          startTime: '00:00:00',
          endTime: '00:00:00',
        ),
      );
      final next = daily.draft
          .withMode(MeetingMode.hourly)
          .withMode(MeetingMode.daily);
      expect(sent(daily.plan(next, title: '팀 회의')), isEmpty);
    });

    test('하루 범위만 바꾸면 시작과 끝 시각을 함께 보낸다', () {
      final next = base.draft.withEndHour(20);
      expect(sent(base.plan(next, title: '팀 회의')), [
        'PATCH {start_time: 06:00:00, end_time: 20:00:00}',
      ]);
    });

    test('기간을 바꾸면 새 기간에 맞는 제외 날짜를 함께 보낸다', () {
      final withExcluded = baseOf(
        meeting: makeMeeting(excludedDates: [march(2)]),
      );
      final next = withExcluded.draft.withDates(
        MeetingDates.range(march(2), march(4), excluded: [march(2), march(3)]),
      );
      expect(sent(withExcluded.plan(next, title: '팀 회의')), [
        'PATCH {start_date: ${day(2)}, end_date: ${day(4)}, '
            'excluded_dates: [${day(3)}]}',
      ]);
    });

    test('기간을 줄여 원래 제외한 날이 빠지면 빈 제외 목록을 보낸다', () {
      final withExcluded = baseOf(
        meeting: makeMeeting(excludedDates: [march(4)]),
      );
      final next = withExcluded.draft.withDates(
        MeetingDates.range(march(1), march(3)),
      );
      expect(sent(withExcluded.plan(next, title: '팀 회의')), [
        'PATCH {start_date: ${day(1)}, end_date: ${day(3)}, excluded_dates: []}',
      ]);
    });

    test('기간은 그대로 두고 제외할 날만 바꾸면 제외 날짜만 보낸다', () {
      final next = base.draft.withDates(
        base.draft.dates.toggleExcluded(march(3)),
      );
      expect(sent(base.plan(next, title: '팀 회의')), [
        'PATCH {excluded_dates: [${day(3)}]}',
      ]);
    });

    test('공개(게스트 허용)를 정한 이메일 비공개로 바꾸면 게스트를 먼저 끄고 공개 범위를 보낸다', () {
      final guests = baseOf(meeting: makeMeeting().copyWith(allowGuests: true));
      final next = withEntries(guests.draft.withPublic(false), [
        'kim@example.com',
        'corp.com',
      ]);
      expect(sent(guests.plan(next, title: '팀 회의')), [
        'PATCH {allow_guests: false}',
        'PUT {level: allowed_emails, allowed_emails: [kim@example.com], '
            'allowed_domains: [corp.com]}',
      ]);
    });

    test('게스트를 끌 때 제목도 바꿨으면 같은 요청에 담아 공개 범위보다 먼저 보낸다', () {
      final guests = baseOf(meeting: makeMeeting().copyWith(allowGuests: true));
      final next = guests.draft.withPublic(false).withOnlyMe(true);
      expect(sent(guests.plan(next, title: '비밀 회의')), [
        'PATCH {title: 비밀 회의, allow_guests: false}',
        'PUT {level: private}',
      ]);
    });

    test('게스트를 받지 않던 공개 모임을 비공개로 바꾸면 공개 범위만 보낸다', () {
      final next = withEntries(base.draft.withPublic(false), [
        'kim@example.com',
      ]);
      expect(sent(base.plan(next, title: '팀 회의')), [
        'PUT {level: allowed_emails, allowed_emails: [kim@example.com]}',
      ]);
    });

    test('비공개를 공개로 바꾸고 게스트를 켜면 공개 범위를 먼저 정하고 게스트를 켠다', () {
      final private = baseOf(
        audience: const MeetingAudience(
          VisibilityLevel.allowedEmails,
          emails: ['kim@example.com'],
        ),
      );
      final next = private.draft.withPublic(true).withGuests(true);
      expect(sent(private.plan(next, title: '팀 회의')), [
        'PUT {level: public}',
        'PATCH {allow_guests: true}',
      ]);
      expect(sent(private.plan(next, title: '공개 회의')), [
        'PUT {level: public}',
        'PATCH {title: 공개 회의, allow_guests: true}',
      ]);
    });

    test('공개 모임에서 게스트만 켜거나 끄면 게스트만 보낸다', () {
      expect(sent(base.plan(base.draft.withGuests(true), title: '팀 회의')), [
        'PATCH {allow_guests: true}',
      ]);
      final guests = baseOf(meeting: makeMeeting().copyWith(allowGuests: true));
      expect(sent(guests.plan(guests.draft.withGuests(false), title: '팀 회의')), [
        'PATCH {allow_guests: false}',
      ]);
    });

    test('비공개로 바꾸고 참여할 사람을 정하지 않았으면 보낼 수 없다', () {
      expect(base.plan(base.draft.withPublic(false), title: '팀 회의'), isNull);
    });

    test('친구 공개 같은 예전 공개 범위는 건드리지 않으면 보내지 않는다', () {
      final friends = baseOf(
        audience: const MeetingAudience(VisibilityLevel.friends),
      );
      expect(sent(friends.plan(friends.draft, title: '팀 회의')), isEmpty);
      expect(sent(friends.plan(friends.draft, title: '새 이름')), [
        'PATCH {title: 새 이름}',
      ]);
    });

    test('넣은 이메일·도메인을 같은 값으로 다시 넣으면(순서만 달라도) 보내지 않는다', () {
      final listed = baseOf(
        audience: const MeetingAudience(
          VisibilityLevel.allowedEmails,
          emails: ['a@example.com', 'b@example.com'],
        ),
      );
      final next = withEntries(
        listed.draft
            .withoutAccessEntry('a@example.com')
            .withoutAccessEntry('b@example.com'),
        ['b@example.com', 'a@example.com'],
      );
      expect(sent(listed.plan(next, title: '팀 회의')), isEmpty);
    });

    test('서버에 남은 도메인을 모두 빼면 빈 도메인 목록을 보낸다', () {
      final listed = baseOf(
        audience: const MeetingAudience(
          VisibilityLevel.allowedEmails,
          emails: ['kim@example.com'],
          domains: ['corp.com'],
        ),
      );
      final next = listed.draft.withoutAccessEntry('corp.com');
      expect(sent(listed.plan(next, title: '팀 회의')), [
        'PUT {level: allowed_emails, allowed_emails: [kim@example.com], '
            'allowed_domains: []}',
      ]);
    });

    test('나만 보기에서 이메일로 바꿀 때 서버에 남은 예전 도메인이 있으면 빈 목록으로 지운다', () {
      final onlyMe = baseOf(
        audience: const MeetingAudience(
          VisibilityLevel.private,
          domains: ['old.com'],
        ),
      );
      final next = withEntries(onlyMe.draft.withOnlyMe(false), [
        'kim@example.com',
      ]);
      expect(sent(onlyMe.plan(next, title: '팀 회의')), [
        'PUT {level: allowed_emails, allowed_emails: [kim@example.com], '
            'allowed_domains: []}',
      ]);
    });
  });

  group('저장 전에 알릴 것', () {
    final base = baseOf();

    test('방식을 바꾸면 답이 다르게 보일 수 있다고 알린다', () {
      expect(base.notices(base.draft.withMode(MeetingMode.daily)), {
        MeetingEditNotice.modeChanged,
      });
    });

    test('기간을 줄이거나 옮기거나 날을 새로 빼면 빠진 날을 알린다', () {
      MeetingDraft over(int from, int to, {List<int> excluded = const []}) =>
          base.draft.withDates(
            MeetingDates.range(
              march(from),
              march(to),
              excluded: [for (final value in excluded) march(value)],
            ),
          );
      expect(base.notices(over(1, 4)), {MeetingEditNotice.daysDropped});
      expect(base.notices(over(2, 6)), {MeetingEditNotice.daysDropped});
      expect(base.notices(over(1, 5, excluded: [3])), {
        MeetingEditNotice.daysDropped,
      });
    });

    test('기간을 늘리거나 시각·제목·공개만 바꾸면 알리지 않는다', () {
      final longer = base.draft.withDates(
        MeetingDates.range(march(1), march(6)),
      );
      expect(base.notices(longer), isEmpty);
      expect(base.notices(base.draft.withEndHour(20)), isEmpty);
      expect(base.notices(base.draft.withPublic(false)), isEmpty);
    });
  });
}
