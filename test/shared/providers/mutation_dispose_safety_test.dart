import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_mutations.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../helpers/schedule_fixtures.dart';

// 정책: ref.mounted 가드 기반 mutation notifier(ScheduleMutations)는 await(=async
// gap) 이후 provider가 dispose돼도 ref/state를 만지지 않는다. provider가 먼저
// dispose된 뒤 API 응답이 도착해도 UnmountedRefException이 발생하면 안 된다.
//   - 성공 직전 dispose: ref 후처리를 건너뛰되 완료는 정상
//   - 실패 직전 dispose: catch state 갱신을 건너뛰되 "원래 에러"가 전파
//
// (Tag·Todo 도메인은 Mutation API 기반으로 전환되어 이 가드 패턴을 쓰지 않으므로
//  각각 tag_providers_test.dart / todo_mutations_test.dart 로 분리되어 있다.)

class MockSchedulesClient extends Mock implements SchedulesClient {}

class FakeScheduleCreate extends Fake implements ScheduleCreate {}

class FakeScheduleUpdate extends Fake implements ScheduleUpdate {}

final Exception _apiError = Exception('api-failure');

final Matcher _propagatesOriginalError = throwsA(
  predicate(
    (Object? e) =>
        e.toString().contains('api-failure') &&
        !e.toString().contains('disposed'),
    'rethrows the original error, not a disposed-ref error',
  ),
);

ProviderContainer _container(dynamic overrides) {
  final container = ProviderContainer(overrides: overrides);
  addTearDown(() {
    try {
      container.dispose();
    } catch (_) {
      // 일부 테스트는 pending API 완료 전에 의도적으로 dispose한다.
    }
  });
  return container;
}

/// await 도중 container를 dispose시킨 뒤 pending 작업을 마무리한다.
Future<T> _disposeDuringAwait<T>(
  ProviderContainer container,
  Future<T> mutation,
  void Function() settle,
) async {
  await Future<void>.delayed(Duration.zero);
  container.dispose();
  settle();
  return mutation;
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeScheduleCreate());
    registerFallbackValue(FakeScheduleUpdate());
  });

  group('ScheduleMutations: async gap 이후 dispose 안전성', () {
    late MockSchedulesClient api;
    late ProviderContainer container;
    ScheduleMutations notifier() =>
        container.read(scheduleMutationsProvider.notifier);

    setUp(() {
      api = MockSchedulesClient();
      container = _container([schedulesApiProvider.overrideWithValue(api)]);
    });

    group('createSchedule', () {
      void stub(Completer<ScheduleRead> pending) => when(
        () => api.createScheduleV1SchedulesPost(body: any(named: 'body')),
      ).thenAnswer((_) => pending.future);
      final data = ScheduleCreate(
        title: 's',
        startTime: DateTime.utc(2026, 1, 1, 9),
        endTime: DateTime.utc(2026, 1, 1, 10),
      );

      test('성공 직전 dispose돼도 정상 완료한다', () async {
        final pending = Completer<ScheduleRead>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().createSchedule(data),
          () => pending.complete(makeSchedule()),
        );
        await expectLater(result, completes);
      });

      test('실패 직전 dispose돼도 원래 에러를 던진다', () async {
        final pending = Completer<ScheduleRead>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().createSchedule(data),
          () => pending.completeError(_apiError),
        );
        await expectLater(result, _propagatesOriginalError);
      });
    });

    group('updateSchedule', () {
      void stub(Completer<ScheduleRead> pending) => when(
        () => api.updateScheduleV1SchedulesScheduleIdPatch(
          scheduleId: any(named: 'scheduleId'),
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => pending.future);
      final data = ScheduleUpdate(title: 's2');

      test('성공 직전 dispose돼도 정상 완료한다', () async {
        final pending = Completer<ScheduleRead>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().updateSchedule('schedule-1', data),
          () => pending.complete(makeSchedule()),
        );
        await expectLater(result, completes);
      });

      test('실패 직전 dispose돼도 원래 에러를 던진다', () async {
        final pending = Completer<ScheduleRead>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().updateSchedule('schedule-1', data),
          () => pending.completeError(_apiError),
        );
        await expectLater(result, _propagatesOriginalError);
      });
    });

    group('deleteSchedule', () {
      void stub(Completer<void> pending) => when(
        () => api.deleteScheduleV1SchedulesScheduleIdDelete(
          scheduleId: any(named: 'scheduleId'),
          instanceStart: any(named: 'instanceStart'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => pending.future);

      test('성공 직전 dispose돼도 정상 완료한다', () async {
        final pending = Completer<void>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().deleteSchedule('schedule-1'),
          () => pending.complete(),
        );
        await expectLater(result, completes);
      });

      test('실패 직전 dispose돼도 원래 에러를 던진다', () async {
        final pending = Completer<void>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().deleteSchedule('schedule-1'),
          () => pending.completeError(_apiError),
        );
        await expectLater(result, _propagatesOriginalError);
      });
    });

    group('convertToTodo', () {
      void stub(Completer<void> pending) => when(
        () => api.createTodoFromScheduleV1SchedulesScheduleIdTodoPost(
          scheduleId: any(named: 'scheduleId'),
          tagGroupId: any(named: 'tagGroupId'),
        ),
      ).thenAnswer((_) => pending.future);

      test('성공 직전 dispose돼도 정상 완료한다', () async {
        final pending = Completer<void>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().convertToTodo('schedule-1', 'group-1'),
          () => pending.complete(),
        );
        await expectLater(result, completes);
      });

      test('실패 직전 dispose돼도 원래 에러를 던진다', () async {
        final pending = Completer<void>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().convertToTodo('schedule-1', 'group-1'),
          () => pending.completeError(_apiError),
        );
        await expectLater(result, _propagatesOriginalError);
      });
    });
  });
}
