// Todo Feature - Providers
import 'package:built_collection/built_collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet_api/momeet_api.dart';

import '../utils/todo_tree_builder.dart';

// ============================================================
// Todo 목록 조회 Provider
// ============================================================

/// Todo 목록 조회 Provider
///
/// 선택적으로 그룹 ID로 필터링할 수 있습니다.
final todosProvider = FutureProvider.family<List<TodoRead>, String?>((ref, groupId) async {
  final api = ref.watch(todosApiProvider);

  final response = await api.readTodosV1TodosGet(
    groupIds: groupId != null ? BuiltList<String>([groupId]) : null,
  );

  return response.data?.toList() ?? [];
});

/// 모든 Todo 조회 (그룹 필터 없음)
final allTodosProvider = FutureProvider<List<TodoRead>>((ref) async {
  return ref.watch(todosProvider(null).future);
});

// ============================================================
// Todo 트리 구조 Provider
// ============================================================

/// Todo 트리 구조 Provider
///
/// 평면 목록을 계층형 트리로 변환합니다.
final todoTreeProvider = FutureProvider.family<TodoTree, String?>((ref, groupId) async {
  final todos = await ref.watch(todosProvider(groupId).future);
  return buildTodoTree(todos);
});

/// 모든 Todo의 트리 구조
final allTodoTreeProvider = FutureProvider<TodoTree>((ref) async {
  return ref.watch(todoTreeProvider(null).future);
});

// ============================================================
// Todo Mutations Provider (생성/수정/삭제)
// ============================================================

/// Todo 뮤테이션 Notifier
///
/// 생성, 수정, 삭제 작업을 처리하고 목록을 자동으로 갱신합니다.
class TodoMutationsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// 새 Todo 생성
  Future<TodoRead?> create(TodoCreate data) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(todosApiProvider);
      final response = await api.createTodoV1TodosPost(todoCreate: data);

      // 목록 갱신
      ref.invalidate(todosProvider);

      state = const AsyncValue.data(null);
      return response.data;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Todo 수정
  Future<TodoRead?> update(String todoId, TodoUpdate data) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(todosApiProvider);
      final response = await api.updateTodoV1TodosTodoIdPatch(
        todoId: todoId,
        todoUpdate: data,
      );

      // 목록 갱신
      ref.invalidate(todosProvider);

      state = const AsyncValue.data(null);
      return response.data;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Todo 삭제
  Future<bool> delete(String todoId) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(todosApiProvider);
      await api.deleteTodoV1TodosTodoIdDelete(todoId: todoId);

      // 목록 갱신
      ref.invalidate(todosProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 부모 변경 (드래그 앤 드롭)
  ///
  /// [todoId] 이동할 Todo ID
  /// [newParentId] 새 부모 ID (null이면 루트로 이동)
  Future<TodoRead?> changeParent(String todoId, String? newParentId) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(todosApiProvider);

      // TodoUpdate 빌더 사용
      final updateBuilder = TodoUpdateBuilder()
        ..parentId = newParentId;

      final response = await api.updateTodoV1TodosTodoIdPatch(
        todoId: todoId,
        todoUpdate: updateBuilder.build(),
      );

      // 목록 갱신
      ref.invalidate(todosProvider);

      state = const AsyncValue.data(null);
      return response.data;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// 상태 변경
  Future<TodoRead?> changeStatus(String todoId, TodoStatus newStatus) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(todosApiProvider);

      final updateBuilder = TodoUpdateBuilder()
        ..status = newStatus;

      final response = await api.updateTodoV1TodosTodoIdPatch(
        todoId: todoId,
        todoUpdate: updateBuilder.build(),
      );

      // 목록 갱신
      ref.invalidate(todosProvider);

      state = const AsyncValue.data(null);
      return response.data;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

/// Todo 뮤테이션 Provider
final todoMutationsProvider = NotifierProvider<TodoMutationsNotifier, AsyncValue<void>>(
  TodoMutationsNotifier.new,
);

// ============================================================
// UI 상태 Providers
// ============================================================

/// 확장된 노드 ID 집합 Notifier
class ExpandedTodoIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void add(String id) {
    state = {...state, id};
  }

  void remove(String id) {
    final newSet = Set<String>.from(state);
    newSet.remove(id);
    state = newSet;
  }

  void toggle(String id) {
    if (state.contains(id)) {
      remove(id);
    } else {
      add(id);
    }
  }

  void clear() {
    state = {};
  }

  void addAll(Iterable<String> ids) {
    state = {...state, ...ids};
  }
}

/// 확장된 노드 ID 집합 Provider
final expandedTodoIdsProvider = NotifierProvider<ExpandedTodoIdsNotifier, Set<String>>(
  ExpandedTodoIdsNotifier.new,
);

/// 선택된 Todo ID Notifier
class SelectedTodoIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) {
    state = id;
  }

  void clear() {
    state = null;
  }
}

/// 선택된 Todo ID Provider
final selectedTodoIdProvider = NotifierProvider<SelectedTodoIdNotifier, String?>(
  SelectedTodoIdNotifier.new,
);

/// 드래그 중인 Todo ID Notifier
class DraggingTodoIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setDragging(String? id) {
    state = id;
  }

  void clear() {
    state = null;
  }
}

/// 현재 드래그 중인 Todo ID Provider
final draggingTodoIdProvider = NotifierProvider<DraggingTodoIdNotifier, String?>(
  DraggingTodoIdNotifier.new,
);
