import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree_tile.dart';

import '../../../../helpers/layout_audit_app.dart';
import '../../../../helpers/schedule_fixtures.dart';
import '../../../../helpers/timer_fixtures.dart';

void main() {
  testLayoutAudit(
    'todo_tree_tile',
    subject: '제목·설명·태그',
    within: find.byType(TodoTreeTile),
    build: (text) {
      final tree = buildTodoTree([
        makeTodo(id: 'parent').copyWith(
          title: text.value,
          description: text.value,
          tags: [
            makeTag(id: 'tag-1', name: text.value),
            makeTag(id: 'tag-2', color: '#3366FF'),
            makeTag(id: 'tag-3', color: '#33CC66'),
          ],
        ),
        makeTodo(id: 'child').copyWith(parentId: 'parent'),
      ]);
      return wrapWithApp(
        overrides: [
          todoTimerAggregationsProvider.overrideWith(
            (ref) async => {
              'parent': const TodoTimerAggregation(
                todoId: 'parent',
                totalElapsedSeconds: 5400,
                ownElapsedSeconds: 5400,
                timers: [],
                hasActiveTimer: false,
              ),
            },
          ),
          activeTimersProvider.overrideWith((ref) async => const []),
          serverClockProvider.overrideWithValue(
            ServerClock(deviceNow: () => DateTime.utc(2026, 11, 6, 10, 0, 30)),
          ),
        ],
      )(TodoTreeTile(node: tree.nodeMap['parent']!, tree: tree));
    },
    verify: (tester) {
      expect(find.byType(TodoTreeTile), findsOneWidget);
      expect(find.text('01:30:00'), findsOneWidget);
    },
  );
}
