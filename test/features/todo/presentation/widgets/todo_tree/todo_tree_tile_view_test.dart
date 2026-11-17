import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_tree_tile_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

void main() {
  TodoRead todo({TodoStatus status = TodoStatus.unscheduled}) => TodoRead(
    id: 'todo-1',
    title: '보고서',
    description: '초안',
    todoGroupId: 'group-1',
    status: status,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  Future<void> pump(WidgetTester tester, Widget view) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: SizedBox(width: 400, child: view)),
    ),
  );

  testWidgets('제목·설명과 상태 아이콘을 보이고 깊이만큼 들여 쓴다', (tester) async {
    await pump(tester, TodoTreeTileView(todo: todo(), depth: 2));

    expect(find.text('보고서'), findsOneWidget);
    expect(find.text('초안'), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
    // 앞쪽 빈칸 24 + 깊이 2 × 24
    expect(tester.getTopLeft(find.byIcon(Icons.circle_outlined)).dx, 72);
  });

  testWidgets('완료한 할 일은 제목에 취소선을 긋는다', (tester) async {
    await pump(tester, TodoTreeTileView(todo: todo(status: TodoStatus.done)));

    expect(
      tester.widget<Text>(find.text('보고서')).style?.decoration,
      TextDecoration.lineThrough,
    );
  });

  testWidgets('앞·상태·아래 줄·뒤 자리에 받은 위젯을 두고 누르면 onTap을 부른다', (tester) async {
    var taps = 0;
    await pump(
      tester,
      TodoTreeTileView(
        todo: todo(),
        leading: const Icon(Icons.chevron_right),
        status: const Text('상태'),
        meta: const [Text('25:00')],
        trailing: const Text('버튼'),
        onTap: () => taps++,
      ),
    );

    for (final text in ['상태', '25:00', '버튼']) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsNothing);
    await tester.tap(find.text('보고서'));
    expect(taps, 1);
  });
}
