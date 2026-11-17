import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../meeting_fixtures.dart';

void main() {
  late FakeMeetingsClient meetings;

  setUp(() => meetings = FakeMeetingsClient());

  ProviderContainer open() {
    final container = ProviderContainer(
      overrides: meetingOverrides(meetings: meetings),
    );
    addTearDown(container.dispose);
    container.listen(myMeetingsProvider, (_, _) {});
    return container;
  }

  test('내 모임은 받은 순서와 상관없이 새로 만든 순이다', () {
    fakeAsync((async) {
      meetings.mine = [
        for (final day in [3, 9, 5])
          makeMeeting(id: 'm$day', createdAt: DateTime.utc(2027, 1, day)),
      ];
      final container = open();
      async.flushMicrotasks();

      expect(
        [for (final m in container.read(myMeetingsProvider).requireValue) m.id],
        ['m9', 'm5', 'm3'],
      );
    });
  });

  test('모임을 만들면 내 모임을 다시 받는다', () {
    fakeAsync((async) {
      final container = open();
      async.flushMicrotasks();
      expect(meetings.listReads, 1);

      container
          .read(meetingMutationsProvider.notifier)
          .create(
            MeetingCreate(
              title: '킥오프',
              startDate: DateTime.utc(2027, 3, 1),
              endDate: DateTime.utc(2027, 3, 5),
              timezone: 'Asia/Seoul',
              mode: MeetingMode.hourly,
              startTime: '06:00:00',
              endTime: '18:00:00',
            ),
            visibility: const VisibilityUpdate(level: VisibilityLevel.public),
            allowGuests: false,
          );
      async.elapse(const Duration(milliseconds: 1));

      expect(meetings.listReads, 2);
    });
  });

  test('만들다 실패하면 다시 받지 않는다', () {
    fakeAsync((async) {
      meetings.createError = Exception('끊김');
      final container = open();
      async.flushMicrotasks();

      container
          .read(meetingMutationsProvider.notifier)
          .create(
            MeetingCreate(
              title: '킥오프',
              startDate: DateTime.utc(2027, 3, 1),
              endDate: DateTime.utc(2027, 3, 5),
              timezone: 'Asia/Seoul',
              mode: MeetingMode.hourly,
              startTime: '06:00:00',
              endTime: '18:00:00',
            ),
            visibility: const VisibilityUpdate(level: VisibilityLevel.public),
            allowGuests: false,
          )
          .ignore();
      async.elapse(const Duration(milliseconds: 1));

      expect(meetings.listReads, 1);
    });
  });
}
