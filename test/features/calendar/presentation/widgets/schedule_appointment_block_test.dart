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
}) async {
  final bounds = Rect.fromLTWH(0, 0, 120, height);
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

  testWidgets('일·주 보기는 블록이 높을수록 시간과 설명을 더 보인다', (tester) async {
    await _pump(tester, CalendarViewType.week, height: 45);
    expect(find.text('회의'), findsOneWidget);
    expect(find.textContaining(' - '), findsNothing);

    await _pump(tester, CalendarViewType.week, height: 60);
    expect(find.textContaining(' - '), findsOneWidget);
    expect(find.text('안건 정리'), findsNothing);

    await _pump(tester, CalendarViewType.day, height: 80);
    expect(find.textContaining(' - '), findsOneWidget);
    expect(find.text('안건 정리'), findsOneWidget);
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
