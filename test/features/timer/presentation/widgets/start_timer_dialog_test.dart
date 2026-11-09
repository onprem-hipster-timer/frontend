import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/widgets/start_timer_dialog.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/timer_fixtures.dart';

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

  /// 할 일 칸에 [text]가 보이는지
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

  Future<void> start(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, '시작'));
    await tester.pumpAndSettle();
  }

  testWidgets('할 일을 고르면 비어 있는 작업명을 그 제목으로 채운다', (tester) async {
    await open(tester);
    expect(titleText(tester), isEmpty);
    expect(fieldShows('연결 안 함'), findsOneWidget);

    await choose(tester, '보고서 쓰기');

    expect(searchField(), findsNothing);
    expect(titleText(tester), '보고서 쓰기');
    expect(fieldShows('보고서 쓰기'), findsOneWidget);
  });

  testWidgets('할 일 제목으로 채운 작업명은 다른 할 일을 고르면 바뀌고, 고친 작업명은 그대로 둔다', (
    tester,
  ) async {
    await open(tester);

    await choose(tester, '보고서 쓰기');
    await choose(tester, '회의 준비');
    expect(titleText(tester), '회의 준비');

    await tester.enterText(titleField(), '회의 준비 자료');
    await choose(tester, '보고서 쓰기');
    expect(titleText(tester), '회의 준비 자료');
  });

  testWidgets('직접 입력한 작업명은 할 일을 골라도 그대로 두고 그 작업명으로 시작한다', (tester) async {
    await open(tester);
    await tester.enterText(titleField(), '집중');

    await choose(tester, '보고서 쓰기');
    expect(titleText(tester), '집중');

    await start(tester);

    expect(result?.title, '집중');
    expect(result?.todos, [report]);
  });

  testWidgets("'연결 안 함'을 고르면 연결을 풀고 작업명은 그대로 둔다", (tester) async {
    await open(tester, initialTodo: report);

    await choose(tester, '연결 안 함');
    expect(fieldShows('연결 안 함'), findsOneWidget);
    expect(titleText(tester), '보고서 쓰기');

    await start(tester);

    expect(result?.todos, isEmpty);
    expect(result?.title, '보고서 쓰기');
  });

  testWidgets('완료·취소한 할 일과 공유받은 할 일은 목록에 없다', (tester) async {
    await open(
      tester,
      todos: () async => [
        report,
        todo('todo-3', '끝낸 일', status: TodoStatus.done),
        todo('todo-4', '취소한 일', status: TodoStatus.cancelled),
        todo('todo-5', '공유받은 일', shared: true),
        todo('todo-6', '예정된 일', status: TodoStatus.scheduled),
      ],
    );

    await openPicker(tester);

    expect(pickerItem('연결 안 함'), findsOneWidget);
    expect(pickerItem('보고서 쓰기'), findsOneWidget);
    expect(pickerItem('예정된 일'), findsOneWidget);
    expect(pickerItem('끝낸 일'), findsNothing);
    expect(pickerItem('취소한 일'), findsNothing);
    expect(pickerItem('공유받은 일'), findsNothing);
  });

  testWidgets('제목으로 찾아 고른다', (tester) async {
    await open(tester);
    await openPicker(tester);

    await tester.enterText(searchField(), '회의');
    await tester.pump();

    expect(pickerItem('회의 준비'), findsOneWidget);
    expect(pickerItem('보고서 쓰기'), findsNothing);
    expect(pickerItem('연결 안 함'), findsOneWidget);

    await tester.tap(pickerItem('회의 준비'));
    await tester.pumpAndSettle();
    await start(tester);

    expect(result?.todos, [meeting]);
    expect(result?.title, '회의 준비');
  });

  testWidgets('목록을 고르지 않고 닫으면 연결한 할 일을 그대로 둔다', (tester) async {
    await open(tester, initialTodo: report);
    await openPicker(tester);

    await tester.enterText(searchField(), '회의');
    await tester.pump();
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(searchField(), findsNothing);
    expect(fieldShows('보고서 쓰기'), findsOneWidget);

    await start(tester);

    expect(result?.todos, [report]);
  });

  testWidgets('시작하면 고른 할 일과 집중 시간을 돌려준다', (tester) async {
    await open(tester, initialDuration: const Duration(minutes: 45));

    await choose(tester, '회의 준비');
    await tester.tap(find.widgetWithText(ChoiceChip, '15분'));
    await tester.pump();
    await start(tester);

    expect(closed, isTrue);
    expect(result?.todos, [meeting]);
    expect(result?.title, '회의 준비');
    expect(result?.duration, const Duration(minutes: 15));
  });

  testWidgets('작업명을 비우면 고른 할 일의 제목으로 시작한다', (tester) async {
    await open(tester);
    await choose(tester, '보고서 쓰기');

    await tester.enterText(titleField(), '  ');
    await start(tester);

    expect(result?.title, '보고서 쓰기');
    expect(result?.todos, [report]);
  });

  testWidgets('작업명도 할 일도 없으면 새 작업으로 시작한다', (tester) async {
    await open(tester);

    await start(tester);

    expect(result?.title, '새 작업');
    expect(result?.todos, isEmpty);
    expect(result?.duration, const Duration(minutes: 25));
  });

  testWidgets('취소하면 null을 돌려준다', (tester) async {
    await open(tester);
    await choose(tester, '보고서 쓰기');

    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('처음 연결할 할 일을 고른 채 열고 작업명을 그 제목으로 채운다', (tester) async {
    await open(tester, initialTodo: meeting);

    expect(titleText(tester), '회의 준비');
    expect(fieldShows('회의 준비'), findsOneWidget);

    await start(tester);

    expect(result?.todos, [meeting]);
    expect(result?.title, '회의 준비');
  });

  testWidgets('할 일을 읽는 동안 할 일 칸을 막고, 연결 없이 시작할 수 있다', (tester) async {
    final loading = Completer<List<TodoRead>>();
    await open(tester, todos: () => loading.future);

    expect(fieldEnabled(tester), isFalse);
    await tester.tap(todoField());
    await tester.pumpAndSettle();
    expect(searchField(), findsNothing);

    await start(tester);

    expect(result?.todos, isEmpty);
    expect(result?.title, '새 작업');
  });

  testWidgets('할 일을 읽는 동안에도 처음 연결할 할 일은 남는다', (tester) async {
    final loading = Completer<List<TodoRead>>();
    await open(tester, todos: () => loading.future, initialTodo: report);

    expect(fieldEnabled(tester), isFalse);
    expect(fieldShows('보고서 쓰기'), findsOneWidget);

    loading.complete([report, meeting]);
    await tester.pumpAndSettle();

    expect(fieldEnabled(tester), isTrue);
    expect(fieldShows('보고서 쓰기'), findsOneWidget);

    await start(tester);

    expect(result?.todos, [report]);
  });

  testWidgets('할 일을 읽지 못하면 칸을 막고 알리며, 연결 없이 시작할 수 있다', (tester) async {
    await open(tester, todos: () async => throw StateError('읽기 실패'));

    expect(fieldEnabled(tester), isFalse);
    expect(find.text('할 일을 불러오지 못했습니다'), findsOneWidget);

    await start(tester);

    expect(result?.todos, isEmpty);
    expect(result?.title, '새 작업');
  });

  testWidgets('360 폭에서 긴 제목의 할 일을 골라도 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const long = '아주 긴 할 일 제목이 들어가도 새 작업 시작 다이얼로그가 넘치지 않아야 한다';

    await open(
      tester,
      todos: () async => [
        report,
        todo('todo-9', long),
        for (var i = 0; i < 20; i++) todo('todo-$i-more', '할 일 $i'),
      ],
    );
    await openPicker(tester);
    expect(tester.takeException(), isNull);
    expect(tester.getRect(pickerItem(long)).right, lessThanOrEqualTo(360));

    await tester.tap(pickerItem(long));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(titleText(tester), long);
    expect(fieldShows(long), findsOneWidget);
  });

  for (final (size, keyboard) in const [
    (Size(360, 800), 300.0),
    (Size(360, 640), 280.0),
  ]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('$label 화면에 키보드가 올라와도 다이얼로그와 할 일 목록이 넘치지 않는다', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.reset);

      await open(
        tester,
        todos: () async => [
          for (var i = 0; i < 20; i++) todo('todo-$i', '할 일 $i'),
        ],
      );
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(todoField());
      await tester.pumpAndSettle();
      await openPicker(tester);

      expect(tester.takeException(), isNull);
      expect(searchField(), findsOneWidget);
    });
  }

  group('여러 할 일', () {
    final review = todo('todo-3', '코드 리뷰');

    Future<void> openWithThree(WidgetTester tester, {TodoRead? initialTodo}) =>
        open(
          tester,
          todos: () async => [report, meeting, review],
          initialTodo: initialTodo,
        );

    Finder checkbox(String label) =>
        find.descendant(of: pickerItem(label), matching: find.byType(Checkbox));
    bool? checked(WidgetTester tester, String label) =>
        tester.widget<Checkbox>(checkbox(label)).value;
    Finder confirmPicks() => find.ancestor(
      of: find.textContaining(RegExp(r'^\d+개 선택 완료$')),
      matching: find.byType(FilledButton),
    );
    bool titleEnabled(WidgetTester tester) =>
        tester.widget<TextField>(titleField()).enabled ?? true;

    /// 할 일 목록에서 [labels]를 차례대로 체크하고 선택 완료를 누른다
    Future<void> checkAll(WidgetTester tester, List<String> labels) async {
      await openPicker(tester);
      for (final label in labels) {
        await tester.tap(checkbox(label));
        await tester.pump();
      }
      await tester.tap(confirmPicks());
      await tester.pumpAndSettle();
    }

    testWidgets('할 일마다 체크 상자가 있고 둘 이상 체크해야 선택 완료가 나온다', (tester) async {
      await openWithThree(tester);
      await openPicker(tester);

      expect(checkbox('보고서 쓰기'), findsOneWidget);
      expect(checkbox('회의 준비'), findsOneWidget);
      expect(checkbox('연결 안 함'), findsNothing);
      expect(confirmPicks(), findsNothing);

      await tester.tap(checkbox('보고서 쓰기'));
      await tester.pump();
      expect(checked(tester, '보고서 쓰기'), isTrue);
      expect(confirmPicks(), findsNothing);
      // 체크만 하고는 닫지 않는다
      expect(searchField(), findsOneWidget);

      await tester.tap(checkbox('회의 준비'));
      await tester.pump();
      expect(find.widgetWithText(FilledButton, '2개 선택 완료'), findsOneWidget);

      await tester.tap(checkbox('보고서 쓰기'));
      await tester.pump();
      expect(checked(tester, '보고서 쓰기'), isFalse);
      expect(confirmPicks(), findsNothing);
    });

    testWidgets('둘 이상 고르면 작업명 칸을 막고 안내하며 체크한 차례대로 돌려준다', (tester) async {
      await openWithThree(tester);
      await tester.enterText(titleField(), '직접 쓴 작업명');

      await checkAll(tester, ['회의 준비', '보고서 쓰기']);

      expect(searchField(), findsNothing);
      expect(fieldShows('회의 준비 외 1개'), findsOneWidget);
      expect(titleEnabled(tester), isFalse);
      expect(find.text('할 일마다 그 제목으로 타이머를 하나씩 시작합니다'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, '45분'));
      await tester.pump();
      await start(tester);

      expect(closed, isTrue);
      expect(result?.todos, [meeting, report]);
      expect(result?.duration, const Duration(minutes: 45));
    });

    testWidgets('셋을 고르면 첫 할 일 외 2개로 보인다', (tester) async {
      await openWithThree(tester);

      await checkAll(tester, ['코드 리뷰', '보고서 쓰기', '회의 준비']);

      expect(fieldShows('코드 리뷰 외 2개'), findsOneWidget);
      await start(tester);
      expect(result?.todos, [review, report, meeting]);
    });

    testWidgets('목록을 다시 열면 고른 할 일이 체크돼 있고, 하나를 누르면 그 할 일 하나로 돌아가 작업명 칸이 풀린다', (
      tester,
    ) async {
      await openWithThree(tester);
      await checkAll(tester, ['보고서 쓰기', '회의 준비']);

      await openPicker(tester);
      expect(checked(tester, '보고서 쓰기'), isTrue);
      expect(checked(tester, '회의 준비'), isTrue);
      expect(checked(tester, '코드 리뷰'), isFalse);
      await tester.tap(
        find.descendant(of: pickerItem('코드 리뷰'), matching: find.text('코드 리뷰')),
      );
      await tester.pumpAndSettle();

      expect(fieldShows('코드 리뷰'), findsOneWidget);
      expect(titleEnabled(tester), isTrue);
      expect(titleText(tester), '코드 리뷰');
      await start(tester);
      expect(result?.todos, [review]);
      expect(result?.title, '코드 리뷰');
    });

    testWidgets("'연결 안 함'을 누르면 고른 할 일을 모두 풀고 작업명 칸이 풀린다", (tester) async {
      await openWithThree(tester);
      await checkAll(tester, ['보고서 쓰기', '회의 준비']);

      await choose(tester, '연결 안 함');

      expect(fieldShows('연결 안 함'), findsOneWidget);
      expect(titleEnabled(tester), isTrue);
      await start(tester);
      expect(result?.todos, isEmpty);
      expect(result?.title, '새 작업');
    });

    testWidgets('체크한 채 목록을 그냥 닫으면 앞서 고른 할 일을 그대로 둔다', (tester) async {
      await openWithThree(tester, initialTodo: report);
      await openPicker(tester);
      await tester.tap(checkbox('회의 준비'));
      await tester.pump();

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      expect(searchField(), findsNothing);
      expect(fieldShows('보고서 쓰기'), findsOneWidget);
      expect(titleEnabled(tester), isTrue);
      await start(tester);
      expect(result?.todos, [report]);
    });

    testWidgets('처음 연결할 할 일을 체크한 채 열고 다른 할 일을 더 체크하면 둘 다 돌려준다', (tester) async {
      await openWithThree(tester, initialTodo: report);
      await openPicker(tester);

      expect(checked(tester, '보고서 쓰기'), isTrue);
      await tester.tap(checkbox('코드 리뷰'));
      await tester.pump();
      await tester.tap(confirmPicks());
      await tester.pumpAndSettle();
      await start(tester);

      expect(result?.todos, [report, review]);
    });

    testWidgets('찾아서 걸러도 앞서 체크한 할 일은 남는다', (tester) async {
      await openWithThree(tester);
      await openPicker(tester);
      await tester.tap(checkbox('보고서 쓰기'));
      await tester.pump();

      await tester.enterText(searchField(), '회의');
      await tester.pumpAndSettle();
      expect(pickerItem('보고서 쓰기'), findsNothing);
      await tester.tap(checkbox('회의 준비'));
      await tester.pump();
      await tester.tap(confirmPicks());
      await tester.pumpAndSettle();
      await start(tester);

      expect(result?.todos, [report, meeting]);
    });
  });
}
