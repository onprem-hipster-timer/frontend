import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

/// 다른 사람이 나에게 공유한 할 일 (`scope=shared`). 내 할 일 그룹에는 넣지 않는다
final sharedTodosProvider = FutureProvider.autoDispose<List<TodoRead>>(
  (ref) => ref
      .watch(todosApiProvider)
      .readTodosV1TodosGet(scope: ResourceScope.shared),
);
