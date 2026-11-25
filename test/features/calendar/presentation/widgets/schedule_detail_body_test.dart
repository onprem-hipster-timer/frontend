import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_detail_body.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';

import '../../../../helpers/schedule_fixtures.dart';

final _convertLabel = '${Terms.todo.withJosa('으로', '로')} 변환';
const _linkedLabel = '연결된 ${Terms.todo} 보기';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  final pressed = <String>[];

  setUp(pressed.clear);

  Widget body({ScheduleRead? schedule, bool enabled = true}) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ScheduleDetailBody(
          schedule: schedule ?? makeSchedule(title: '팀 회의'),
          timerSection: const Text('타이머 자리'),
          onOpenLinked: enabled ? () => pressed.add('linked') : null,
          onConvert: enabled ? () => pressed.add('convert') : null,
          onEdit: enabled ? () => pressed.add('edit') : null,
          onDelete: enabled ? () => pressed.add('delete') : null,
        ),
      ),
    ),
  );

  testWidgets('일정 상세 본문은 제목과 받은 타이머 자리를 보인다', (tester) async {
    await tester.pumpWidget(body());

    expect(find.text('팀 회의'), findsOneWidget);
    expect(find.text('타이머 자리'), findsOneWidget);
  });

  testWidgets('할 일과 이어지지 않은 일정에서 변환을 누르면 받은 콜백을 부른다', (tester) async {
    await tester.pumpWidget(body());

    expect(find.text(_linkedLabel), findsNothing);
    await tester.tap(find.text(_convertLabel));
    expect(pressed, ['convert']);
  });

  testWidgets('할 일과 이어진 일정에서 연결된 할 일 보기를 누르면 받은 콜백을 부른다', (tester) async {
    await tester.pumpWidget(
      body(schedule: makeSchedule(sourceTodoId: 'todo-1')),
    );

    expect(find.text(_convertLabel), findsNothing);
    await tester.tap(find.text(_linkedLabel));
    expect(pressed, ['linked']);
  });

  testWidgets('본문에서 수정과 삭제를 누르면 받은 콜백을 부른다', (tester) async {
    await tester.pumpWidget(body());

    await tester.tap(find.text('수정'));
    await tester.tap(find.text('삭제'));
    expect(pressed, ['edit', 'delete']);
  });

  testWidgets('콜백을 주지 않으면 변환·수정·삭제를 눌러도 아무것도 부르지 않는다', (tester) async {
    await tester.pumpWidget(body(enabled: false));

    await tester.tap(find.text(_convertLabel));
    await tester.tap(find.text('수정'));
    await tester.tap(find.text('삭제'));
    expect(pressed, isEmpty);
  });

  testWidgets('변환 알림의 할 일 보기를 누르면 받은 콜백을 부른다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTodoConvertedNotice(
                context,
                onShowTodo: () => pressed.add('show'),
              ),
              child: const Text('띄우기'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('띄우기'));
    await tester.pumpAndSettle();
    expect(
      find.text('${Terms.todo.withJosa('으로', '로')} 변환되었습니다'),
      findsOneWidget,
    );
    await tester.tap(find.text('${Terms.todo} 보기'));
    expect(pressed, ['show']);
  });

  testWidgets('삭제를 누를 수 없으면 오류색이 아닌 비활성 모양으로 보인다', (tester) async {
    Color? background(bool enabled) {
      final button = tester.widget<FilledButton>(
        find.ancestor(of: find.text('삭제'), matching: find.byType(FilledButton)),
      );
      return button.style!.backgroundColor!.resolve({
        if (!enabled) WidgetState.disabled,
      });
    }

    await tester.pumpWidget(body());
    final error = Theme.of(tester.element(find.text('삭제'))).colorScheme.error;
    expect(background(true), error);

    await tester.pumpWidget(body(enabled: false));
    expect(background(false), isNot(error));
  });

  Future<void> showConverted(
    WidgetTester tester, {
    bool persist = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTodoConvertedNotice(
                context,
                onShowTodo: () {},
                persist: persist,
              ),
              child: const Text('띄우기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('띄우기'));
    await tester.pumpAndSettle();
  }

  testWidgets('변환 알림은 4초 뒤 저절로 닫힌다', (tester) async {
    await showConverted(tester);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('남기기를 고르면 변환 알림이 1분이 지나도 남는다', (tester) async {
    await showConverted(tester, persist: true);

    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(SnackBarAction, '${Terms.todo} 보기'),
      findsOneWidget,
    );
  });
}
