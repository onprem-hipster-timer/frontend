import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/mypage/presentation/widgets/activity_stats_section.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';

void main() {
  late FakeTodosClient todos;

  TodoRead todo(String id, TodoStatus status) => TodoRead(
    id: id,
    title: id,
    tagGroupId: 'group-1',
    status: status,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    todos = FakeTodosClient([
      todo('a', TodoStatus.unscheduled),
      todo('b', TodoStatus.unscheduled),
      todo('c', TodoStatus.scheduled),
      todo('d', TodoStatus.done),
      todo('e', TodoStatus.cancelled),
    ]);
  });

  Future<void> pumpSection(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [todosApiProvider.overrideWithValue(todos)],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ActivityStatsSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 실패한 조회의 자동 재시도가 끝날 때까지(1~2분) 흘린다
  Future<void> exhaustRetries(WidgetTester tester) async {
    await tester.pump(const Duration(minutes: 2));
    await tester.pumpAndSettle();
  }

  /// [label] 칸에 적힌 수
  String countOf(WidgetTester tester, String label) {
    final column = find.ancestor(
      of: find.text(label),
      matching: find.byType(Column),
    );
    return tester
        .widgetList<Text>(
          find.descendant(of: column.first, matching: find.byType(Text)),
        )
        .first
        .data!;
  }

  testWidgets('완료 비율과 상태별 수를 보인다 (취소는 전체에만 센다)', (tester) async {
    await pumpSection(tester);

    expect(find.text('활동 요약'), findsOneWidget);
    expect(find.text('전체 진행률 (1개 완료 / 5개 전체)'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0.2,
    );
    expect(countOf(tester, '전체'), '5');
    expect(countOf(tester, '미지정'), '2');
    expect(countOf(tester, '예정'), '1');
    expect(countOf(tester, '완료'), '1');
  });

  testWidgets('할 일이 없으면 0으로 보인다', (tester) async {
    todos.todos.clear();
    await pumpSection(tester);

    expect(find.text('전체 진행률 (0개 완료 / 0개 전체)'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0,
    );
  });

  testWidgets('불러오지 못하면 오류를 보인다', (tester) async {
    todos.readError = Exception('끊김');
    await pumpSection(tester);
    await exhaustRetries(tester);

    expect(find.text('통계 데이터를 불러올 수 없습니다'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('불러오지 못한 뒤 다시 시도하면 통계를 그린다', (tester) async {
    todos.readError = Exception('끊김');
    await pumpSection(tester);
    await exhaustRetries(tester);

    todos.readError = null;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('전체 진행률 (1개 완료 / 5개 전체)'), findsOneWidget);
  });
}
