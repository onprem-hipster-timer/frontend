import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:momeet/features/calendar/presentation/pages/schedule_detail_page.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_detail_providers.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_mutations.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/schedule_fixtures.dart';
import '../../../../helpers/timer_fixtures.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  const testScheduleId = 'schedule-1';

  late ScheduleRead testSchedule;
  late List<TimerRead> testTimers;

  setUp(() {
    testSchedule = makeSchedule(
      id: testScheduleId,
      title: '팀 회의',
      description: '주간 팀 미팅입니다',
      state: ScheduleState.confirmed,
      tags: [makeTag(name: '업무', color: '#4CAF50')],
    );
    testTimers = [
      makeTimer(
        id: 'timer-1',
        status: TimerStatus.completed,
        elapsedTime: 1800,
      ),
    ];
  });

  Widget buildPage({
    ScheduleRead? schedule,
    List<TimerRead>? timers,
    Object? scheduleError,
  }) {
    return pumpApp(
      const ScheduleDetailPage(scheduleId: testScheduleId),
      overrides: [
        scheduleDetailProvider(testScheduleId).overrideWith(
          (ref) => scheduleError != null
              ? Future<ScheduleRead>.error(scheduleError)
              : Future.value(schedule ?? testSchedule),
        ),
        scheduleTimersProvider(
          testScheduleId,
        ).overrideWith((ref) => Future.value(timers ?? testTimers)),
        scheduleMutationsProvider.overrideWith(ScheduleMutations.new),
      ],
    );
  }

  // ============================================================
  // 기본 렌더링
  // ============================================================
  group('기본 렌더링', () {
    testWidgets('AppBar에 "일정 상세" 제목이 표시된다', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('일정 상세'), findsOneWidget);
    });

    testWidgets('일정 제목이 표시된다', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('팀 회의'), findsOneWidget);
    });

    testWidgets('일정 설명이 표시된다', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('주간 팀 미팅입니다'), findsOneWidget);
    });

    testWidgets('일정 상태가 표시된다', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('확정됨'), findsAtLeastNWidgets(1));
    });

    testWidgets('태그가 표시된다', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('업무'), findsOneWidget);
    });

    testWidgets('수정/삭제 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('수정'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
    });
  });

  // ============================================================
  // 타이머 섹션
  // ============================================================
  group('타이머 섹션', () {
    testWidgets('타이머가 있으면 타이머 섹션이 표시된다', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('타이머'), findsAtLeastNWidgets(1));
      expect(find.text('1'), findsAtLeastNWidgets(1)); // 타이머 개수 배지
    });

    testWidgets('타이머가 없으면 타이머 섹션이 숨겨진다', (tester) async {
      await tester.pumpWidget(buildPage(timers: []));
      await tester.pumpAndSettle();

      expect(find.text('타이머'), findsNothing);
    });

    testWidgets('완료된 타이머의 상태 텍스트가 표시된다', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('완료'), findsOneWidget);
    });
  });

  // ============================================================
  // TODO 변환
  // ============================================================
  group('TODO 변환', () {
    testWidgets('연결된 TODO가 없으면 변환 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('TODO로 변환'), findsOneWidget);
    });

    testWidgets('연결된 TODO가 있으면 "연결된 TODO 보기" 버튼이 표시된다', (tester) async {
      final linkedSchedule = makeSchedule(
        id: testScheduleId,
        title: '연결된 일정',
        sourceTodoId: 'todo-123',
        tagGroupId: 'group-1',
      );

      await tester.pumpWidget(buildPage(schedule: linkedSchedule));
      await tester.pumpAndSettle();

      expect(find.text('연결된 TODO 보기'), findsOneWidget);
      expect(find.text('TODO로 변환'), findsNothing);
    });
  });

  // ============================================================
  // 에러 상태
  // ============================================================
  group('에러 상태', () {
    testWidgets('로딩 실패 시 에러 메시지와 재시도 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(buildPage(scheduleError: Exception('네트워크 오류')));
      await tester.pumpAndSettle();

      expect(find.text('일정을 불러올 수 없습니다'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });
  });

  // ============================================================
  // 일정 상태별 표시
  // ============================================================
  group('일정 상태별 표시', () {
    testWidgets('계획됨 상태가 올바르게 표시된다', (tester) async {
      final planned = makeSchedule(
        id: testScheduleId,
        title: '계획된 일정',
        state: ScheduleState.planned,
      );
      await tester.pumpWidget(buildPage(schedule: planned));
      await tester.pumpAndSettle();

      expect(find.text('계획됨'), findsAtLeastNWidgets(1));
    });

    testWidgets('취소됨 상태가 올바르게 표시된다', (tester) async {
      final cancelled = makeSchedule(
        id: testScheduleId,
        title: '취소된 일정',
        state: ScheduleState.cancelled,
      );
      await tester.pumpWidget(buildPage(schedule: cancelled));
      await tester.pumpAndSettle();

      expect(find.text('취소됨'), findsAtLeastNWidgets(1));
    });
  });

  // ============================================================
  // 설명 없는 일정
  // ============================================================
  group('선택적 필드', () {
    testWidgets('설명이 없으면 설명 영역이 표시되지 않는다', (tester) async {
      final noDesc = makeSchedule(id: testScheduleId, title: '설명 없는 일정');
      await tester.pumpWidget(buildPage(schedule: noDesc));
      await tester.pumpAndSettle();

      expect(find.text('설명'), findsNothing);
    });

    testWidgets('태그가 없으면 태그 영역이 표시되지 않는다', (tester) async {
      final noTags = makeSchedule(
        id: testScheduleId,
        title: '태그 없는 일정',
        tags: [],
      );
      await tester.pumpWidget(buildPage(schedule: noTags));
      await tester.pumpAndSettle();

      expect(find.text('태그'), findsNothing);
    });

    testWidgets('반복 규칙이 있으면 반복 일정 표시된다', (tester) async {
      final recurring = makeSchedule(
        id: testScheduleId,
        title: '반복 일정',
        recurrenceRule: 'FREQ=WEEKLY',
      );
      await tester.pumpWidget(buildPage(schedule: recurring));
      await tester.pumpAndSettle();

      expect(find.text('반복 일정'), findsAtLeastNWidgets(1));
    });
  });
}
