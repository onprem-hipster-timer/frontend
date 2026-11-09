import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/pages/todo_picker_page.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/sheet_host.dart';

void main() {
  late FakeTodosClient todos;
  late List<List<TodoRead>?> results;

  TodoRead todo(
    String id,
    String title, {
    String group = 'group-work',
    String? parentId,
    TodoStatus status = TodoStatus.unscheduled,
  }) => TodoRead(
    id: id,
    title: title,
    tagGroupId: group,
    parentId: parentId,
    status: status,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    results = [];
    todos = FakeTodosClient([
      todo('a', '보고서'),
      todo('b', '자료 조사', parentId: 'a'),
      todo('c', '끝난 일', status: TodoStatus.done),
      todo('d', '영단어', group: 'group-study'),
      todo('e', '어디에도 없는 그룹 일', group: 'group-gone'),
    ]);
  });

  Future<void> open(
    WidgetTester tester, {
    List<TodoRead> selected = const [],
  }) => pumpSheetHost(
    tester,
    overrides: [
      todosApiProvider.overrideWithValue(todos),
      tagsApiProvider.overrideWithValue(
        FakeTagsClient([
          makeTagGroup(id: 'group-work', name: '업무'),
          makeTagGroup(id: 'group-study', name: '학습'),
        ]),
      ),
    ],
    open: (context) async => results.add(
      await showTodoPicker(
        context,
        selectable: (todo) => todo.status != TodoStatus.done,
        selected: selected,
      ),
    ),
  );

  Finder checkbox(String title) => find.byWidgetPredicate(
    (widget) => widget is Checkbox && widget.semanticLabel == '$title 고르기',
  );

  testWidgets('고를 수 있는 할 일을 그룹 순서대로 트리로 보이고, 목록에 없는 그룹은 기타로 묶는다', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('할 일 고르기'), findsOneWidget);
    expect(find.text('끝난 일'), findsNothing);
    final work = tester.getTopLeft(find.text('업무')).dy;
    final study = tester.getTopLeft(find.text('학습')).dy;
    final other = tester.getTopLeft(find.text('기타')).dy;
    expect(work < study && study < other, isTrue);
    expect(tester.getTopLeft(find.text('보고서')).dy, greaterThan(work));
    expect(
      tester.getTopLeft(find.text('자료 조사')).dx,
      greaterThan(tester.getTopLeft(find.text('보고서')).dx),
    );
    expect(find.text('어디에도 없는 그룹 일'), findsOneWidget);
  });

  testWidgets('한 줄을 누르면 그 할 일 하나를 돌려주며 닫는다', (tester) async {
    await open(tester);
    await tapVisible(tester, find.text('영단어'));

    expect(find.text('할 일 고르기'), findsNothing);
    expect(results.single!.map((t) => t.id), ['d']);
  });

  testWidgets('연결 안 함은 빈 목록을, 뒤로 가기는 null을 돌려준다', (tester) async {
    await open(tester);
    await tapVisible(tester, find.text('연결 안 함'));
    expect(results.single, isEmpty);

    await tapVisible(tester, find.text('열기'));
    await tapVisible(tester, find.byType(CloseButton));
    expect(results.last, isNull);
  });

  testWidgets('둘 이상 체크하면 선택 완료로 체크한 차례대로 돌려준다', (tester) async {
    await open(tester);

    await tapVisible(tester, checkbox('영단어'));
    expect(find.textContaining('선택 완료'), findsNothing);
    await tapVisible(tester, checkbox('보고서'));
    await tapVisible(tester, find.text('2개 선택 완료'));

    expect(results.single!.map((t) => t.id), ['d', 'a']);
  });

  testWidgets('넘겨받은 할 일을 체크한 채 열고, 체크를 풀 수 있다', (tester) async {
    await open(tester, selected: [todo('a', '보고서'), todo('d', '영단어')]);

    expect(tester.widget<Checkbox>(checkbox('보고서')).value, isTrue);
    expect(find.text('2개 선택 완료'), findsOneWidget);
    await tapVisible(tester, checkbox('보고서'));
    expect(find.textContaining('선택 완료'), findsNothing);
  });

  testWidgets('제목으로 찾으면 맞는 할 일과 그 상위만 남기고 빈 그룹은 숨긴다', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), '자료');
    await tester.pumpAndSettle();

    expect(find.text('자료 조사'), findsOneWidget);
    expect(find.text('보고서'), findsOneWidget);
    expect(find.text('영단어'), findsNothing);
    expect(find.text('학습'), findsNothing);
  });

  testWidgets('할 일을 불러오지 못하면 오류와 다시 시도를 보인다', (tester) async {
    todos.readError = Exception('끊김');
    await open(tester);

    expect(find.text('할 일을 불러오지 못했습니다'), findsOneWidget);
    todos.readError = null;
    await tapVisible(tester, find.text('다시 시도'));
    expect(find.text('보고서'), findsOneWidget);
  });
}
