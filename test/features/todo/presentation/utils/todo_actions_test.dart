import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/todo/presentation/utils/todo_actions.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/pump_app.dart';

/// `linked_timer_policy` 없는 삭제는 422 `LinkedTimerPolicyRequiredError`, 있으면 204
class _FakeBackend implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.uri.queryParameters.containsKey('linked_timer_policy')) {
      return ResponseBody.fromString('', 204);
    }
    return ResponseBody.fromString(
      '{"status_code": 422, "error_type": "LinkedTimerPolicyRequiredError"}',
      422,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final todo = TodoRead(
    id: 'todo-1',
    title: '보고서',
    tagGroupId: 'g1',
    status: TodoStatus.unscheduled,
    createdAt: DateTime(2026, 1, 1),
  );
  final node = TodoTreeNode(
    todo: todo,
    depth: 0,
    children: const [],
    pathIds: const ['todo-1'],
  );

  late _FakeBackend backend;

  /// 삭제를 확인하고 연결 타이머 정책 다이얼로그가 뜰 때까지 진행한다.
  Future<void> deleteUntilTimerPolicyAsked(WidgetTester tester) async {
    backend = _FakeBackend();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = backend;
    await tester.pumpWidget(
      pumpApp(
        Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () =>
                  TodoActions.showDeleteTodoDialog(context, ref, todo, node),
              child: const Text('열기'),
            ),
          ),
        ),
        overrides: [todosApiProvider.overrideWithValue(TodosClient(dio))],
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(backend.requests, hasLength(1));
    expect(
      backend.requests.single.uri.queryParameters,
      isNot(contains('linked_timer_policy')),
    );
    expect(find.text('연결된 타이머 처리'), findsOneWidget);
  }

  testWidgets('서버가 연결 타이머 정책을 요구하면 고른 정책으로 다시 삭제한다', (tester) async {
    await deleteUntilTimerPolicyAsked(tester);

    await tester.tap(find.text('연결만 해제'));
    await tester.pumpAndSettle();

    expect(backend.requests, hasLength(2));
    expect(
      backend.requests.last.uri.queryParameters['linked_timer_policy'],
      'unlink',
    );
    expect(find.text('보고서이(가) 삭제되었습니다'), findsOneWidget);
  });

  testWidgets('연결 타이머 정책 다이얼로그를 취소하면 다시 보내지 않는다', (tester) async {
    await deleteUntilTimerPolicyAsked(tester);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(backend.requests, hasLength(1));
    expect(find.text('연결된 타이머 처리'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });
}
