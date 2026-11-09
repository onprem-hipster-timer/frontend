import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/providers/retry_policy.dart';
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
        retry: appRetry,
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

  /// [label] 칸이 읽히는 수
  String countOf(WidgetTester tester, String label) =>
      tester.getSemantics(find.text(label)).label.split('\n').first;

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

  testWidgets('불러오지 못하면 다시 받지 않고 바로 오류를 보인다', (tester) async {
    todos.readError = Exception('끊김');
    await pumpSection(tester);

    expect(todos.readGroupIds, hasLength(1));
    expect(find.text('통계 데이터를 불러올 수 없습니다'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('불러오지 못한 뒤 다시 시도하면 통계를 그린다', (tester) async {
    todos.readError = Exception('끊김');
    await pumpSection(tester);

    todos.readError = null;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('전체 진행률 (1개 완료 / 5개 전체)'), findsOneWidget);
  });

  testWidgets('네트워크가 잠깐 끊겼다 돌아오면 오류 없이 통계를 그린다', (tester) async {
    todos
      ..readError = DioException(
        requestOptions: RequestOptions(path: '/v1/todos'),
        type: DioExceptionType.connectionError,
      )
      ..readFailures = 2;
    await pumpSection(tester);
    await tester.pump(appRetryWindow);
    await tester.pumpAndSettle();

    expect(find.text('통계 데이터를 불러올 수 없습니다'), findsNothing);
    expect(find.text('전체 진행률 (1개 완료 / 5개 전체)'), findsOneWidget);
    expect(todos.readGroupIds, hasLength(3));
  });
}
