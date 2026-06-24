import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_mutations.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/schedule_fixtures.dart';

class MockSchedulesClient extends Mock implements SchedulesClient {}

class FakeScheduleCreate extends Fake implements ScheduleCreate {}

class FakeScheduleUpdate extends Fake implements ScheduleUpdate {}

void main() {
  late MockSchedulesClient api;

  setUpAll(() {
    registerFallbackValue(FakeScheduleCreate());
    registerFallbackValue(FakeScheduleUpdate());
  });

  setUp(() {
    api = MockSchedulesClient();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [schedulesApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    return container;
  }

  final createData = ScheduleCreate(
    title: 's',
    startTime: DateTime.utc(2026, 1, 1, 9),
    endTime: DateTime.utc(2026, 1, 1, 10),
  );

  ScheduleMutations notifier(ProviderContainer c) =>
      c.read(scheduleMutationsProvider.notifier);

  group('ScheduleMutations - CUD가 REST API를 호출한다 (Mutation 경유)', () {
    test('createSchedule', () async {
      when(
        () => api.createScheduleV1SchedulesPost(body: any(named: 'body')),
      ).thenAnswer((_) async => makeSchedule());

      final c = makeContainer();
      await createScheduleMutation.run(
        c,
        (tsx) => tsx
            .get(scheduleMutationsProvider.notifier)
            .createSchedule(createData),
      );

      verify(
        () => api.createScheduleV1SchedulesPost(body: any(named: 'body')),
      ).called(1);
    });

    test('updateSchedule', () async {
      when(
        () => api.updateScheduleV1SchedulesScheduleIdPatch(
          scheduleId: any(named: 'scheduleId'),
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => makeSchedule());

      final c = makeContainer();
      await updateScheduleMutation.run(
        c,
        (tsx) => tsx
            .get(scheduleMutationsProvider.notifier)
            .updateSchedule('s1', ScheduleUpdate(title: 's2')),
      );

      verify(
        () => api.updateScheduleV1SchedulesScheduleIdPatch(
          scheduleId: 's1',
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('deleteSchedule', () async {
      when(
        () => api.deleteScheduleV1SchedulesScheduleIdDelete(
          scheduleId: any(named: 'scheduleId'),
          instanceStart: any(named: 'instanceStart'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});

      final c = makeContainer();
      await deleteScheduleMutation.run(
        c,
        (tsx) =>
            tsx.get(scheduleMutationsProvider.notifier).deleteSchedule('s1'),
      );

      verify(
        () => api.deleteScheduleV1SchedulesScheduleIdDelete(
          scheduleId: 's1',
          instanceStart: any(named: 'instanceStart'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('convertToTodo', () async {
      when(
        () => api.createTodoFromScheduleV1SchedulesScheduleIdTodoPost(
          scheduleId: any(named: 'scheduleId'),
          tagGroupId: any(named: 'tagGroupId'),
        ),
      ).thenAnswer((_) async {});

      final c = makeContainer();
      await convertToTodoMutation.run(
        c,
        (tsx) => tsx
            .get(scheduleMutationsProvider.notifier)
            .convertToTodo('s1', 'group-1'),
      );

      verify(
        () => api.createTodoFromScheduleV1SchedulesScheduleIdTodoPost(
          scheduleId: 's1',
          tagGroupId: 'group-1',
        ),
      ).called(1);
    });

    test('moveSchedule는 updateSchedule API를 호출한다', () async {
      when(
        () => api.updateScheduleV1SchedulesScheduleIdPatch(
          scheduleId: any(named: 'scheduleId'),
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => makeSchedule());

      final c = makeContainer();
      await notifier(c).moveSchedule(
        's1',
        newStartTime: DateTime.utc(2026, 1, 2, 9),
        newEndTime: DateTime.utc(2026, 1, 2, 10),
      );

      verify(
        () => api.updateScheduleV1SchedulesScheduleIdPatch(
          scheduleId: 's1',
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });
  });

  group('Mutation - UI operation state', () {
    test('run 성공 시 상태가 MutationSuccess가 된다', () async {
      when(
        () => api.deleteScheduleV1SchedulesScheduleIdDelete(
          scheduleId: any(named: 'scheduleId'),
          instanceStart: any(named: 'instanceStart'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});

      final c = makeContainer();
      c.listen(deleteScheduleMutation, (_, _) {});

      await deleteScheduleMutation.run(
        c,
        (tsx) =>
            tsx.get(scheduleMutationsProvider.notifier).deleteSchedule('s1'),
      );

      expect(c.read(deleteScheduleMutation).isSuccess, isTrue);
    });

    test('run 실패 시 원래 에러를 rethrow하고 MutationError가 된다', () async {
      when(
        () => api.deleteScheduleV1SchedulesScheduleIdDelete(
          scheduleId: any(named: 'scheduleId'),
          instanceStart: any(named: 'instanceStart'),
          options: any(named: 'options'),
        ),
      ).thenThrow(Exception('delete-failed'));

      final c = makeContainer();
      c.listen(deleteScheduleMutation, (_, _) {});

      await expectLater(
        deleteScheduleMutation.run(
          c,
          (tsx) =>
              tsx.get(scheduleMutationsProvider.notifier).deleteSchedule('s1'),
        ),
        throwsA(
          predicate((Object? e) => e.toString().contains('delete-failed')),
        ),
      );

      expect(c.read(deleteScheduleMutation).hasError, isTrue);
    });
  });
}
