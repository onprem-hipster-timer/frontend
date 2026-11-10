import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/editable_todo_tree_tile.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../../helpers/layout_audit_app.dart';

const _title = '분기 보고서 초안 검토하고 의견 정리하기';

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final tree = buildTodoTree([
    TodoRead(
      id: 'todo-1',
      title: _title,
      tagGroupId: 'group-1',
      status: TodoStatus.unscheduled,
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  ]);
  await tester.pumpWidget(
    wrapWithApp(
      overrides: [
        activeTimersProvider.overrideWith((ref) async => const []),
        todoTimerAggregationsProvider.overrideWith((ref) async => const {}),
      ],
    )(EditableTodoTreeTile(node: tree.nodeMap['todo-1']!, tree: tree)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('넓은 줄은 수정·삭제를 제목 오른쪽에 둔다', (tester) async {
    await _pump(tester, width: 800);

    final title = tester.getRect(find.text(_title));
    final edit = tester.getRect(find.text('수정'));
    expect(edit.left, greaterThan(title.right));
    expect(edit.top, lessThan(title.bottom));
  });

  testWidgets('버튼을 옆에 두면 제목 칸이 좁아지는 폭은 버튼을 제목 아래로 내린다', (tester) async {
    await _pump(tester, width: 320, textScale: 1.3);

    expect(tester.takeException(), isNull);
    final title = tester.getRect(find.text(_title));
    final edit = tester.getRect(find.text('수정'));
    expect(edit.top, greaterThanOrEqualTo(title.bottom));
    // 제목이 글자 두세 개씩 꺾이지 않을 만큼 넓다
    expect(title.width, greaterThan(140 * 1.3));
  });
}
