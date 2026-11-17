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

  test('읽을 수 없는 값은 버린다', () async {
    for (final raw in ['', '{', '[]', '{"mode":"monthly"}', '{"days":[1]}']) {
      await prefs.setString(PendingMeetingStore.key, raw);
      expect(store.take(today: today), isNull, reason: raw);
      expect(prefs.getString(PendingMeetingStore.key), isNull, reason: raw);
    }
  });
}
