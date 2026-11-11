import 'package:dio/dio.dart' show RequestOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/auth/auth_user.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/mypage/presentation/providers/my_page_providers.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../helpers/fake_rest_clients.dart';

/// 인증 상태를 테스트에서 직접 바꾸는 [AuthNotifier].
class _Auth extends AuthNotifier {
  var _jwts = 0;

  @override
  AuthStatus build() => const AuthStatus.unauthenticated();

  void signIn(AuthUser user) => state = AuthStatus.authenticated(
    user: user,
    accessToken: 'jwt-${++_jwts}',
  );

  void leave() => state = const AuthStatus.unauthenticated();
}

/// 계정마다 다른 태그 통계를 돌려주는 [FakeTodosClient].
class _TodosClient extends FakeTodosClient {
  List<TagStat> byTag = const [];
  int statsReads = 0;

  @override
  Future<TodoStats> getTodoStatsV1TodosStatsGet({
    String? groupId,
    RequestOptions? options,
  }) async {
    statsReads++;
    return TodoStats(totalCount: todos.length, byTag: byTag);
  }
}

AuthUser _user(String id) => AuthUser(
  id: id,
  email: '$id@example.com',
  emailVerified: true,
  createdAt: DateTime.utc(2024, 1, 1),
);

TodoRead _todo(String id, {TodoStatus status = TodoStatus.unscheduled}) =>
    TodoRead(
      id: id,
      title: id,
      tagGroupId: 'g1',
      status: status,
      createdAt: DateTime.utc(2024, 1, 1),
    );

void main() {
  late _TodosClient api;
  late ProviderContainer container;

  _Auth auth() => container.read(authProvider.notifier) as _Auth;

  /// A에서 로그아웃하고, 서버가 B의 데이터를 돌려주게 한 뒤 B로 로그인한다.
  Future<void> switchFromAToB() async {
    auth().leave();
    await container.pump();
    api.todos
      ..clear()
      ..addAll([_todo('b-1', status: TodoStatus.done), _todo('b-2')]);
    api.byTag = const [TagStat(tagId: 'tb', tagName: 'B 태그', count: 2)];
    auth().signIn(_user('b'));
  }

  setUp(() {
    api = _TodosClient()..todos.add(_todo('a-1'));
    api.byTag = const [TagStat(tagId: 'ta', tagName: 'A 태그', count: 1)];
    container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_Auth.new),
        todosApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    auth().signIn(_user('a'));
  });

  group('로그인한 사용자 ID가 바뀌면', () {
    test('할 일 목록과 트리를 새 계정 것으로 다시 받는다', () async {
      expect((await container.read(allTodosProvider.future)).map((t) => t.id), [
        'a-1',
      ]);
      expect(
        (await container.read(todosProvider('g1').future)).map((t) => t.id),
        ['a-1'],
      );
      expect((await container.read(allTodoTreeProvider.future)).flatOrder, [
        'a-1',
      ]);
      await container.read(todoTreeProvider('g1').future);

      await switchFromAToB();

      expect((await container.read(allTodosProvider.future)).map((t) => t.id), [
        'b-1',
        'b-2',
      ]);
      expect(
        (await container.read(todosProvider('g1').future)).map((t) => t.id),
        ['b-1', 'b-2'],
      );
      expect((await container.read(allTodoTreeProvider.future)).flatOrder, [
        'b-1',
        'b-2',
      ]);
      expect((await container.read(todoTreeProvider('g1').future)).flatOrder, [
        'b-1',
        'b-2',
      ]);
    });

    test('마이페이지의 프로필·할 일 통계·태그 통계를 새 계정 것으로 바꾼다', () async {
      expect(
        (await container.read(userProfileProvider.future))?.email,
        'a@example.com',
      );
      expect(
        (await container.read(todoStatisticsProvider.future)).totalCount,
        1,
      );
      expect(
        (await container.read(
          tagUsageStatisticsProvider.future,
        )).tagUsageMap.keys,
        ['ta'],
      );

      await switchFromAToB();

      expect(
        (await container.read(userProfileProvider.future))?.email,
        'b@example.com',
      );
      final stats = await container.read(todoStatisticsProvider.future);
      expect((stats.totalCount, stats.doneCount), (2, 1));
      expect(
        (await container.read(
          tagUsageStatisticsProvider.future,
        )).tagUsageMap.keys,
        ['tb'],
      );
    });

    test('B로 바꿨다가 A로 돌아오면 B의 값이 아니라 A의 것을 다시 받는다', () async {
      await container.read(allTodosProvider.future);
      await container.read(tagUsageStatisticsProvider.future);
      await switchFromAToB();
      expect((await container.read(allTodosProvider.future)).map((t) => t.id), [
        'b-1',
        'b-2',
      ]);
      expect(
        (await container.read(
          tagUsageStatisticsProvider.future,
        )).tagUsageMap.keys,
        ['tb'],
      );

      auth().leave();
      await container.pump();
      api.todos
        ..clear()
        ..add(_todo('a-1'));
      api.byTag = const [TagStat(tagId: 'ta', tagName: 'A 태그', count: 1)];
      auth().signIn(_user('a'));

      expect((await container.read(allTodosProvider.future)).map((t) => t.id), [
        'a-1',
      ]);
      expect(
        (await container.read(
          tagUsageStatisticsProvider.future,
        )).tagUsageMap.keys,
        ['ta'],
      );
    });
  });

  group('JWT만 새로 받으면', () {
    test('같은 사용자로 보고 계정별 데이터를 다시 받거나 계산하지 않는다', () async {
      final profile = await container.read(userProfileProvider.future);
      await container.read(allTodoTreeProvider.future);
      await container.read(todoStatisticsProvider.future);
      await container.read(tagUsageStatisticsProvider.future);
      final todoReads = api.readGroupIds.length;
      final statsReads = api.statsReads;

      final userChanges = <AuthUser?>[];
      container.listen(currentUserProvider, (_, next) => userChanges.add(next));

      auth().signIn(_user('a'));
      await container.pump();

      expect(userChanges, isEmpty);
      expect(await container.read(userProfileProvider.future), same(profile));
      await container.read(allTodoTreeProvider.future);
      await container.read(todoStatisticsProvider.future);
      await container.read(tagUsageStatisticsProvider.future);
      expect(api.readGroupIds.length, todoReads);
      expect(api.statsReads, statsReads);
    });
  });
}
