import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/widgets/start_timer_sheet.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/start_timer_sheet_driver.dart';
import '../../../../helpers/timer_fixtures.dart';
import 'package:momeet/shared/domain/terms.dart';

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
                  result = await showStartTimerSheet(
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

  testWidgets('할 일을 고르면 비어 있는 작업명을 그 제목으로 채운다', (tester) async {
    await open(tester);
    expect(tester.startSheetTitle(), isEmpty);
    expect(StartSheet.todoShows('연결 안 함'), findsOneWidget);

    await tester.chooseTodo('보고서 쓰기');

    expect(StartSheet.searchField, findsNothing);
    expect(tester.startSheetTitle(), '보고서 쓰기');
    expect(StartSheet.todoShows('보고서 쓰기'), findsOneWidget);
  });

  testWidgets('할 일 제목으로 채운 작업명은 다른 할 일을 고르면 바뀌고, 고친 작업명은 그대로 둔다', (
    tester,
  ) async {
    await open(tester);

    await tester.chooseTodo('보고서 쓰기');
    await tester.chooseTodo('회의 준비');
    expect(tester.startSheetTitle(), '회의 준비');

    await tester.enterText(StartSheet.titleField, '회의 준비 자료');
    await tester.chooseTodo('보고서 쓰기');
    expect(tester.startSheetTitle(), '회의 준비 자료');
  });

  testWidgets('직접 입력한 작업명은 할 일을 골라도 그대로 두고 그 작업명으로 시작한다', (tester) async {
    await open(tester);
    await tester.enterText(StartSheet.titleField, '집중');

    await tester.chooseTodo('보고서 쓰기');
    expect(tester.startSheetTitle(), '집중');

    await tester.startFromSheet();

    expect(result?.title, '집중');
    expect(result?.todos, [report]);
  });

  testWidgets("'연결 안 함'을 고르면 연결을 풀고 작업명은 그대로 둔다", (tester) async {
    await open(tester, initialTodo: report);

    await tester.chooseTodo('연결 안 함');
    expect(StartSheet.todoShows('연결 안 함'), findsOneWidget);
    expect(tester.startSheetTitle(), '보고서 쓰기');

    await tester.startFromSheet();

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

    await tester.openTodoPicker();

    expect(StartSheet.pickerItem('연결 안 함'), findsOneWidget);
    expect(StartSheet.pickerItem('보고서 쓰기'), findsOneWidget);
    expect(StartSheet.pickerItem('예정된 일'), findsOneWidget);
    expect(StartSheet.pickerItem('끝낸 일'), findsNothing);
    expect(StartSheet.pickerItem('취소한 일'), findsNothing);
    expect(StartSheet.pickerItem('공유받은 일'), findsNothing);
  });

  testWidgets('제목으로 찾아 고른다', (tester) async {
    await open(tester);
    await tester.openTodoPicker();

    await tester.enterText(StartSheet.searchField, '회의');
    await tester.pump();

    expect(StartSheet.pickerItem('회의 준비'), findsOneWidget);
    expect(StartSheet.pickerItem('보고서 쓰기'), findsNothing);
    expect(StartSheet.pickerItem('연결 안 함'), findsOneWidget);

    await tester.tapPickerItem('회의 준비');
    await tester.startFromSheet();

    expect(result?.todos, [meeting]);
    expect(result?.title, '회의 준비');
  });

  testWidgets('목록을 고르지 않고 닫으면 연결한 할 일을 그대로 둔다', (tester) async {
    await open(tester, initialTodo: report);
    await tester.openTodoPicker();

    await tester.enterText(StartSheet.searchField, '회의');
    await tester.pump();
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(StartSheet.searchField, findsNothing);
    expect(StartSheet.todoShows('보고서 쓰기'), findsOneWidget);

    await tester.startFromSheet();

    expect(result?.todos, [report]);
  });

  testWidgets('시작하면 고른 할 일과 집중 시간을 돌려준다', (tester) async {
    await open(tester, initialDuration: const Duration(minutes: 45));

    await tester.chooseTodo('회의 준비');
    await tester.choosePreset(15);
    await tester.pump();
    await tester.startFromSheet();

    expect(closed, isTrue);
    expect(result?.todos, [meeting]);
    expect(result?.title, '회의 준비');
    expect(result?.duration, const Duration(minutes: 15));
  });

  testWidgets('작업명을 비우면 고른 할 일의 제목으로 시작한다', (tester) async {
    await open(tester);
    await tester.chooseTodo('보고서 쓰기');

    await tester.enterText(StartSheet.titleField, '  ');
    await tester.startFromSheet();

    expect(result?.title, '보고서 쓰기');
    expect(result?.todos, [report]);
  });

  testWidgets('타이머 제목도 할 일도 없으면 새 타이머로 시작한다', (tester) async {
    await open(tester);

    await tester.startFromSheet();

    expect(result?.title, '새 ${Terms.timer}');
    expect(result?.todos, isEmpty);
    expect(result?.duration, const Duration(minutes: 25));
  });

  testWidgets('취소하면 null을 돌려준다', (tester) async {
    await open(tester);
    await tester.chooseTodo('보고서 쓰기');

    await tester.cancelStartSheet();

    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('처음 연결할 할 일을 고른 채 열고 작업명을 그 제목으로 채운다', (tester) async {
    await open(tester, initialTodo: meeting);

    expect(tester.startSheetTitle(), '회의 준비');
    expect(StartSheet.todoShows('회의 준비'), findsOneWidget);

    await tester.startFromSheet();

    expect(result?.todos, [meeting]);
    expect(result?.title, '회의 준비');
  });

  testWidgets('할 일을 읽는 동안 할 일 칸을 막고, 연결 없이 시작할 수 있다', (tester) async {
    final loading = Completer<List<TodoRead>>();
    await open(tester, todos: () => loading.future);

    expect(tester.startSheetTodoEnabled(), isFalse);
    await tester.tap(StartSheet.todoField);
    await tester.pumpAndSettle();
    expect(StartSheet.searchField, findsNothing);

    await tester.startFromSheet();

    expect(result?.todos, isEmpty);
    expect(result?.title, '새 ${Terms.timer}');
  });

  testWidgets('할 일을 읽는 동안에도 처음 연결할 할 일은 남는다', (tester) async {
    final loading = Completer<List<TodoRead>>();
    await open(tester, todos: () => loading.future, initialTodo: report);

    expect(tester.startSheetTodoEnabled(), isFalse);
    expect(StartSheet.todoShows('보고서 쓰기'), findsOneWidget);

    loading.complete([report, meeting]);
    await tester.pumpAndSettle();

    expect(tester.startSheetTodoEnabled(), isTrue);
    expect(StartSheet.todoShows('보고서 쓰기'), findsOneWidget);

    await tester.startFromSheet();

    expect(result?.todos, [report]);
  });

  testWidgets('할 일을 읽지 못하면 칸을 막고 알리며, 연결 없이 시작할 수 있다', (tester) async {
    await open(tester, todos: () async => throw StateError('읽기 실패'));

    expect(tester.startSheetTodoEnabled(), isFalse);
    expect(find.text('할 일을 불러오지 못했습니다'), findsOneWidget);

    await tester.startFromSheet();

    expect(result?.todos, isEmpty);
    expect(result?.title, '새 ${Terms.timer}');
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
    await tester.openTodoPicker();
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(StartSheet.pickerItem(long)).right,
      lessThanOrEqualTo(360),
    );

    await tester.tapPickerItem(long);

    expect(tester.takeException(), isNull);
    expect(tester.startSheetTitle(), long);
    expect(StartSheet.todoShows(long), findsOneWidget);
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

      await tester.ensureVisible(StartSheet.todoField);
      await tester.pumpAndSettle();
      await tester.openTodoPicker();

      expect(tester.takeException(), isNull);
      expect(StartSheet.searchField, findsOneWidget);
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

    testWidgets('할 일마다 체크 상자가 있고 둘 이상 체크해야 선택 완료가 나온다', (tester) async {
      await openWithThree(tester);
      await tester.openTodoPicker();

      expect(StartSheet.checkbox('보고서 쓰기'), findsOneWidget);
      expect(StartSheet.checkbox('회의 준비'), findsOneWidget);
      expect(StartSheet.checkbox('연결 안 함'), findsNothing);
      expect(StartSheet.confirmPicks, findsNothing);

      await tester.tap(StartSheet.checkbox('보고서 쓰기'));
      await tester.pump();
      expect(tester.isTodoChecked('보고서 쓰기'), isTrue);
      expect(StartSheet.confirmPicks, findsNothing);
      // 체크만 하고는 닫지 않는다
      expect(StartSheet.searchField, findsOneWidget);

      await tester.tap(StartSheet.checkbox('회의 준비'));
      await tester.pump();
      expect(StartSheet.confirmPicks, findsOneWidget);

      await tester.tap(StartSheet.checkbox('보고서 쓰기'));
      await tester.pump();
      expect(tester.isTodoChecked('보고서 쓰기'), isFalse);
      expect(StartSheet.confirmPicks, findsNothing);
    });

    testWidgets('둘 이상 고르면 작업명 칸을 막고 안내하며 체크한 차례대로 돌려준다', (tester) async {
      await openWithThree(tester);
      await tester.enterText(StartSheet.titleField, '직접 쓴 작업명');

      await tester.checkTodos(['회의 준비', '보고서 쓰기']);

      expect(StartSheet.searchField, findsNothing);
      expect(StartSheet.todoShows('회의 준비 외 1개'), findsOneWidget);
      expect(tester.startSheetTitleEnabled(), isFalse);
      expect(find.text('할 일마다 그 제목으로 타이머를 하나씩 시작합니다'), findsOneWidget);

      await tester.choosePreset(45);
      await tester.pump();
      await tester.startFromSheet();

      expect(closed, isTrue);
      expect(result?.todos, [meeting, report]);
      expect(result?.duration, const Duration(minutes: 45));
    });

    testWidgets('셋을 고르면 첫 할 일 외 2개로 보인다', (tester) async {
      await openWithThree(tester);

      await tester.checkTodos(['코드 리뷰', '보고서 쓰기', '회의 준비']);

      expect(StartSheet.todoShows('코드 리뷰 외 2개'), findsOneWidget);
      await tester.startFromSheet();
      expect(result?.todos, [review, report, meeting]);
    });

    testWidgets('목록을 다시 열면 고른 할 일이 체크돼 있고, 하나를 누르면 그 할 일 하나로 돌아가 작업명 칸이 풀린다', (
      tester,
    ) async {
      await openWithThree(tester);
      await tester.checkTodos(['보고서 쓰기', '회의 준비']);

      await tester.openTodoPicker();
      expect(tester.isTodoChecked('보고서 쓰기'), isTrue);
      expect(tester.isTodoChecked('회의 준비'), isTrue);
      expect(tester.isTodoChecked('코드 리뷰'), isFalse);
      await tester.tapPickerItem('코드 리뷰');

      expect(StartSheet.todoShows('코드 리뷰'), findsOneWidget);
      expect(tester.startSheetTitleEnabled(), isTrue);
      expect(tester.startSheetTitle(), '코드 리뷰');
      await tester.startFromSheet();
      expect(result?.todos, [review]);
      expect(result?.title, '코드 리뷰');
    });

    testWidgets("'연결 안 함'을 누르면 고른 할 일을 모두 풀고 작업명 칸이 풀린다", (tester) async {
      await openWithThree(tester);
      await tester.checkTodos(['보고서 쓰기', '회의 준비']);

      await tester.chooseTodo('연결 안 함');

      expect(StartSheet.todoShows('연결 안 함'), findsOneWidget);
      expect(tester.startSheetTitleEnabled(), isTrue);
      await tester.startFromSheet();
      expect(result?.todos, isEmpty);
      expect(result?.title, '새 ${Terms.timer}');
    });

    testWidgets('체크한 채 목록을 그냥 닫으면 앞서 고른 할 일을 그대로 둔다', (tester) async {
      await openWithThree(tester, initialTodo: report);
      await tester.openTodoPicker();
      await tester.tap(StartSheet.checkbox('회의 준비'));
      await tester.pump();

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      expect(StartSheet.searchField, findsNothing);
      expect(StartSheet.todoShows('보고서 쓰기'), findsOneWidget);
      expect(tester.startSheetTitleEnabled(), isTrue);
      await tester.startFromSheet();
      expect(result?.todos, [report]);
    });

    testWidgets('처음 연결할 할 일을 체크한 채 열고 다른 할 일을 더 체크하면 둘 다 돌려준다', (tester) async {
      await openWithThree(tester, initialTodo: report);
      await tester.openTodoPicker();

      expect(tester.isTodoChecked('보고서 쓰기'), isTrue);
      await tester.tap(StartSheet.checkbox('코드 리뷰'));
      await tester.pump();
      await tester.tap(StartSheet.confirmPicks);
      await tester.pumpAndSettle();
      await tester.startFromSheet();

      expect(result?.todos, [report, review]);
    });

    testWidgets('찾아서 걸러도 앞서 체크한 할 일은 남는다', (tester) async {
      await openWithThree(tester);
      await tester.openTodoPicker();
      await tester.tap(StartSheet.checkbox('보고서 쓰기'));
      await tester.pump();

      await tester.enterText(StartSheet.searchField, '회의');
      await tester.pumpAndSettle();
      expect(StartSheet.pickerItem('보고서 쓰기'), findsNothing);
      await tester.tap(StartSheet.checkbox('회의 준비'));
      await tester.pump();
      await tester.tap(StartSheet.confirmPicks);
      await tester.pumpAndSettle();
      await tester.startFromSheet();

      expect(result?.todos, [report, meeting]);
    });
  });
}
