import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_group_form_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/sheet_host.dart';

void main() {
  late FakeTodosClient todos;
  final work = makeTodoGroup(
    id: 'group-work',
    name: '업무',
    color: '#B3D4FF',
    description: '회사 일',
  );

  setUp(() {
    todos = FakeTodosClient(const [], [work]);
  });

  Future<void> open(WidgetTester tester, {TodoGroupRead? group}) =>
      pumpSheetHost(
        tester,
        overrides: [todosApiProvider.overrideWithValue(todos)],
        open: (context) => showTodoGroupFormSheet(context, group: group),
      );

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Finder swatch(int argb) => find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).color?.toARGB32() == argb,
  );

  group('새 할 일 그룹', () {
    testWidgets('이름이 비면 오류를 보이고 보내지 않는다', (tester) async {
      await open(tester);
      expect(find.text('새 해야 할 일 목록 만들기'), findsOneWidget);

      await tapVisible(tester, find.text('생성'));

      expect(find.text('해야 할 일 목록 이름을 입력해주세요'), findsOneWidget);
      expect(todos.createdGroups, isEmpty);
    });

    testWidgets('이름·설명·색을 다듬어 보내고 닫는다', (tester) async {
      await open(tester);
      await tester.enterText(field('해야 할 일 목록 이름'), '  운동  ');
      await tester.enterText(field('설명 (선택사항)'), '  주 3회  ');
      await tapVisible(tester, swatch(0xFFCCB3FF));
      await tapVisible(tester, find.text('생성'));

      final body = todos.createdGroups.single;
      expect(body.name, '운동');
      expect(body.description, '주 3회');
      expect(body.color, '#CCB3FF');
      expect(find.text('새 해야 할 일 목록 만들기'), findsNothing);
      expect(find.text('해야 할 일 목록이 생성되었습니다'), findsOneWidget);
    });

    testWidgets('설명이 비면 null, 색은 기본 색으로 보낸다', (tester) async {
      await open(tester);
      await tester.enterText(field('해야 할 일 목록 이름'), '운동');
      await tapVisible(tester, find.text('생성'));

      final body = todos.createdGroups.single;
      expect(body.description, isNull);
      expect(body.color, '#FFB3B3');
    });

    testWidgets('보내기에 실패하면 시트를 두고 오류를 알린다', (tester) async {
      todos.writeError = Exception('서버 오류');
      await open(tester);
      await tester.enterText(field('해야 할 일 목록 이름'), '운동');
      await tapVisible(tester, find.text('생성'));

      expect(find.text('새 해야 할 일 목록 만들기'), findsOneWidget);
      expect(find.textContaining('해야 할 일 목록 생성에 실패했습니다'), findsOneWidget);
    });
  });

  group('할 일 그룹 수정', () {
    testWidgets('기존 값을 채우고 바꾼 값을 보낸다', (tester) async {
      await open(tester, group: work);

      expect(find.text('해야 할 일 목록 수정'), findsOneWidget);
      expect(find.text('회사 일'), findsOneWidget);

      await tester.enterText(field('업무'), '업무 2');
      await tapVisible(tester, find.text('수정'));

      final (id, body, options) = todos.updatedGroups.single;
      expect(id, 'group-work');
      expect(body.name, '업무 2');
      expect(body.description, '회사 일');
      expect(body.color, '#B3D4FF');
      expect(explicitNullFields(options), isEmpty);
      expect(find.text('해야 할 일 목록 수정'), findsNothing);
      expect(find.text('해야 할 일 목록이 수정되었습니다'), findsOneWidget);
    });

    testWidgets('기본 그룹도 이름을 바꿀 수 있다', (tester) async {
      await open(tester, group: defaultTodoGroup);
      await tester.enterText(field('기본'), '받은 일');
      await tapVisible(tester, find.text('수정'));

      final (id, body, _) = todos.updatedGroups.single;
      expect(id, defaultTodoGroupId);
      expect(body.name, '받은 일');
    });

    testWidgets('설명을 비우면 description을 null로 보내라고 표시한다', (tester) async {
      await open(tester, group: work);
      await tester.enterText(field('회사 일'), '');
      await tapVisible(tester, find.text('수정'));

      final (_, body, options) = todos.updatedGroups.single;
      expect(body.description, isNull);
      expect(explicitNullFields(options), ['description']);
    });

    testWidgets('수정에 실패하면 시트를 두고 오류를 알린다', (tester) async {
      todos.writeError = Exception('서버 오류');
      await open(tester, group: work);
      await tapVisible(tester, find.text('수정'));

      expect(find.text('해야 할 일 목록 수정'), findsOneWidget);
      expect(find.textContaining('해야 할 일 목록 수정에 실패했습니다'), findsOneWidget);
    });
  });
}
