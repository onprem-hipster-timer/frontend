import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form/todo_group_field.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/schedule_fixtures.dart';
import '../../../../helpers/sheet_host.dart';
import '../../../../helpers/large_text.dart';

void main() {
  late FakeTodosClient todos;
  late FakeTagsClient tags;

  final focus = makeTag(id: 'tag-focus', name: '집중', groupId: 'group-work');
  final study = makeTag(id: 'tag-study', name: '공부', groupId: 'group-study');
  final study2 = makeTag(id: 'tag-read', name: '독서', groupId: 'group-study');

  setUp(() {
    todos = FakeTodosClient(const [], [
      makeTodoGroup(id: 'group-work', name: '업무'),
      makeTodoGroup(id: 'group-study', name: '학습'),
    ]);
    tags = FakeTagsClient([
      makeTagGroup(id: 'group-work', name: '업무', tags: [focus]),
      makeTagGroup(id: 'group-study', name: '학습', tags: [study, study2]),
    ]);
  });

  Future<void> open(
    WidgetTester tester, {
    TodoRead? todo,
    String? defaultParentId,
    String? defaultTodoGroupId,
  }) => pumpSheetHost(
    tester,
    overrides: [
      todosApiProvider.overrideWithValue(todos),
      tagsApiProvider.overrideWithValue(tags),
    ],
    open: (context) => showTodoFormSheet(
      context,
      todo: todo,
      defaultParentId: defaultParentId,
      defaultTodoGroupId: defaultTodoGroupId,
    ),
  );

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  /// 할 일 그룹 칸에 보이는 글자
  Finder groupShown(String text) => find.descendant(
    of: find.byType(TodoGroupField),
    matching: find.text(text),
  );

  group('새 할 일', () {
    testWidgets('좁은 화면에 글자가 커도 설명 칸 이름을 자르지 않는다', (tester) async {
      await open(tester);
      await useLargeTextOnSmallPhone(tester);

      expectWholeText(tester, find.text('설명 (선택사항)'));
    });

    testWidgets('제목이 비면 오류를 보이고 보내지 않는다', (tester) async {
      await open(tester);

      expect(find.text('새 할 일 만들기'), findsOneWidget);
      await tapVisible(tester, find.text('생성'));

      expect(find.text('할 일 제목을 입력해주세요'), findsOneWidget);
      expect(todos.created, isEmpty);
    });

    testWidgets('제목이 200자를 넘으면 오류를 보인다', (tester) async {
      await open(tester);
      await tester.enterText(field('할 일 제목'), 'a' * 201);
      await tapVisible(tester, find.text('생성'));

      expect(find.text('제목은 200자 이하로 입력해주세요'), findsOneWidget);
      expect(todos.created, isEmpty);
    });

    testWidgets('고른 태그·상위와 함께 보낸 뒤 닫는다. 할 일 그룹을 받지 않았으면 그룹을 보내지 않는다', (
      tester,
    ) async {
      await open(tester, defaultParentId: 'parent-1');

      await tester.enterText(field('할 일 제목'), '  보고서 쓰기  ');
      await tester.enterText(field('설명 (선택사항)'), '  초안  ');
      await tapVisible(tester, find.widgetWithText(FilterChip, '공부'));
      expect(find.text('선택된 태그 (1)'), findsOneWidget);
      await tapVisible(tester, find.text('생성'));

      expect(todos.created, hasLength(1));
      final body = todos.created.single;
      expect(body.title, '보고서 쓰기');
      expect(body.description, '초안');
      expect(body.todoGroupId, isNull);
      expect(body.tagIds, ['tag-study']);
      expect(body.parentId, 'parent-1');
      expect(body.status, isNull);
      expect(find.text('새 할 일 만들기'), findsNothing);
      expect(find.text('할 일이 생성되었습니다'), findsOneWidget);
    });

    testWidgets('할 일 그룹을 받으면 그 그룹을 칸에 보이고 그 그룹으로 만든다', (tester) async {
      await open(tester, defaultTodoGroupId: 'group-work');

      expect(groupShown('업무'), findsOneWidget);
      await tester.enterText(field('할 일 제목'), '회의');
      await tapVisible(tester, find.text('생성'));

      expect(todos.created.single.todoGroupId, 'group-work');
    });

    testWidgets('할 일 그룹을 받지 않으면 칸에 기본 그룹을 보인다', (tester) async {
      await open(tester);

      expect(groupShown('기본'), findsOneWidget);
    });

    testWidgets('할 일 그룹을 고르면 지금 그룹에 체크가 있고, 고른 그룹으로 만든다', (tester) async {
      await open(tester, defaultTodoGroupId: 'group-work');
      await tapVisible(tester, find.byType(TodoGroupField));

      expect(find.text('할 일 그룹 고르기'), findsOneWidget);
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, '업무'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      await tapVisible(tester, find.widgetWithText(ListTile, '학습'));
      expect(groupShown('학습'), findsOneWidget);

      await tester.enterText(field('할 일 제목'), '단어 외우기');
      await tapVisible(tester, find.text('생성'));
      expect(todos.created.single.todoGroupId, 'group-study');
    });

    testWidgets('할 일 그룹 고르기를 취소하면 그대로 둔다', (tester) async {
      await open(tester, defaultTodoGroupId: 'group-work');
      await tapVisible(tester, find.byType(TodoGroupField));
      await tapVisible(tester, find.widgetWithText(TextButton, '취소'));

      expect(find.text('할 일 그룹 고르기'), findsNothing);
      expect(groupShown('업무'), findsOneWidget);
      await tester.enterText(field('할 일 제목'), '회의');
      await tapVisible(tester, find.text('생성'));
      expect(todos.created.single.todoGroupId, 'group-work');
    });

    testWidgets('하위 할 일은 할 일 그룹을 바꿀 수 없다', (tester) async {
      await open(
        tester,
        defaultParentId: 'parent-1',
        defaultTodoGroupId: 'group-work',
      );
      await tapVisible(tester, find.byType(TodoGroupField));

      expect(find.text('할 일 그룹 고르기'), findsNothing);
      expect(groupShown('업무'), findsOneWidget);
    });

    testWidgets('할 일 그룹을 불러오지 못하면 칸에 알리고, 할 일은 그래도 만든다', (tester) async {
      todos.groupsReadError = Exception('끊김');
      await open(tester);

      expect(find.text('할 일 그룹을 불러오지 못했습니다'), findsOneWidget);
      await tapVisible(tester, find.byType(TodoGroupField));
      expect(find.text('할 일 그룹 고르기'), findsNothing);

      await tester.enterText(field('할 일 제목'), '정리');
      await tapVisible(tester, find.text('생성'));
      expect(todos.created.single.todoGroupId, isNull);
    });

    testWidgets('완료를 고르면 완료 상태로 보낸다', (tester) async {
      await open(tester);
      await tester.enterText(field('할 일 제목'), '정리');
      await tapVisible(tester, find.widgetWithText(ChoiceChip, '완료'));
      await tapVisible(tester, find.text('생성'));

      expect(todos.created.single.status, TodoStatus.done);
    });

    testWidgets('선택된 태그의 x를 누르면 선택이 풀린다', (tester) async {
      await open(tester);
      await tapVisible(tester, find.widgetWithText(FilterChip, '공부'));
      await tapVisible(tester, find.byIcon(Icons.close));
      expect(find.textContaining('선택된 태그'), findsNothing);

      await tester.enterText(field('할 일 제목'), '정리');
      await tapVisible(tester, find.text('생성'));
      expect(todos.created.single.tagIds, isEmpty);
    });

    testWidgets('여러 태그 그룹의 태그를 함께 붙인다', (tester) async {
      await open(tester);
      await tester.enterText(field('할 일 제목'), '정리');
      await tapVisible(tester, find.widgetWithText(FilterChip, '집중'));
      await tapVisible(tester, find.widgetWithText(FilterChip, '독서'));
      await tapVisible(tester, find.text('생성'));

      expect(
        todos.created.single.tagIds,
        unorderedEquals(['tag-focus', 'tag-read']),
      );
    });

    testWidgets('태그 그룹이 없으면 안내를 보이고, 태그 그룹을 만들지 않고 할 일만 만든다', (tester) async {
      tags.groups.clear();
      await open(tester);

      expect(find.text('아직 태그가 없습니다'), findsOneWidget);
      await tester.enterText(field('할 일 제목'), '첫 할 일');
      await tapVisible(tester, find.text('생성'));

      expect(tags.createdGroups, isEmpty);
      expect(todos.created.single.title, '첫 할 일');
      expect(todos.created.single.tagIds, isEmpty);
    });

    testWidgets('태그 그룹이 없을 때 첫 태그 만들기는 태그 그룹부터 만들고, 그 그룹에 태그를 만들어 이어 고른다', (
      tester,
    ) async {
      tags.groups.clear();
      await open(tester);

      expect(find.textContaining('태그 그룹을 만든 뒤'), findsOneWidget);
      await tapVisible(tester, find.text('첫 태그 만들기'));
      expect(find.text('새 태그 그룹 만들기'), findsOneWidget);
      await tester.enterText(field('태그 그룹 이름'), '생활');
      await tapVisible(tester, find.widgetWithText(FilledButton, '생성').last);

      expect(tags.createdGroups.single.name, '생활');
      expect(find.text('새 태그 만들기'), findsOneWidget);
      await tester.enterText(field('태그 이름'), '운동');
      await tapVisible(tester, find.widgetWithText(FilledButton, '생성').last);

      expect(tags.createdTags.single.groupId, 'group-new-1');
      expect(find.text('새 태그 만들기'), findsNothing);
      expect(find.text('새 할 일 만들기'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, '운동'), findsOneWidget);
    });

    testWidgets('태그 그룹이 없을 때 새 태그에서 태그 그룹 폼을 닫으면 태그 폼을 열지 않는다', (tester) async {
      tags.groups.clear();
      await open(tester);
      await tapVisible(tester, find.text('새 태그'));
      expect(find.text('새 태그 그룹 만들기'), findsOneWidget);
      await tapVisible(tester, find.widgetWithText(OutlinedButton, '취소').last);

      expect(find.text('새 태그 그룹 만들기'), findsNothing);
      expect(find.text('새 태그 만들기'), findsNothing);
      expect(tags.createdGroups, isEmpty);
      expect(find.text('새 할 일 만들기'), findsOneWidget);
    });

    testWidgets('태그 그룹이 있으면 새 태그는 바로 태그 폼을 연다', (tester) async {
      await open(tester);
      await tapVisible(tester, find.text('새 태그'));

      expect(find.text('새 태그 그룹 만들기'), findsNothing);
      expect(find.text('새 태그 만들기'), findsOneWidget);
    });

    testWidgets('보내기에 실패하면 시트를 두고 오류를 알린다', (tester) async {
      todos.writeError = Exception('서버 오류');
      await open(tester);
      await tester.enterText(field('할 일 제목'), '정리');
      await tapVisible(tester, find.text('생성'));

      expect(find.text('새 할 일 만들기'), findsOneWidget);
      expect(find.textContaining('할 일 생성에 실패했습니다'), findsOneWidget);
    });

    testWidgets('취소는 보내지 않고 닫는다', (tester) async {
      await open(tester);
      await tester.enterText(field('할 일 제목'), '정리');
      await tapVisible(tester, find.widgetWithText(OutlinedButton, '취소'));

      expect(find.text('새 할 일 만들기'), findsNothing);
      expect(todos.created, isEmpty);
    });

    testWidgets('태그를 불러오지 못하면 오류를 보인다', (tester) async {
      tags.readError = Exception('끊김');
      await open(tester);

      expect(find.textContaining('태그를 불러오지 못했습니다'), findsOneWidget);
    });
  });

  group('할 일 수정', () {
    TodoRead existing({
      TodoStatus status = TodoStatus.unscheduled,
      DateTime? deadline,
      String? description = '메모',
      String? parentId,
    }) => TodoRead(
      id: 'todo-1',
      title: '보고서',
      description: description,
      todoGroupId: 'group-study',
      parentId: parentId,
      status: status,
      deadline: deadline,
      tags: [study],
      createdAt: DateTime.utc(2026, 1, 1),
    );

    testWidgets('지금 할 일 그룹을 칸에 보이고, 바꾸지 않으면 그룹을 보내지 않는다', (tester) async {
      await open(tester, todo: existing());

      expect(groupShown('학습'), findsOneWidget);
      await tapVisible(tester, find.text('수정'));

      expect(todos.updated.single.$2.todoGroupId, isNull);
    });

    testWidgets('같은 할 일 그룹을 다시 고르면 그룹을 보내지 않는다', (tester) async {
      await open(tester, todo: existing());
      await tapVisible(tester, find.byType(TodoGroupField));
      await tapVisible(tester, find.widgetWithText(ListTile, '학습'));
      await tapVisible(tester, find.text('수정'));

      expect(todos.updated.single.$2.todoGroupId, isNull);
    });

    testWidgets('다른 할 일 그룹을 고르면 그 그룹으로 옮긴다', (tester) async {
      await open(tester, todo: existing());
      await tapVisible(tester, find.byType(TodoGroupField));

      expect(
        find.text('할 일을 옮길 할 일 그룹입니다. 하위 할 일이 있으면 함께 옮겨집니다.'),
        findsOneWidget,
      );
      await tapVisible(tester, find.widgetWithText(ListTile, '업무'));
      expect(groupShown('업무'), findsOneWidget);
      await tapVisible(tester, find.text('수정'));

      expect(todos.updated.single.$2.todoGroupId, 'group-work');
    });

    testWidgets('상위 할 일이 있으면 옮길 때 상위 연결이 풀린다고 알린다', (tester) async {
      await open(tester, todo: existing(parentId: 'todo-parent'));
      await tapVisible(tester, find.byType(TodoGroupField));

      expect(find.textContaining('하위 할 일이 있으면 함께 옮겨집니다.'), findsOneWidget);
      expect(
        find.textContaining('상위 할 일과의 연결은 풀리고, 옮긴 할 일 그룹에서 맨 위 할 일이 됩니다.'),
        findsOneWidget,
      );
    });

    testWidgets('상위 할 일이 없으면 상위 연결을 말하지 않는다', (tester) async {
      await open(tester, todo: existing());
      await tapVisible(tester, find.byType(TodoGroupField));

      expect(find.textContaining('상위'), findsNothing);
    });

    testWidgets('기존 값으로 채우고 바꾼 값을 보낸 뒤 닫는다', (tester) async {
      await open(tester, todo: existing(deadline: DateTime(2026, 11, 20)));

      expect(find.text('할 일 수정'), findsOneWidget);
      expect(find.text('보고서'), findsOneWidget);
      expect(find.text('메모'), findsOneWidget);
      expect(find.text('2026년 11월 20일'), findsOneWidget);
      expect(find.text('선택된 태그 (1)'), findsOneWidget);

      await tester.enterText(field('할 일 제목'), '보고서 2');
      await tapVisible(tester, find.text('수정'));

      final (id, body, options) = todos.updated.single;
      expect(id, 'todo-1');
      expect(body.title, '보고서 2');
      expect(body.description, '메모');
      expect(body.tagIds, ['tag-study']);
      expect(body.deadline, DateTime(2026, 11, 20));
      expect(explicitNullFields(options), isEmpty);
      expect(find.text('할 일 수정'), findsNothing);
      expect(find.text('할 일이 수정되었습니다'), findsOneWidget);
    });

    testWidgets('설명을 비우면 description을 null로 보내라고 표시한다', (tester) async {
      await open(tester, todo: existing());
      await tester.enterText(field('설명 (선택사항)'), '');
      await tapVisible(tester, find.text('수정'));

      final (_, body, options) = todos.updated.single;
      expect(body.description, isNull);
      expect(explicitNullFields(options), ['description']);
    });

    testWidgets('예정된 할 일의 마감일을 지우면 연결 일정 처리를 묻고 고른 정책을 보낸다', (tester) async {
      await open(
        tester,
        todo: existing(
          status: TodoStatus.scheduled,
          deadline: DateTime(2026, 11, 20),
        ),
      );
      await tapVisible(tester, find.byIcon(Icons.clear));
      await tapVisible(tester, find.text('수정'));

      expect(find.text('연결된 일정 처리'), findsOneWidget);
      await tapVisible(tester, find.text('일정은 남기기'));

      final (_, body, options) = todos.updated.single;
      expect(body.linkedSchedulePolicy, LinkedSchedulePolicy.unlink);
      expect(body.deadline, isNull);
      expect(explicitNullFields(options), ['deadline']);
    });

    testWidgets('연결 일정 질문을 닫으면 보내지 않는다', (tester) async {
      await open(
        tester,
        todo: existing(
          status: TodoStatus.scheduled,
          deadline: DateTime(2026, 11, 20),
        ),
      );
      await tapVisible(tester, find.byIcon(Icons.clear));
      await tapVisible(tester, find.text('수정'));
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(todos.updated, isEmpty);
      expect(find.text('할 일 수정'), findsOneWidget);
    });

    testWidgets('미예정 할 일의 마감일을 지우면 묻지 않고 null로 보낸다', (tester) async {
      await open(tester, todo: existing(deadline: DateTime(2026, 11, 20)));
      await tapVisible(tester, find.byIcon(Icons.clear));
      await tapVisible(tester, find.text('수정'));

      expect(find.text('연결된 일정 처리'), findsNothing);
      expect(explicitNullFields(todos.updated.single.$3), ['deadline']);
    });

    testWidgets('수정에 실패하면 시트를 두고 오류를 알린다', (tester) async {
      todos.writeError = Exception('서버 오류');
      await open(tester, todo: existing());
      await tapVisible(tester, find.text('수정'));

      expect(find.text('할 일 수정'), findsOneWidget);
      expect(find.textContaining('할 일 수정에 실패했습니다'), findsOneWidget);
    });
  });
}
