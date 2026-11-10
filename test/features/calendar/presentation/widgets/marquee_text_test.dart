import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/marquee_text.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_appointment_block.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

const _long = '분기 보고서 초안을 팀과 함께 검토하고 수정 사항 정리하기';
const _style = TextStyle(fontSize: 11);

Future<void> _pumpText(
  WidgetTester tester, {
  required String text,
  required bool active,
  double width = 80,
  bool reduceMotion = false,
  int? loops,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Center(
          child: SizedBox(
            width: width,
            child: MarqueeText(
              text,
              style: _style,
              active: active,
              loops: loops,
            ),
          ),
        ),
      ),
    ),
  );
}

/// 흐르는 글자의 가로 이동량. 흐르지 않으면 null
double? _shift(WidgetTester tester) {
  final moving = find.descendant(
    of: find.byType(MarqueeText),
    matching: find.byType(Transform),
  );
  if (moving.evaluate().isEmpty) return null;
  return tester.widget<Transform>(moving.first).transform.getTranslation().x;
}

void main() {
  testWidgets('넘치는 글자는 활성인 동안 왼쪽으로 흐른다', (tester) async {
    await _pumpText(tester, text: _long, active: true);
    await tester.pump();
    final start = _shift(tester);
    await tester.pump(const Duration(milliseconds: 500));

    expect(start, isNotNull);
    expect(_shift(tester), lessThan(start!));
    expect(tester.takeException(), isNull);
  });

  testWidgets('활성이 아니거나 다 들어가거나 동작 줄이기면 흐르지 않고 말줄임으로 둔다', (tester) async {
    await _pumpText(tester, text: _long, active: false);
    expect(_shift(tester), isNull);

    await _pumpText(tester, text: '회의', active: true, width: 200);
    expect(_shift(tester), isNull);

    await _pumpText(tester, text: _long, active: true, reduceMotion: true);
    expect(_shift(tester), isNull);
    expect(
      tester.widget<Text>(find.text(_long)).overflow,
      TextOverflow.ellipsis,
    );
  });

  testWidgets('정한 횟수만큼 흐른 뒤 멈추고 말줄임으로 돌아간다', (tester) async {
    await _pumpText(tester, text: _long, active: true, loops: 2);
    await tester.pump();
    expect(_shift(tester), isNotNull);

    await tester.pumpAndSettle();

    expect(_shift(tester), isNull);
    expect(
      tester.widget<Text>(find.text(_long)).overflow,
      TextOverflow.ellipsis,
    );
  });

  testWidgets('흐르는 동안에도 스크린 리더는 제목을 한 번만 읽는다', (tester) async {
    await _pumpText(tester, text: _long, active: true);
    await tester.pump();

    expect(find.bySemanticsLabel(_long), findsOneWidget);
  });

  testWidgets('일정 블록은 마우스를 올린 동안에만 긴 제목을 흘린다', (tester) async {
    final appointment = Appointment(
      startTime: DateTime(2026, 11, 9, 9),
      endTime: DateTime(2026, 11, 9, 10),
      subject: _long,
      color: const Color(0xFFB3D4FF),
    );
    final bounds = const Rect.fromLTWH(0, 0, 80, 18);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.fromSize(
            size: bounds.size,
            child: ScheduleAppointmentBlock(
              details: CalendarAppointmentDetails(DateTime(2026, 11, 9), [
                appointment,
              ], bounds),
              viewType: CalendarViewType.month,
            ),
          ),
        ),
      ),
    );
    expect(_shift(tester), isNull);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(ScheduleAppointmentBlock)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(_shift(tester), isNotNull);

    await mouse.moveTo(Offset.zero);
    await tester.pump();
    expect(_shift(tester), isNull);
  });
}
