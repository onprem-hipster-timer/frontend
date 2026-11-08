import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/widgets/start_timer_dialog.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/timer_fixtures.dart';

/// 새 작업 시작 다이얼로그의 경계. 기본 동작은 start_timer_dialog_test.dart
void main() {
  TodoRead todo(
    String id,
    String title, {
    TodoStatus status = TodoStatus.unscheduled,
    bool shared = false,
  }) =>
      makeTodo(id: id).copyWith(title: title, status: status, isShared: shared);

  final report = todo('todo-1', '보고서 쓰기');
  final meeting = todo('todo-2', '회의 준비');

  late StartTimerInput? result;
  late bool closed;

  /// 버튼으로 다이얼로그를 연다. 닫히면 [closed]가 true, 돌려준 값은 [result]
  Future<void> open(
    WidgetTester tester, {
    Future<List<TodoRead>> Function()? todos,
    TodoRead? initialTodo,
    Duration initialDuration = const Duration(minutes: 25),
  }) async {
    result = null;
    closed = false;
    final load = todos ?? () async => [report, meeting];
    await tester.pumpWidget(
      pumpApp(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await showStartTimerDialog(
                    context,
                    initialDuration: initialDuration,
                    initialTodo: initialTodo,
                  );
                  closed = true;
                },
                child: const Text('열기'),
              ),
            ),
          ),
        ),
        overrides: [allTodosProvider.overrideWith((ref) => load())],
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  Finder todoField() => find.widgetWithText(InputDecorator, '할 일 연결 (선택)');
  Finder titleField() => find.widgetWithText(TextField, '작업명');
  Finder searchField() => find.widgetWithIcon(TextField, Icons.search);
  Finder pickerItem(String label) => find.widgetWithText(ListTile, label);

  String titleText(WidgetTester tester) =>
      tester.widget<TextField>(titleField()).controller!.text;

  Finder fieldShows(String text) =>
      find.descendant(of: todoField(), matching: find.text(text));

  bool fieldEnabled(WidgetTester tester) =>
      tester.widget<InputDecorator>(todoField()).decoration.enabled;

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(todoField());
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String label) async {
    await openPicker(tester);
    await tester.tap(pickerItem(label));
    await tester.pumpAndSettle();
  }

  Future<void> closePicker(WidgetTester tester) async {
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
  }

  Future<void> start(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, '시작'));
    await tester.pumpAndSettle();
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(AlertDialog)));

  group('작업명 채우기', () {
    testWidgets('할 일 제목으로 채운 작업명을 지운 뒤 다른 할 일을 고르면 그 제목으로 채운다', (tester) async {
      await open(tester);
      await choose(tester, '보고서 쓰기');

      await tester.enterText(titleField(), '');
      await choose(tester, '회의 준비');

      expect(titleText(tester), '회의 준비');
    });

    testWidgets('처음 연결한 할 일로 채운 작업명은 다른 할 일을 고르면 그 제목으로 바뀐다', (tester) async {
      await open(tester, initialTodo: report);

      await choose(tester, '회의 준비');

      expect(titleText(tester), '회의 준비');
      await start(tester);
      expect(result?.todo, meeting);
      expect(result?.title, '회의 준비');
    });

    testWidgets('처음 연결한 할 일로 채운 작업명을 고치면 다른 할 일을 골라도 그대로다', (tester) async {
      await open(tester, initialTodo: report);
      await tester.enterText(titleField(), '보고서 초안');

      await choose(tester, '회의 준비');

      expect(titleText(tester), '보고서 초안');
      await start(tester);
      expect(result?.todo, meeting);
      expect(result?.title, '보고서 초안');
    });

    testWidgets("'연결 안 함'을 거쳐도 할 일 제목으로 채운 작업명은 다음에 고른 할 일 제목으로 바뀐다", (
      tester,
    ) async {
      await open(tester);
      await choose(tester, '보고서 쓰기');
      await choose(tester, '연결 안 함');
      expect(titleText(tester), '보고서 쓰기');

      await choose(tester, '회의 준비');

      expect(titleText(tester), '회의 준비');
      await start(tester);
      expect(result?.todo, meeting);
      expect(result?.title, '회의 준비');
    });

    testWidgets('같은 할 일을 다시 골라도 고친 작업명은 그대로다', (tester) async {
      await open(tester);
      await choose(tester, '보고서 쓰기');
      await tester.enterText(titleField(), '보고서 1장');

      await choose(tester, '보고서 쓰기');

      expect(titleText(tester), '보고서 1장');
    });

    testWidgets('작업명 앞뒤 공백은 지우고 시작한다', (tester) async {
      await open(tester);
      await choose(tester, '보고서 쓰기');
      await tester.enterText(titleField(), '  집중  ');

      await start(tester);

      expect(result?.title, '집중');
      expect(result?.todo, report);
    });

    testWidgets('할 일을 읽는 동안에도 처음 연결할 할 일 제목으로 작업명을 채우고, 읽은 뒤 고친 작업명을 덮지 않는다', (
      tester,
    ) async {
      final loading = Completer<List<TodoRead>>();
      await open(tester, todos: () => loading.future, initialTodo: report);
      expect(titleText(tester), '보고서 쓰기');

      await tester.enterText(titleField(), '보고서 초안');
      loading.complete([report, meeting]);
      await tester.pumpAndSettle();

      expect(titleText(tester), '보고서 초안');
      await start(tester);
      expect(result?.title, '보고서 초안');
      expect(result?.todo, report);
    });
  });

  group('할 일 목록', () {
    testWidgets('제목이 같은 할 일이 둘이면 누른 쪽을 연결한다', (tester) async {
      final first = todo('todo-a', '회의');
      final second = todo('todo-b', '회의');
      await open(tester, todos: () async => [first, second]);
      await openPicker(tester);
      expect(pickerItem('회의'), findsNWidgets(2));

      await tester.tap(pickerItem('회의').last);
      await tester.pumpAndSettle();
      await start(tester);

      expect(result?.todo?.id, 'todo-b');
    });

    testWidgets('영문 제목은 대소문자를 가리지 않고 찾는다', (tester) async {
      await open(
        tester,
        todos: () async => [
          todo('todo-a', 'Weekly Report'),
          todo('todo-b', 'Meeting'),
        ],
      );
      await openPicker(tester);

      await tester.enterText(searchField(), 'report');
      await tester.pump();

      expect(pickerItem('Weekly Report'), findsOneWidget);
      expect(pickerItem('Meeting'), findsNothing);
    });

    testWidgets("맞는 할 일이 없으면 '연결 안 함'만 남고 그것을 고를 수 있다", (tester) async {
      await open(tester, initialTodo: report);
      await openPicker(tester);

      await tester.enterText(searchField(), '없는 할 일');
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(pickerItem('보고서 쓰기'), findsNothing);
      expect(pickerItem('회의 준비'), findsNothing);

      await tester.tap(pickerItem('연결 안 함'));
      await tester.pumpAndSettle();
      expect(fieldShows('연결 안 함'), findsOneWidget);
      await start(tester);
      expect(result?.todo, isNull);
    });

    testWidgets('검색한 채 닫았다 다시 열면 모든 할 일을 보인다', (tester) async {
      await open(tester);
      await openPicker(tester);
      await tester.enterText(searchField(), '회의');
      await tester.pump();
      await closePicker(tester);

      await openPicker(tester);

      expect(pickerItem('보고서 쓰기'), findsOneWidget);
      expect(pickerItem('회의 준비'), findsOneWidget);
    });

    testWidgets("고를 수 있는 할 일이 없으면 '연결 안 함'만 보인다", (tester) async {
      await open(
        tester,
        todos: () async => [
          todo('todo-3', '끝낸 일', status: TodoStatus.done),
          todo('todo-5', '공유받은 일', shared: true),
        ],
      );

      await openPicker(tester);

      expect(tester.takeException(), isNull);
      expect(pickerItem('연결 안 함'), findsOneWidget);
      expect(pickerItem('끝낸 일'), findsNothing);
      expect(pickerItem('공유받은 일'), findsNothing);
    });

    testWidgets('처음 연결할 할 일이 목록의 값과 조금 달라도 같은 할 일 하나로 보고 그대로 연결한다', (
      tester,
    ) async {
      final stale = report.copyWith(description: '예전 설명');
      await open(tester, initialTodo: stale);
      expect(fieldShows('보고서 쓰기'), findsOneWidget);

      await openPicker(tester);
      expect(pickerItem('보고서 쓰기'), findsOneWidget);
      await closePicker(tester);
      await start(tester);

      expect(result?.todo?.id, 'todo-1');
    });

    testWidgets('할 일을 읽지 못해도 처음 연결할 할 일로 시작한다', (tester) async {
      await open(
        tester,
        todos: () async => throw StateError('읽기 실패'),
        initialTodo: report,
      );

      expect(fieldEnabled(tester), isFalse);
      expect(find.text('할 일을 불러오지 못했습니다'), findsOneWidget);
      expect(fieldShows('보고서 쓰기'), findsOneWidget);
      expect(titleText(tester), '보고서 쓰기');

      await start(tester);

      expect(result?.todo, report);
      expect(result?.title, '보고서 쓰기');
    });

    testWidgets('할 일 목록을 다시 읽어도 고른 할 일과 작업명이 남는다', (tester) async {
      final reload = Completer<List<TodoRead>>();
      var loads = 0;
      await open(
        tester,
        todos: () =>
            loads++ == 0 ? Future.value([report, meeting]) : reload.future,
      );
      await choose(tester, '회의 준비');

      container(tester).invalidate(allTodosProvider);
      await tester.pump();
      expect(fieldShows('회의 준비'), findsOneWidget);
      expect(titleText(tester), '회의 준비');

      reload.complete([report, meeting]);
      await tester.pumpAndSettle();
      expect(fieldShows('회의 준비'), findsOneWidget);
      await start(tester);

      expect(result?.todo, meeting);
      expect(result?.title, '회의 준비');
    });

    testWidgets('할 일 목록을 다시 읽다 실패해도 고른 할 일로 시작한다', (tester) async {
      var loads = 0;
      await open(
        tester,
        todos: () async {
          if (loads++ == 0) return [report, meeting];
          throw StateError('다시 읽기 실패');
        },
      );
      await choose(tester, '회의 준비');

      container(tester).invalidate(allTodosProvider);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(fieldShows('회의 준비'), findsOneWidget);
      await start(tester);
      expect(result?.todo, meeting);
    });
  });

  group('화면 크기', () {
    final many = [
      report,
      todo('todo-long', '아주 긴 할 일 제목이 들어가도 새 작업 시작 다이얼로그와 할 일 목록이 넘치지 않아야 한다'),
      for (var i = 0; i < 20; i++) todo('todo-$i-more', '할 일 $i'),
    ];

    for (final (size, keyboard) in const [
      (Size(360, 800), 0.0),
      (Size(360, 560), 0.0),
      (Size(844, 390), 0.0),
      (Size(800, 1280), 0.0),
      (Size(1280, 800), 0.0),
      (Size(360, 560), 250.0),
      (Size(844, 390), 180.0),
    ]) {
      final label =
          '${size.width.toInt()}x${size.height.toInt()}'
          '${keyboard > 0 ? ' 키보드 ${keyboard.toInt()}' : ''}';

      // 키보드가 올라온 가로 화면은 목록 칸이 한 줄 남짓이라 찾은 할 일까지 목록을 굴려 고른다
      testWidgets('$label 화면에서 할 일을 찾아 골라 시작해도 넘치지 않는다', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
        addTearDown(tester.view.reset);

        await open(tester, todos: () async => many);
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(todoField());
        await tester.pumpAndSettle();
        await openPicker(tester);
        expect(tester.takeException(), isNull);
        expect(searchField(), findsOneWidget);

        await tester.enterText(searchField(), '할 일 19');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(pickerItem('할 일 19'));
        await tester.pumpAndSettle();
        await tester.tap(pickerItem('할 일 19'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(titleText(tester), '할 일 19');
        await tester.ensureVisible(find.widgetWithText(FilledButton, '시작'));
        await tester.pumpAndSettle();
        await start(tester);

        expect(closed, isTrue);
        expect(result?.todo?.id, 'todo-19-more');
      });
    }
  });
}
