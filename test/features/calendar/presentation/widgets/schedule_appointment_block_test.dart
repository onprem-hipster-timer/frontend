import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_appointment_block.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

final _appointment = Appointment(
  startTime: DateTime(2026, 11, 9, 9),
  endTime: DateTime(2026, 11, 9, 10, 30),
  subject: '회의',
  notes: '안건 정리',
  color: const Color(0xFFB3D4FF),
);

Future<void> _pump(
  WidgetTester tester,
  CalendarViewType viewType, {
  double height = 100,
  double width = 120,
}) async {
  final bounds = Rect.fromLTWH(0, 0, width, height);
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox.fromSize(
          size: bounds.size,
          child: ScheduleAppointmentBlock(
            details: CalendarAppointmentDetails(DateTime(2026, 11, 9), [
              _appointment,
            ], bounds),
            viewType: viewType,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('월 보기는 제목만 보인다', (tester) async {
    await _pump(tester, CalendarViewType.month, height: 18);

    expect(find.text('회의'), findsOneWidget);
    expect(find.textContaining('안건'), findsNothing);
  });

  testWidgets('월 칸에 다 들어가지 않은 일정은 숨긴 수를 +N으로 보이고 그중 하나를 일정처럼 그리지 않는다', (
    tester,
  ) async {
    final hidden = [
      for (final title in ['고객 미팅', '보고서 마감'])
        Appointment(
          startTime: DateTime(2026, 11, 9, 9),
          endTime: DateTime(2026, 11, 9, 10),
          subject: title,
          color: const Color(0xFFB3D4FF),
        ),
    ];
    const bounds = Rect.fromLTWH(0, 0, 60, 18);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.fromSize(
            size: bounds.size,
            child: ScheduleAppointmentBlock(
              details: CalendarAppointmentDetails(
                DateTime(2026, 11, 9),
                hidden,
                bounds,
                isMoreAppointmentRegion: true,
              ),
              viewType: CalendarViewType.month,
            ),
          ),
        ),
      ),
    );

    expect(find.text('+2'), findsOneWidget);
    expect(find.bySemanticsLabel('일정 2개 더'), findsOneWidget);
    expect(find.text('고객 미팅'), findsNothing);
  });

  testWidgets('좁은 월 칸의 +N은 글자가 커도 잘리지 않는 만큼만 키운다', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    const bounds = Rect.fromLTWH(0, 0, 40, 20);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.fromSize(
            size: bounds.size,
            child: ScheduleAppointmentBlock(
              details: CalendarAppointmentDetails(
                DateTime(2026, 11, 9),
                [for (var i = 0; i < 5; i++) _appointment],
                bounds,
                isMoreAppointmentRegion: true,
              ),
              viewType: CalendarViewType.month,
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .renderObject<RenderParagraph>(
            find.descendant(
              of: find.text('+5'),
              matching: find.byType(RichText),
            ),
          )
          .didExceedMaxLines,
      isFalse,
    );
  });

  testWidgets('좁은 월 칸은 글자가 커도 제목이 두 글자는 남는 만큼만 키운다', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pump(tester, CalendarViewType.month, height: 40, width: 46);
    final narrow = tester.renderObject<RenderParagraph>(find.text('회의'));
    expect(narrow.didExceedMaxLines, isFalse);
    expect(narrow.textScaler.scale(1), lessThan(2));

    await _pump(tester, CalendarViewType.month, height: 40, width: 200);
    final wide = tester.renderObject<RenderParagraph>(find.text('회의'));
    expect(wide.textScaler.scale(1), 2);
  });

  testWidgets('일·주 보기는 들어가는 만큼만 시간과 설명 줄을 더 보인다', (tester) async {
    await _pump(tester, CalendarViewType.week, height: 45);
    expect(find.text('회의'), findsOneWidget);
    expect(find.textContaining(' - '), findsNothing);

    await _pump(tester, CalendarViewType.week, height: 56);
    expect(find.textContaining(' - '), findsOneWidget);
    expect(find.text('안건 정리'), findsNothing);

    await _pump(tester, CalendarViewType.day, height: 80);
    expect(find.textContaining(' - '), findsOneWidget);
    expect(find.text('안건 정리'), findsOneWidget);
  });

  testWidgets('글자가 크면 같은 높이에서도 줄을 덜 보이고 넘치지 않는다', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester, CalendarViewType.day, height: 80);

    expect(tester.takeException(), isNull);
    expect(find.text('회의'), findsOneWidget);
    expect(find.text('안건 정리'), findsNothing);
  });

  testWidgets('제목 한 줄보다 낮은 블록도 넘침 오류 없이 제목을 둔다', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester, CalendarViewType.week, height: 12);

    expect(tester.takeException(), isNull);
    expect(find.text('회의'), findsOneWidget);
  });

  testWidgets('설명이 비었으면 높은 블록에서도 설명 줄을 두지 않는다', (tester) async {
    _appointment.notes = '';
    addTearDown(() => _appointment.notes = '안건 정리');
    await _pump(tester, CalendarViewType.week, height: 80);

    expect(find.byType(Text), findsNWidgets(2));
  });

  testWidgets('일정 목록 보기는 시작 시각과 제목을 한 줄에 보인다', (tester) async {
    await _pump(tester, CalendarViewType.agenda, height: 30);

    expect(find.text('회의'), findsOneWidget);
    expect(find.byType(Row), findsOneWidget);
  });
}
