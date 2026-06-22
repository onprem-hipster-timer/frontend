import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_mutations.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/providers/tag_providers.dart';

import '../../helpers/schedule_fixtures.dart';

// 정책: 모든 async mutation은 await(=async gap) 이후 provider가 dispose되면
// ref/state를 만지지 않는다. 화면 이탈·scope teardown 등으로 mutation provider가
// 먼저 dispose된 뒤 API 응답이 도착해도 Riverpod의 UnmountedRefException
// ("Cannot use the Ref ... after it has been disposed")이 발생하면 안 된다.
//
// 각 mutation마다 두 경로를 본다.
//   - 성공 직전 dispose: ref 후처리를 건너뛰되 결과/완료는 정상 반환
//   - 실패 직전 dispose: catch의 state 갱신을 건너뛰되 "원래 에러"가 전파
//     (disposed-ref 에러로 뒤바뀌지 않아야 함)

class MockTagsClient extends Mock implements TagsClient {}

class MockSchedulesClient extends Mock implements SchedulesClient {}

class MockTodosClient extends Mock implements TodosClient {}

class FakeTagGroupCreate extends Fake implements TagGroupCreate {}

class FakeTagGroupUpdate extends Fake implements TagGroupUpdate {}

class FakeTagCreate extends Fake implements TagCreate {}

class FakeTagUpdate extends Fake implements TagUpdate {}

class FakeScheduleCreate extends Fake implements ScheduleCreate {}

class FakeScheduleUpdate extends Fake implements ScheduleUpdate {}

class FakeTodoCreate extends Fake implements TodoCreate {}

class FakeTodoUpdate extends Fake implements TodoUpdate {}

/// API 호출 실패를 흉내 내는 에러.
final Exception _apiError = Exception('api-failure');

/// dispose 이후 실패 경로에서 "원래 에러"가 그대로 전파되고,
/// disposed-ref 에러로 뒤바뀌지 않았음을 확인하는 matcher.
final Matcher _propagatesOriginalError = throwsA(
  predicate(
    (Object? e) =>
        e.toString().contains('api-failure') &&
        !e.toString().contains('disposed'),
    'rethrows the original error, not a disposed-ref error',
  ),
);

TagGroupRead _tagGroup() => TagGroupRead(
  id: 'group-1',
  name: 'group',
  color: '#3498DB',
  createdAt: DateTime(2025, 1, 1),
  updatedAt: DateTime(2025, 1, 1),
);

TodoRead _todo() => TodoRead(
  id: 'todo-1',
  title: 'todo',
  tagGroupId: 'group-1',
  status: TodoStatus.unscheduled,
  createdAt: DateTime(2025, 1, 1),
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
/// 이미 시작된 [mutation] future를 그대로 돌려주므로 호출부에서 matcher로 검증한다.
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
    registerFallbackValue(FakeTagGroupCreate());
    registerFallbackValue(FakeTagGroupUpdate());
    registerFallbackValue(FakeTagCreate());
    registerFallbackValue(FakeTagUpdate());
    registerFallbackValue(FakeScheduleCreate());
    registerFallbackValue(FakeScheduleUpdate());
    registerFallbackValue(FakeTodoCreate());
    registerFallbackValue(FakeTodoUpdate());
  });

  group('TagMutations: async gap 이후 dispose 안전성', () {
    late MockTagsClient api;
    late ProviderContainer container;
    TagMutations notifier() => container.read(tagMutationsProvider.notifier);

    setUp(() {
      api = MockTagsClient();
      container = _container([tagsApiProvider.overrideWithValue(api)]);
    });

    group('createGroup', () {
      void stub(Completer<TagGroupRead> pending) => when(
        () => api.createTagGroupV1TagsGroupsPost(
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => pending.future);
      final data = TagGroupCreate(name: 'g', color: '#000000');

      test('성공 직전 dispose돼도 결과를 반환한다', () async {
        final pending = Completer<TagGroupRead>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().createGroup(data),
          () => pending.complete(_tagGroup()),
        );
        await expectLater(result, completion(isA<TagGroupRead>()));
      });

      test('실패 직전 dispose돼도 원래 에러를 던진다', () async {
        final pending = Completer<TagGroupRead>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().createGroup(data),
          () => pending.completeError(_apiError),
        );
        await expectLater(result, _propagatesOriginalError);
      });
    });

    group('updateGroup', () {
      void stub(Completer<TagGroupRead> pending) => when(
        () => api.updateTagGroupV1TagsGroupsGroupIdPatch(
          groupId: any(named: 'groupId'),
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => pending.future);
      final data = TagGroupUpdate(name: 'g2');

      test('성공 직전 dispose돼도 결과를 반환한다', () async {
        final pending = Completer<TagGroupRead>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().updateGroup('group-1', data),
          () => pending.complete(_tagGroup()),
        );
        await expectLater(result, completion(isA<TagGroupRead>()));
      });

      test('실패 직전 dispose돼도 원래 에러를 던진다', () async {
        final pending = Completer<TagGroupRead>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().updateGroup('group-1', data),
          () => pending.completeError(_apiError),
        );
        await expectLater(result, _propagatesOriginalError);
      });
    });

    group('deleteGroup', () {
      void stub(Completer<void> pending) => when(
        () => api.deleteTagGroupV1TagsGroupsGroupIdDelete(
          groupId: any(named: 'groupId'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => pending.future);

      test('성공 직전 dispose돼도 정상 완료한다', () async {
        final pending = Completer<void>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().deleteGroup('group-1'),
          () => pending.complete(),
        );
        await expectLater(result, completes);
      });

      test('실패 직전 dispose돼도 원래 에러를 던진다', () async {
        final pending = Completer<void>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().deleteGroup('group-1'),
          () => pending.completeError(_apiError),
        );
        await expectLater(result, _propagatesOriginalError);
      });
    });

    group('createTag', () {
      void stub(Completer<TagRead> pending) => when(
        () => api.createTagV1TagsPost(
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => pending.future);
      final data = TagCreate(name: 't', color: '#FF5733', groupId: 'group-1');

      test('성공 직전 dispose돼도 결과를 반환한다', () async {
        final pending = Completer<TagRead>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().createTag(data),
          () => pending.complete(makeTag()),
        );
        await expectLater(result, completion(isA<TagRead>()));
      });

      test('실패 직전 dispose돼도 원래 에러를 던진다', () async {
        final pending = Completer<TagRead>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().createTag(data),
          () => pending.completeError(_apiError),
        );
        await expectLater(result, _propagatesOriginalError);
      });
    });

    group('updateTag', () {
      void stub(Completer<TagRead> pending) => when(
        () => api.updateTagV1TagsTagIdPatch(
          tagId: any(named: 'tagId'),
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => pending.future);
      final data = TagUpdate(name: 't2');

      test('성공 직전 dispose돼도 결과를 반환한다', () async {
        final pending = Completer<TagRead>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().updateTag('tag-1', data),
          () => pending.complete(makeTag()),
        );
        await expectLater(result, completion(isA<TagRead>()));
      });

      test('실패 직전 dispose돼도 원래 에러를 던진다', () async {
        final pending = Completer<TagRead>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().updateTag('tag-1', data),
          () => pending.completeError(_apiError),
        );
        await expectLater(result, _propagatesOriginalError);
      });
    });

    group('deleteTag', () {
      void stub(Completer<void> pending) => when(
        () => api.deleteTagV1TagsTagIdDelete(
          tagId: any(named: 'tagId'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => pending.future);

      test('성공 직전 dispose돼도 정상 완료한다', () async {
        final pending = Completer<void>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().deleteTag('tag-1'),
          () => pending.complete(),
        );
        await expectLater(result, completes);
      });

      test('실패 직전 dispose돼도 원래 에러를 던진다', () async {
        final pending = Completer<void>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().deleteTag('tag-1'),
          () => pending.completeError(_apiError),
        );
        await expectLater(result, _propagatesOriginalError);
      });
    });
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

  group('TodoMutationsNotifier: async gap 이후 dispose 안전성', () {
    late MockTodosClient api;
    late ProviderContainer container;
    TodoMutationsNotifier notifier() =>
        container.read(todoMutationsProvider.notifier);

    setUp(() {
      api = MockTodosClient();
      container = _container([todosApiProvider.overrideWithValue(api)]);
    });

    group('create', () {
      void stub(Completer<TodoRead> pending) => when(
        () => api.createTodoV1TodosPost(body: any(named: 'body')),
      ).thenAnswer((_) => pending.future);
      final data = TodoCreate(title: 'todo', tagGroupId: 'group-1');

      test('성공 직전 dispose돼도 결과를 반환한다', () async {
        final pending = Completer<TodoRead>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().create(data),
          () => pending.complete(_todo()),
        );
        await expectLater(result, completion(isA<TodoRead>()));
      });

      test('실패 직전 dispose돼도 원래 에러를 던진다', () async {
        final pending = Completer<TodoRead>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().create(data),
          () => pending.completeError(_apiError),
        );
        await expectLater(result, _propagatesOriginalError);
      });
    });

    group('update', () {
      void stub(Completer<TodoRead> pending) => when(
        () => api.updateTodoV1TodosTodoIdPatch(
          todoId: any(named: 'todoId'),
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => pending.future);
      final data = TodoUpdate(title: 'todo2');

      test('성공 직전 dispose돼도 결과를 반환한다', () async {
        final pending = Completer<TodoRead>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().update('todo-1', data),
          () => pending.complete(_todo()),
        );
        await expectLater(result, completion(isA<TodoRead>()));
      });

      test('실패 직전 dispose돼도 원래 에러를 던진다', () async {
        final pending = Completer<TodoRead>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().update('todo-1', data),
          () => pending.completeError(_apiError),
        );
        await expectLater(result, _propagatesOriginalError);
      });
    });

    group('delete', () {
      void stub(Completer<void> pending) => when(
        () => api.deleteTodoV1TodosTodoIdDelete(
          todoId: any(named: 'todoId'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => pending.future);

      // delete는 에러를 rethrow하지 않고 bool로 결과를 알리는 계약이라
      // 성공/실패 각각 true/false로 완료되어야 한다(둘 다 disposed-ref 에러 없이).
      test('성공 직전 dispose돼도 true로 완료한다', () async {
        final pending = Completer<void>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().delete('todo-1'),
          () => pending.complete(),
        );
        await expectLater(result, completion(isTrue));
      });

      test('실패 직전 dispose돼도 false로 완료한다', () async {
        final pending = Completer<void>();
        stub(pending);
        final result = _disposeDuringAwait(
          container,
          notifier().delete('todo-1'),
          () => pending.completeError(_apiError),
        );
        await expectLater(result, completion(isFalse));
      });
    });
  });
}
