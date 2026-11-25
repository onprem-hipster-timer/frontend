import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/editable_todo_tree_tile_view.dart';
import 'package:momeet/shared/api/rest/export.dart';

void main() {
  testWidgets('수정·삭제 콜백이 없으면 할 일 줄의 두 버튼을 누를 수 없다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditableTodoTreeTileView(
            todo: TodoRead(
              id: 'todo-1',
              title: '단어 외우기',
              todoGroupId: 'group-1',
              status: TodoStatus.scheduled,
              createdAt: DateTime(2026, 11, 25),
            ),
            status: const Icon(Icons.schedule),
            onEdit: null,
            onDelete: null,
            onTap: () {},
            canAccept: (_) => false,
            onAccept: (_) {},
            onDragStarted: () {},
            onDragEnd: () {},
          ),
        ),
      ),
    );

    for (final label in ['수정', '삭제']) {
      final button = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(button.enabled, isFalse, reason: label);
    }
  });
}
