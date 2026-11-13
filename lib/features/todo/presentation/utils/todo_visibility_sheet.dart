import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';
import 'package:momeet/features/visibility/data/rest_resource_visibility.dart';
import 'package:momeet/features/visibility/presentation/widgets/visibility_button.dart';
import 'package:momeet/features/visibility/presentation/widgets/visibility_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/providers/api_providers.dart';

/// 내 할 일 [node]의 공유 설정 시트를 연다. 저장하면 할 일 목록을 다시 읽는다
///
/// 공유는 이 할 일에만 걸리므로 마감 일정이나 하위 할 일이 있으면 함께 공유되지 않는다고 알린다.
///
/// 테스트: test/features/todo/presentation/widgets/todo_tree_tile_visibility_test.dart
Future<void> showTodoVisibilitySheet(BuildContext context, TodoTreeNode node) {
  final todo = node.todo;
  final container = ProviderScope.containerOf(context, listen: false);
  final notice = [
    if (todo.deadline != null) '마감 일정은 함께 공유되지 않습니다. 캘린더의 일정에서 따로 공유합니다.',
    if (node.hasChildren) '하위 ${Terms.todo.withJosa('은', '는')} 함께 공유되지 않습니다.',
  ].join(' ');
  return showVisibilitySheet(
    context,
    target: RestResourceVisibility(
      container.read(visibilityApiProvider),
      ResourceType.todo,
      todo.id,
    ),
    levels: resourceVisibilityLevels,
    notice: notice.isEmpty ? null : notice,
    onSaved: (container) async => container.invalidate(todosProvider),
  );
}
