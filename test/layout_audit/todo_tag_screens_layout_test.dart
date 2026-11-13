@Tags(['layout_audit'])
library;

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart' show Tags;
import 'package:layout_audit/layout_audit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/tag/presentation/pages/tag_management_page.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_form_sheet.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_group_form_sheet.dart';
import 'package:momeet/features/todo/presentation/pages/todo_dashboard_page.dart';
import 'package:momeet/features/todo/presentation/pages/todo_group_detail_page.dart';
import 'package:momeet/features/todo/presentation/pages/todo_picker_page.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form/todo_group_field.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form_sheet.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_group_form_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../helpers/fake_rest_clients.dart';
import '../helpers/layout_audit_app.dart';
import '../helpers/schedule_fixtures.dart';

/// 할 일·태그 화면과 폼 시트를 화면 크기 × 글자 배율 × 긴 문구로 점검한다.
///
/// 사용자가 넣는 글자(할 일 제목·설명, 그룹·태그 이름)에 [StressText]를 넣는다.
void main() {
  TodoRead todo(String id, String title, {String? parentId}) => TodoRead(
    id: id,
    title: title,
    description: title,
    todoGroupId: 'group-work',
    parentId: parentId,
    status: TodoStatus.unscheduled,
    createdAt: DateTime.utc(2026, 1, 1),
    tags: [makeTag(id: 'tag-1', name: title, groupId: 'group-work')],
  );

  TagGroupReadWithTags group(String id, String name) => makeTagGroup(
    id: id,
    name: name,
    description: name,
    tags: [
      makeTag(id: '$id-tag-1', name: name, groupId: id),
      makeTag(id: '$id-tag-2', name: '짧은 태그', groupId: id),
    ],
  );

  List<Override> overrides(String text) => [
    todosApiProvider.overrideWithValue(
      FakeTodosClient(
        [
          todo('todo-1', text),
          todo('todo-2', text, parentId: 'todo-1'),
          todo('todo-3', '짧은 할 일'),
        ],
        [
          makeTodoGroup(id: 'group-work', name: text, description: text),
          makeTodoGroup(id: 'group-study', name: '학습'),
        ],
      ),
    ),
    tagsApiProvider.overrideWithValue(
      FakeTagsClient([group('group-work', text), group('group-study', '학습')]),
    ),
    activeTimersProvider.overrideWith((ref) async => const []),
    todoTimerAggregationsProvider.overrideWith((ref) async => const {}),
  ];

  Widget app(StressText text, Widget child) =>
      wrapWithApp(overrides: overrides(text.value))(child);

  testLayoutAudit(
    'todo_dashboard_page',
    subject: '그룹 이름',
    build: (text) => app(text, const TodoDashboardPage()),
  );

  testLayoutAudit(
    'todo_group_detail_page',
    subject: '그룹·할 일 제목',
    build: (text) =>
        app(text, const TodoGroupDetailPage(groupId: 'group-work')),
  );

  testLayoutAudit(
    'todo_picker_page',
    subject: '그룹·할 일 제목',
    build: (text) => app(text, TodoPickerPage(selectable: (_) => true)),
  );

  testLayoutAudit(
    'tag_management_page',
    subject: '그룹·태그 이름',
    build: (text) => app(text, const TagManagementPage()),
  );

  testLayoutAudit(
    'todo_form_sheet',
    subject: '할 일 제목·태그',
    build: (text) => app(
      text,
      SingleChildScrollView(
        child: TodoFormSheet(todo: todo('todo-1', text.value)),
      ),
    ),
  );

  testLayoutAudit(
    'todo_form_sheet_new',
    subject: '할 일 그룹·태그 이름',
    build: (text) => app(
      text,
      const SingleChildScrollView(
        child: TodoFormSheet(defaultTodoGroupId: 'group-work'),
      ),
    ),
  );

  testLayoutAudit(
    'todo_group_picker',
    subject: '할 일 그룹 이름',
    build: (text) => app(
      text,
      OpenOnStart(
        open: (context) => showTodoGroupPicker(
          context,
          groups: [
            defaultTodoGroup,
            makeTodoGroup(id: 'group-work', name: text.value),
            makeTodoGroup(id: 'group-study', name: '학습'),
          ],
          selectedId: 'group-work',
        ),
      ),
    ),
  );

  testLayoutAudit(
    'tag_form_sheet',
    subject: '태그·그룹 이름',
    build: (text) => app(
      text,
      SingleChildScrollView(
        child: TagFormSheet(
          tag: makeTag(id: 'group-work-tag-1', name: text.value),
        ),
      ),
    ),
  );

  testLayoutAudit(
    'todo_group_form_sheet_new',
    subject: '빈 칸 안내',
    build: (text) =>
        app(text, const SingleChildScrollView(child: TodoGroupFormSheet())),
  );

  testLayoutAudit(
    'todo_group_form_sheet',
    subject: '그룹 이름·설명',
    build: (text) => app(
      text,
      SingleChildScrollView(
        child: TodoGroupFormSheet(
          group: makeTodoGroup(
            id: 'group-work',
            name: text.value,
            description: text.value,
          ),
        ),
      ),
    ),
  );

  testLayoutAudit(
    'tag_group_form_sheet',
    subject: '그룹 이름·설명',
    build: (text) => app(
      text,
      SingleChildScrollView(
        child: TagGroupFormSheet(tagGroup: group('group-work', text.value)),
      ),
    ),
  );
}
