import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

class MockTodosClient extends Mock implements TodosClient {}

class FakeTodoCreate extends Fake implements TodoCreate {}

class FakeTodoUpdate extends Fake implements TodoUpdate {}

TodoRead _todo() => TodoRead(
  id: 'todo-1',
  title: 'todo',
  tagGroupId: 'g1',
  status: TodoStatus.unscheduled,
  createdAt: DateTime(2025, 1, 1),
);

void main() {
  late MockTodosClient api;

  setUpAll(() {
    registerFallbackValue(FakeTodoCreate());
    registerFallbackValue(FakeTodoUpdate());
  });

  setUp(() {
    api = MockTodosClient();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [todosApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    return container;
  }

  void stubList() {
    when(
      () => api.readTodosV1TodosGet(
        tagIds: any(named: 'tagIds'),
        groupIds: any(named: 'groupIds'),
        scope: any(named: 'scope'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => <TodoRead>[]);
  }

  void readTodosCalled(int n) {
    verify(
      () => api.readTodosV1TodosGet(
        tagIds: any(named: 'tagIds'),
        groupIds: any(named: 'groupIds'),
        scope: any(named: 'scope'),
        options: any(named: 'options'),
      ),
    ).called(n);
  }

  group('TodoMutationsNotifier - CUD가 해당 REST API를 호출한다', () {
    test('create', () async {
      stubList();
      when(
        () => api.createTodoV1TodosPost(
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => _todo());

      final container = makeContainer();
      await container
          .read(todoMutationsProvider.notifier)
          .create(TodoCreate(title: 't', tagGroupId: 'g1'));

      verify(
        () => api.createTodoV1TodosPost(
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('update', () async {
      stubList();
      when(
        () => api.updateTodoV1TodosTodoIdPatch(
          todoId: any(named: 'todoId'),
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => _todo());

      final container = makeContainer();
      await container
          .read(todoMutationsProvider.notifier)
          .update('todo-1', TodoUpdate(title: 't2'));

      verify(
        () => api.updateTodoV1TodosTodoIdPatch(
          todoId: 'todo-1',
          body: any(named: 'body'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('delete', () async {
      stubList();
      when(
        () => api.deleteTodoV1TodosTodoIdDelete(
          todoId: any(named: 'todoId'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});

      final container = makeContainer();
      await container.read(todoMutationsProvider.notifier).delete('todo-1');

      verify(
        () => api.deleteTodoV1TodosTodoIdDelete(
          todoId: 'todo-1',
          options: any(named: 'options'),
        ),
      ).called(1);
    });
  });

  group('TodoMutationsNotifier - 캐시 갱신', () {
    test('CUD 후 todosProvider가 재조회된다', () async {
      stubList();
      when(
        () => api.deleteTodoV1TodosTodoIdDelete(
          todoId: any(named: 'todoId'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});

      final container = makeContainer();
      container.listen(todosProvider(null), (_, _) {});
      await container.read(todosProvider(null).future);
      await container.read(todoMutationsProvider.notifier).delete('todo-1');
      await container.read(todosProvider(null).future);

      readTodosCalled(2);
    });
  });

  group('Mutation - UI operation state', () {
    test('run 성공 시 MutationSuccess가 되고 목록이 갱신된다', () async {
      stubList();
      when(
        () => api.deleteTodoV1TodosTodoIdDelete(
          todoId: any(named: 'todoId'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});

      final container = makeContainer();
      container.listen(todosProvider(null), (_, _) {});
      container.listen(deleteTodoMutation, (_, _) {});
      await container.read(todosProvider(null).future);

      await deleteTodoMutation.run(
        container,
        (tsx) => tsx.get(todoMutationsProvider.notifier).delete('todo-1'),
      );

      expect(container.read(deleteTodoMutation).isSuccess, isTrue);
      await container.read(todosProvider(null).future);
      readTodosCalled(2);
    });

    test('run 실패 시 원래 에러를 rethrow하고 MutationError가 된다', () async {
      stubList();
      when(
        () => api.deleteTodoV1TodosTodoIdDelete(
          todoId: any(named: 'todoId'),
          options: any(named: 'options'),
        ),
      ).thenThrow(Exception('delete-failed'));

      final container = makeContainer();
      container.listen(deleteTodoMutation, (_, _) {});

      await expectLater(
        deleteTodoMutation.run(
          container,
          (tsx) => tsx.get(todoMutationsProvider.notifier).delete('todo-1'),
        ),
        throwsA(
          predicate((Object? e) => e.toString().contains('delete-failed')),
        ),
      );

      expect(container.read(deleteTodoMutation).hasError, isTrue);
    });
  });
}
