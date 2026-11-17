import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
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

  test('둔 폼을 그대로 꺼내고 지운다', () async {
    final draft = const MeetingDraft()
        .tapDay(DateTime.utc(2027, 3, 12))
        .tapDay(DateTime.utc(2027, 3, 15))
        .withStartHour(9)
        .withEndHour(21)
        .withGuests(false);
    await store.save((draft: draft, title: ' 스터디 '));

    final taken = store.take(today: today)!;

    expect(taken.title, ' 스터디 ');
    expect(taken.draft.mode, MeetingMode.hourly);
    expect(taken.draft.dates.days, draft.dates.days);
    expect(taken.draft.startHour, 9);
    expect(taken.draft.endHour, 21);
    expect(taken.draft.isPublic, isTrue);
    expect(taken.draft.allowGuests, isFalse);
    expect(store.take(today: today), isNull, reason: '한 번만 꺼낸다');
  });

  test('요일별·비공개도 그대로 꺼낸다', () async {
    final draft = const MeetingDraft()
        .withMode(MeetingMode.weekly)
        .tapDay(DateTime.utc(2027, 3, 10))
        .withPublic(false);
    await store.save((draft: draft, title: ''));

    final taken = store.take(today: today)!.draft;

    expect(taken.mode, MeetingMode.weekly);
    expect(
      taken.dates.days,
      MeetingDates.period(DateTime.utc(2027, 3, 10), 7).days,
    );
    expect(taken.isPublic, isFalse);
    expect(taken.allowGuests, isFalse);
  });

  test('날짜를 고르지 않은 폼도 꺼낸다', () async {
    await store.save((draft: const MeetingDraft(), title: '스터디'));

    expect(store.take(today: today)?.draft.dates.isEmpty, isTrue);
  });

  test('첫날이 오늘보다 앞이면 버린다', () async {
    final draft = const MeetingDraft().tapDay(DateTime.utc(2027, 3, 9));
    await store.save((draft: draft, title: '스터디'));

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
      for (final day in pending.draft.dates.days) day.day,
    ];

    test('시간별인데 기간이 5일을 넘으면 날짜별로 바꾼다', () {
      final taken = takeStored({
        'days': ['2027-03-12', '2027-03-20'],
      })!;
      expect(taken.draft.mode, MeetingMode.daily);
      expect(daysOf(taken), [12, 20]);
    });

    test('요일별인데 이어진 7일이 아니면 첫날부터 7일로 맞춘다', () {
      final taken = takeStored({
        'mode': 'weekly',
        'days': ['2027-03-12', '2027-03-14'],
      })!;
      expect(taken.draft.mode, MeetingMode.weekly);
      expect(daysOf(taken), [12, 13, 14, 15, 16, 17, 18]);
    });

    test('공개가 아니면 게스트 로그인을 끈다', () {
      final taken = takeStored({'public': false, 'guests': true})!;
      expect(taken.draft.isPublic, isFalse);
      expect(taken.draft.allowGuests, isFalse);
    });

    test('끝이 시작보다 늦지 않으면 끝을 시작 한 시간 뒤로 민다', () {
      final taken = takeStored({'start_hour': 20, 'end_hour': 18})!;
      expect(taken.draft.startHour, 20);
      expect(taken.draft.endHour, 21);
    });

    test('0시 시작과 24시 끝은 그대로 꺼낸다', () {
      final taken = takeStored({'start_hour': 0, 'end_hour': 24})!;
      expect(taken.draft.startHour, 0);
      expect(taken.draft.endHour, 24);
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
}
