import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_list_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/schedule_fixtures.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  final testDate = DateTime(2026, 4, 7);

  late List<ScheduleRead> testSchedules;

  setUp(() {
    testSchedules = [
      makeSchedule(
        id: 'sched-1',
        title: '오전 회의',
        startTime: DateTime(2026, 4, 7, 9, 0),
        endTime: DateTime(2026, 4, 7, 10, 0),
        tags: [makeTag(name: '업무', color: '#4CAF50')],
      ),
      makeSchedule(
        id: 'sched-2',
        title: '점심 약속',
        startTime: DateTime(2026, 4, 7, 12, 0),
        endTime: DateTime(2026, 4, 7, 13, 0),
      ),
      makeSchedule(
        id: 'sched-3',
        title: '저녁 운동',
        startTime: DateTime(2026, 4, 7, 18, 0),
        endTime: DateTime(2026, 4, 7, 19, 30),
      ),
    ];
  });

  Widget buildSheet({DateTime? date, List<ScheduleRead>? schedules}) {
    return MaterialApp(
      home: Scaffold(
        body: ScheduleListSheet(
          date: date ?? testDate,
          schedules: schedules ?? testSchedules,
        ),
      ),
    );
  }

  // ============================================================
  // 기본 렌더링
  // ============================================================
  group('기본 렌더링', () {
    testWidgets('날짜 헤더가 표시된다', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      expect(find.textContaining('4월 7일'), findsOneWidget);
    });

    testWidgets('일정 개수가 표시된다', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      expect(find.text('3개 일정'), findsOneWidget);
    });

    testWidgets('모든 일정 제목이 표시된다', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      expect(find.text('오전 회의'), findsOneWidget);
      expect(find.text('점심 약속'), findsOneWidget);
      expect(find.text('저녁 운동'), findsOneWidget);
    });

    testWidgets('일정 시간이 표시된다', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      expect(find.text('09:00 - 10:00'), findsOneWidget);
      expect(find.text('12:00 - 13:00'), findsOneWidget);
      expect(find.text('18:00 - 19:30'), findsOneWidget);
    });

    testWidgets('chevron 아이콘이 각 일정에 표시된다', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));
    });
  });

  // ============================================================
  // 종일 일정
  // ============================================================
  group('종일 일정', () {
    testWidgets('종일 일정은 "종일"로 표시된다', (tester) async {
      final allDaySchedules = [
        makeSchedule(
          id: 'allday-1',
          title: '종일 이벤트',
          startTime: DateTime(2026, 4, 7),
          endTime: DateTime(2026, 4, 8),
        ),
      ];
      await tester.pumpWidget(buildSheet(schedules: allDaySchedules));
      await tester.pumpAndSettle();

      expect(find.text('종일'), findsOneWidget);
    });
  });

  // ============================================================
  // 단일 일정
  // ============================================================
  group('단일 일정', () {
    testWidgets('일정이 1개여도 올바르게 표시된다', (tester) async {
      final single = [
        makeSchedule(
          id: 'single-1',
          title: '유일한 일정',
          startTime: DateTime(2026, 4, 7, 14, 0),
          endTime: DateTime(2026, 4, 7, 15, 0),
        ),
      ];
      await tester.pumpWidget(buildSheet(schedules: single));
      await tester.pumpAndSettle();

      expect(find.text('1개 일정'), findsOneWidget);
      expect(find.text('유일한 일정'), findsOneWidget);
    });
  });

  // ============================================================
  // showScheduleListSheet 헬퍼
  // ============================================================
  group('showScheduleListSheet 헬퍼', () {
    testWidgets('바텀시트가 정상적으로 열린다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    showScheduleListSheet(context, testDate, testSchedules),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      expect(find.text('오전 회의'), findsOneWidget);
      expect(find.text('점심 약속'), findsOneWidget);
      expect(find.text('저녁 운동'), findsOneWidget);
    });

    testWidgets('바깥 영역을 탭하면 시트가 닫힌다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    showScheduleListSheet(context, testDate, testSchedules),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      // 시트 바깥 영역 탭
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      expect(find.text('오전 회의'), findsNothing);
    });
  });

  // ============================================================
  // 색상 표시
  // ============================================================
  group('색상 바 표시', () {
    testWidgets('태그가 있는 일정은 색상 바가 표시된다', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      // 색상 바 컨테이너 (width: 4, height: 40)가 존재하는지 확인
      final colorBars = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.maxWidth == 4 &&
            widget.constraints?.maxHeight == 40,
      );
      // ListTile의 leading으로 3개 존재
      expect(colorBars, findsNWidgets(3));
    });
  });
}
