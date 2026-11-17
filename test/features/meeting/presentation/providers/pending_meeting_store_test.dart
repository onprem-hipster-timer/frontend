import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_access.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/providers/pending_meeting_store.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late PendingMeetingStore store;
  final today = DateTime.utc(2027, 3, 10);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = PendingMeetingStore(prefs);
  });

  /// 2027년 3월 [from]~[to]일
  MeetingDates march(int from, int to) => MeetingDates.range(
    DateTime.utc(2027, 3, from),
    DateTime.utc(2027, 3, to),
  );

  test('하나씩 답한 폼을 답한 그대로 꺼내고 지운다', () async {
    final draft = const MeetingDraft()
        .withDates(march(12, 15).toggleExcluded(DateTime.utc(2027, 3, 13)))
        .withStartHour(9)
        .withEndHour(21)
        .withGuests(false);
    final answered = {
      MeetingQuestion.range,
      MeetingQuestion.exclusions,
      MeetingQuestion.mode,
      MeetingQuestion.time,
      MeetingQuestion.visibility,
      MeetingQuestion.guests,
    };
    await store.save((
      flow: MeetingFlow(draft: draft, answered: answered),
      title: ' 스터디 ',
    ));

    final taken = store.take(today: today)!;

    expect(taken.title, ' 스터디 ');
    expect(taken.flow.expanded, isFalse);
    expect(taken.flow.answered, answered);
    expect(taken.flow.current, MeetingQuestion.title);
    final restored = taken.flow.draft;
    expect(restored.mode, MeetingMode.hourly);
    expect(restored.dates.days, draft.dates.days);
    expect(restored.dates.excluded, [DateTime.utc(2027, 3, 13)]);
    expect(restored.startHour, 9);
    expect(restored.endHour, 21);
    expect(restored.isPublic, isTrue);
    expect(restored.allowGuests, isFalse);
    expect(store.take(today: today), isNull, reason: '한 번만 꺼낸다');
  });

  test('펼친 폼은 펼친 폼으로 꺼낸다', () async {
    final draft = const MeetingDraft()
        .withDates(march(10, 10))
        .withMode(MeetingMode.weekly)
        .withPublic(false);
    await store.save((
      flow: MeetingFlow(draft: draft, expanded: true),
      title: '',
    ));

    final taken = store.take(today: today)!.flow;

    expect(taken.expanded, isTrue);
    expect(taken.draft.mode, MeetingMode.weekly);
    expect(taken.draft.dates.days, march(10, 16).days);
    expect(taken.draft.isPublic, isFalse);
    expect(taken.draft.allowGuests, isFalse);
  });

  test('비공개에 넣은 이메일·도메인과 나만 보기를 그대로 꺼낸다', () async {
    var draft = const MeetingDraft(
      mode: MeetingMode.daily,
    ).withDates(march(12, 13)).withPublic(false);
    for (final input in ['kim@example.com', 'corp.com']) {
      draft = draft.withAccessEntry(parseMeetingAccessEntry(input)!);
    }
    const answered = {
      MeetingQuestion.range,
      MeetingQuestion.exclusions,
      MeetingQuestion.mode,
      MeetingQuestion.visibility,
      MeetingQuestion.access,
    };
    await store.save((
      flow: MeetingFlow(draft: draft, answered: answered),
      title: '',
    ));

    final taken = store.take(today: today)!.flow;

    expect(taken.current, MeetingQuestion.title);
    expect(taken.draft.isPublic, isFalse);
    expect(taken.draft.emails, ['kim@example.com']);
    expect(taken.draft.domains, ['corp.com']);
    expect(taken.draft.onlyMe, isFalse);

    await store.save((
      flow: MeetingFlow(draft: draft.withOnlyMe(true), answered: answered),
      title: '',
    ));
    expect(store.take(today: today)!.flow.draft.onlyMe, isTrue);
  });

  test('날짜를 고르지 않은 폼도 꺼낸다', () async {
    await store.save((flow: const MeetingFlow(), title: '스터디'));

    expect(store.take(today: today)?.flow.draft.dates.isEmpty, isTrue);
  });

  test('첫날이 오늘보다 앞이면 버린다', () async {
    final draft = const MeetingDraft().withDates(march(9, 9));
    await store.save((flow: MeetingFlow(draft: draft), title: '스터디'));

    expect(store.take(today: today), isNull);
    expect(prefs.getString(PendingMeetingStore.key), isNull);
  });

  group('폼이 만들 수 없는 값은 폼의 규칙으로 맞추거나 버린다', () {
    /// [overrides]로 바꾼 저장 값을 꺼낸다
    PendingMeeting? takeStored(Map<String, Object?> overrides) {
      prefs.setString(
        PendingMeetingStore.key,
        jsonEncode({
          'mode': 'hourly',
          'days': ['2027-03-12'],
          'start_hour': 9,
          'end_hour': 18,
          'public': true,
          'guests': true,
          'title': '스터디',
          ...overrides,
        }),
      );
      return store.take(today: today);
    }

    List<int> daysOf(PendingMeeting pending) => [
      for (final day in pending.flow.draft.dates.days) day.day,
    ];

    test('답한 질문이 없던 이전 형식은 펼친 폼으로 꺼낸다', () {
      expect(takeStored({})!.flow.expanded, isTrue);
    });

    test('형식이 아닌 이메일·도메인은 버리고 겹친 것은 한 번만 꺼낸다', () {
      final taken = takeStored({
        'public': false,
        'guests': false,
        'emails': ['Kim@Example.com', 'kim@example.com', 'not an email'],
        'domains': ['corp.com', '-bad.com'],
      })!;
      expect(taken.flow.draft.emails, ['kim@example.com']);
      expect(taken.flow.draft.domains, ['corp.com']);
    });

    test('공개면 이메일과 나만 보기를 버린다', () {
      final taken = takeStored({
        'emails': ['kim@example.com'],
        'only_me': true,
      })!;
      expect(taken.flow.draft.emails, isEmpty);
      expect(taken.flow.draft.onlyMe, isFalse);
    });

    test('비공개인데 참여할 사람을 정하지 않았으면 그 질문을 다시 묻는다', () {
      final taken = takeStored({
        'mode': 'daily',
        'public': false,
        'answered': ['range', 'mode', 'visibility', 'access'],
      })!;
      expect(taken.flow.current, MeetingQuestion.access);
    });

    test('알 수 없는 질문 이름은 버리고 나머지 답으로 꺼낸다', () {
      final taken = takeStored({
        'answered': ['range', 'colour'],
      })!;
      expect(taken.flow.expanded, isFalse);
      expect(taken.flow.answered, {MeetingQuestion.range});
    });

    test('시간별인데 시간별로 받을 수 없는 날짜면 날짜별로 바꾼다', () {
      final taken = takeStored({
        'days': [for (var day = 12; day <= 17; day++) '2027-03-$day'],
      })!;
      expect(taken.flow.draft.mode, MeetingMode.daily);
      expect(daysOf(taken), [12, 13, 14, 15, 16, 17]);
    });

    test('요일별인데 이어진 7일이 아니면 첫날부터 7일로 맞춘다', () {
      final taken = takeStored({
        'mode': 'weekly',
        'days': ['2027-03-12', '2027-03-14'],
      })!;
      expect(taken.flow.draft.mode, MeetingMode.weekly);
      expect(daysOf(taken), [12, 13, 14, 15, 16, 17, 18]);
    });

    test('공개가 아니면 게스트 로그인을 끈다', () {
      final taken = takeStored({'public': false, 'guests': true})!;
      expect(taken.flow.draft.isPublic, isFalse);
      expect(taken.flow.draft.allowGuests, isFalse);
    });

    test('끝이 시작보다 늦지 않으면 끝을 시작 한 시간 뒤로 민다', () {
      final taken = takeStored({'start_hour': 20, 'end_hour': 18})!;
      expect(taken.flow.draft.startHour, 20);
      expect(taken.flow.draft.endHour, 21);
    });

    test('0시 시작과 24시 끝은 그대로 꺼낸다', () {
      final taken = takeStored({'start_hour': 0, 'end_hour': 24})!;
      expect(taken.flow.draft.startHour, 0);
      expect(taken.flow.draft.endHour, 24);
    });

    test('하루 범위 밖의 시각은 버린다', () {
      for (final hours in [
        {'start_hour': -1},
        {'start_hour': 24},
        {'end_hour': 0},
        {'end_hour': 25},
      ]) {
        expect(takeStored(hours), isNull, reason: '$hours');
      }
    });

    test('기간이 3개월 상한을 넘으면 버린다', () {
      expect(
        takeStored({
          'mode': 'daily',
          'days': ['2027-03-12', '2027-06-13'],
        }),
        isNull,
      );
    });

    test('알 수 없는 방식은 버린다', () {
      expect(takeStored({'mode': r'$unknown'}), isNull);
    });

    test('제목은 제목 칸처럼 200자에서 자른다', () {
      final taken = takeStored({'title': '가' * 250})!;
      expect(taken.title, '가' * 200);
    });
  });

  test('읽을 수 없는 값은 버린다', () async {
    for (final raw in ['', '{', '[]', '{"mode":"monthly"}', '{"days":[1]}']) {
      await prefs.setString(PendingMeetingStore.key, raw);
      expect(store.take(today: today), isNull, reason: raw);
      expect(prefs.getString(PendingMeetingStore.key), isNull, reason: raw);
    }
  });

  test('요일별이면 요일별로 바꾸기 전의 날짜를 함께 두고 꺼내, 벗어나면 그 날짜로 돌아간다', () async {
    final weekly = MeetingDraft(
      mode: MeetingMode.daily,
      dates: march(12, 14),
    ).withMode(MeetingMode.weekly);
    await store.save((
      flow: MeetingFlow(draft: weekly, expanded: true),
      title: '',
    ));

    final restored = store.take(today: today)!.flow.draft;

    expect(restored.mode, MeetingMode.weekly);
    expect(restored.dates.days, march(12, 18).days);
    expect(restored.beforeWeekly?.days, march(12, 14).days);
    expect(
      restored.withMode(MeetingMode.hourly).dates.days,
      march(12, 14).days,
    );
  });

  test('기억한 날짜가 없는 요일별은 기억 없이 꺼내, 시간별은 앞의 5일로 줄인다', () async {
    final weekly = MeetingDraft(mode: MeetingMode.weekly, dates: march(12, 18));
    await store.save((
      flow: MeetingFlow(draft: weekly, expanded: true),
      title: '',
    ));

    final restored = store.take(today: today)!.flow.draft;

    expect(restored.dates.days, march(12, 18).days);
    expect(restored.beforeWeekly, isNull);
    expect(
      restored.withMode(MeetingMode.hourly).dates.days,
      march(12, 16).days,
    );
  });
}
