// Todo 트리 구조 빌더
//
// Flat한 Todo 리스트를 parent-child 관계로 트리 구조로 변환합니다.
import 'package:momeet/shared/api/export.dart';

/// 트리 노드 - Todo와 자식들을 포함
class TodoTreeNode {
  final TodoRead todo;
  final int depth;
  final List<TodoTreeNode> children;
  final List<String> pathIds;

  const TodoTreeNode({
    required this.todo,
    required this.depth,
    required this.children,
    required this.pathIds,
  });

  String get id => todo.id;
  String? get parentId => todo.parentId;
  bool get hasChildren => children.isNotEmpty;

  /// 노드의 복사본 생성 (자식 변경 시 사용)
  TodoTreeNode copyWith({
    TodoRead? todo,
    int? depth,
    List<TodoTreeNode>? children,
    List<String>? pathIds,
  }) {
    return TodoTreeNode(
      todo: todo ?? this.todo,
      depth: depth ?? this.depth,
      children: children ?? this.children,
      pathIds: pathIds ?? this.pathIds,
    );
  }
}

/// 전체 트리 구조
class TodoTree {
  /// 루트 레벨 노드들
  final List<TodoTreeNode> roots;

  /// ID로 노드 접근용 맵
  final Map<String, TodoTreeNode> nodeMap;

  /// 평면 순서 (DFS 순회 순서)
  final List<String> flatOrder;

  const TodoTree({
    required this.roots,
    required this.nodeMap,
    required this.flatOrder,
  });

  /// 빈 트리
  static const empty = TodoTree(
    roots: [],
    nodeMap: {},
    flatOrder: [],
  );

  /// 노드 조회
  TodoTreeNode? getNode(String id) => nodeMap[id];

  /// 총 노드 수
  int get totalCount => nodeMap.length;
}

/// 평면 목록을 트리 구조로 변환
TodoTree buildTodoTree(List<TodoRead> todos) {
  if (todos.isEmpty) {
    return TodoTree.empty;
  }

  // 1. ID -> Todo 맵 생성
  final Map<String, TodoRead> todoById = {};
  for (final todo in todos) {
    todoById[todo.id] = todo;
  }

  // 2. 부모 ID -> 자식 Todo 목록 생성
  final Map<String, List<TodoRead>> childrenByParentId = {};
  final List<TodoRead> roots = [];

  for (final todo in todos) {
    final parentId = todo.parentId;
    if (parentId == null || !todoById.containsKey(parentId)) {
      // 부모가 없거나 부모가 목록에 없으면 루트
      roots.add(todo);
    } else {
      childrenByParentId.putIfAbsent(parentId, () => []);
      childrenByParentId[parentId]!.add(todo);
    }
  }

  // 3. 노드 맵과 평면 순서 리스트 생성
  final Map<String, TodoTreeNode> nodeMap = {};
  final List<String> flatOrder = [];

  // 4. 재귀적으로 노드 생성
  TodoTreeNode buildNode(TodoRead todo, int depth, List<String> parentPath) {
    final currentPath = [...parentPath, todo.id];
    final childTodos = childrenByParentId[todo.id] ?? [];

    // 자식들을 재귀적으로 빌드
    final children = <TodoTreeNode>[];
    for (final childTodo in childTodos) {
      children.add(buildNode(childTodo, depth + 1, currentPath));
    }

    // 노드 생성
    final node = TodoTreeNode(
      todo: todo,
      depth: depth,
      children: children,
      pathIds: currentPath,
    );

    // 맵에 추가
    nodeMap[todo.id] = node;
    flatOrder.add(todo.id);

    return node;
  }

  // 5. 루트부터 시작해서 트리 생성
  final rootNodes = <TodoTreeNode>[];
  for (final rootTodo in roots) {
    rootNodes.add(buildNode(rootTodo, 0, []));
  }

  return TodoTree(
    roots: rootNodes,
    nodeMap: nodeMap,
    flatOrder: flatOrder,
  );
}

/// 노드가 다른 노드의 자손인지 확인
bool isDescendantOf(TodoTree tree, String nodeId, String potentialAncestorId) {
  final node = tree.getNode(nodeId);
  if (node == null) return false;

  return node.pathIds.contains(potentialAncestorId) && nodeId != potentialAncestorId;
}

/// 노드가 다른 노드의 조상인지 확인
bool isAncestorOf(TodoTree tree, String nodeId, String potentialDescendantId) {
  return isDescendantOf(tree, potentialDescendantId, nodeId);
}

/// 드롭이 유효한지 확인 (순환 방지)
bool canDropOn(TodoTree tree, String draggedId, String targetId) {
  // 자기 자신 위에는 드롭 불가
  if (draggedId == targetId) return false;

  // 자신의 자손 위에는 드롭 불가 (순환 발생)
  if (isAncestorOf(tree, draggedId, targetId)) return false;

  return true;
}
