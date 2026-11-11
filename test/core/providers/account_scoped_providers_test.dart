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
