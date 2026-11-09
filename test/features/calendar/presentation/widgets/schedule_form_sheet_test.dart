import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_form_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/schedule_fixtures.dart';
import '../../../../helpers/sheet_host.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  late FakeSchedulesClient schedules;

  // 날짜 고르기 창은 오늘 기준 1년 전~2년 뒤만 받으므로 이번 달 안에서 고른다
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 10, 9);
  final end = DateTime(now.year, now.month, 10, 10);

  setUp(() {
    schedules = FakeSchedulesClient();
  });

  Future<void> openCreate(
    WidgetTester tester, {
    DateTime? initialStartTime,
    DateTime? initialEndTime,
    DateTime? initialDate,
  }) => pumpSheetHost(
    tester,
    overrides: [schedulesApiProvider.overrideWithValue(schedules)],
    open: (context) => showScheduleFormSheet(
      context,
      initialStartTime: initialStartTime,
      initialEndTime: initialEndTime,
      initialDate: initialDate,
    ),
  );

  Future<void> openEdit(WidgetTester tester, ScheduleRead schedule) {
    schedules.schedules.add(schedule);
    return pumpSheetHost(
      tester,
      overrides: [schedulesApiProvider.overrideWithValue(schedules)],
      open: (context) => showScheduleEditSheet(context, schedule),
    );
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  String hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  group('새 일정', () {
    testWidgets('제목이 비면 오류를 보이고 보내지 않는다', (tester) async {
      await openCreate(tester, initialStartTime: start, initialEndTime: end);

      expect(find.text('새 일정'), findsOneWidget);
      await tapVisible(tester, find.text('저장'));
      expect(find.text('제목을 입력해주세요'), findsOneWidget);
      expect(schedules.created, isEmpty);
    });

    testWidgets('받은 시각을 보이고, 제목·설명을 다듬어 UTC 시각과 함께 보낸 뒤 닫는다', (tester) async {
      await openCreate(tester, initialStartTime: start, initialEndTime: end);

      expect(find.textContaining('${start.month}월 10일'), findsNWidgets(2));
      expect(find.textContaining('09:00'), findsOneWidget);
      expect(find.textContaining('10:00'), findsOneWidget);
      await tester.enterText(field('제목'), '  회의  ');
      await tester.enterText(field('설명 (선택사항)'), '  안건 정리  ');
      await tapVisible(tester, find.text('저장'));

      final body = schedules.created.single;
      expect(body.title, '회의');
      expect(body.description, '안건 정리');
      expect(body.startTime, start.toUtc());
      expect(body.startTime.isUtc, isTrue);
      expect(body.endTime, end.toUtc());
      expect(find.text('새 일정'), findsNothing);
      expect(find.text('일정이 생성되었습니다'), findsOneWidget);
    });

    testWidgets('설명이 비면 null로 보낸다', (tester) async {
      await openCreate(tester, initialStartTime: start, initialEndTime: end);
      await tester.enterText(field('제목'), '회의');
      await tapVisible(tester, find.text('저장'));

      expect(schedules.created.single.description, isNull);
    });

    testWidgets('날짜만 받으면 그날 지금의 다음 정각부터 1시간으로 잡는다', (tester) async {
      final day = DateTime(now.year, now.month, 12);
      await openCreate(tester, initialDate: day);
      final hour = DateTime.now().hour;
      final next = hour < 23 ? hour + 1 : hour;
      await tester.enterText(field('제목'), '회의');
      await tapVisible(tester, find.text('저장'));

      final body = schedules.created.single;
      expect(body.startTime.toLocal(), DateTime(day.year, day.month, 12, next));
      expect(
        body.endTime.toLocal(),
        DateTime(day.year, day.month, 12, next).add(const Duration(hours: 1)),
      );
    });

    testWidgets('종일을 켜면 시작은 그날 00:00, 종료는 종료일 23:59로 보내고 시각을 숨긴다', (
      tester,
    ) async {
      await openCreate(tester, initialStartTime: start, initialEndTime: end);
      await tapVisible(tester, find.text('종일'));

      expect(find.text('하루 종일 일정으로 설정됩니다'), findsOneWidget);
      expect(find.textContaining(':'), findsNothing);
      await tester.enterText(field('제목'), '휴가');
      await tapVisible(tester, find.text('저장'));

      final body = schedules.created.single;
      expect(body.startTime.toLocal(), DateTime(now.year, now.month, 10));
      expect(body.endTime.toLocal(), DateTime(now.year, now.month, 10, 23, 59));
    });

    testWidgets('종료가 시작보다 이르면 오류를 보이고 보내지 않는다', (tester) async {
      await openCreate(tester, initialStartTime: end, initialEndTime: start);

      expect(find.text('종료 시간은 시작 시간보다 늦어야 합니다'), findsOneWidget);
      await tester.enterText(field('제목'), '회의');
      await tapVisible(tester, find.text('저장'));

      expect(find.text('종료 시간은 시작 시간보다 늦어야 합니다'), findsNWidgets(2));
      expect(schedules.created, isEmpty);
    });

    testWidgets('시작을 종료보다 늦은 날로 고르면 종료를 그 1시간 뒤로 민다', (tester) async {
      await openCreate(tester, initialStartTime: start, initialEndTime: end);
      await tapVisible(tester, find.textContaining('09:00'));
      await tapVisible(tester, find.text('20'));
      await tapVisible(tester, find.text('확인'));
      await tapVisible(tester, find.text('확인'));
      await tester.enterText(field('제목'), '회의');
      await tapVisible(tester, find.text('저장'));

      final body = schedules.created.single;
      expect(body.startTime.toLocal(), DateTime(now.year, now.month, 20, 9));
      expect(body.endTime.toLocal(), DateTime(now.year, now.month, 20, 10));
    });

    testWidgets('종료를 시작보다 이른 날로 고르면 시작을 그 1시간 앞으로 당긴다', (tester) async {
      await openCreate(tester, initialStartTime: start, initialEndTime: end);
      await tapVisible(tester, find.textContaining('10:00'));
      await tapVisible(tester, find.text('5'));
      await tapVisible(tester, find.text('확인'));
      await tapVisible(tester, find.text('확인'));
      await tester.enterText(field('제목'), '회의');
      await tapVisible(tester, find.text('저장'));

      final body = schedules.created.single;
      expect(body.startTime.toLocal(), DateTime(now.year, now.month, 5, 9));
      expect(body.endTime.toLocal(), DateTime(now.year, now.month, 5, 10));
    });

    testWidgets('날짜 고르기를 취소하면 시각을 바꾸지 않는다', (tester) async {
      await openCreate(tester, initialStartTime: start, initialEndTime: end);
      await tapVisible(tester, find.textContaining('09:00'));
      await tapVisible(tester, find.text('20'));
      await tapVisible(
        tester,
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('취소'),
        ),
      );

      expect(find.textContaining('${start.month}월 10일'), findsNWidgets(2));
      expect(find.textContaining(hm(start)), findsOneWidget);
    });

    testWidgets('보내기에 실패하면 시트를 두고 오류를 알린다', (tester) async {
      schedules.writeError = Exception('서버 오류');
      await openCreate(tester, initialStartTime: start, initialEndTime: end);
      await tester.enterText(field('제목'), '회의');
      await tapVisible(tester, find.text('저장'));

      expect(find.text('새 일정'), findsOneWidget);
      expect(find.textContaining('일정 생성에 실패했습니다'), findsOneWidget);
    });

    testWidgets('취소는 보내지 않고 닫는다', (tester) async {
      await openCreate(tester, initialStartTime: start, initialEndTime: end);
      await tester.enterText(field('제목'), '회의');
      await tapVisible(tester, find.widgetWithText(OutlinedButton, '취소'));

      expect(find.text('새 일정'), findsNothing);
      expect(schedules.created, isEmpty);
    });
  });

  group('일정 수정', () {
    ScheduleRead existing({String? description = '안건'}) => makeSchedule(
      id: 'schedule-1',
      title: '회의',
      description: description,
      startTime: start.toUtc(),
      endTime: end.toUtc(),
    );

    testWidgets('기존 값을 채우고 바꾼 값을 보낸 뒤 닫는다', (tester) async {
      await openEdit(tester, existing());

      expect(find.text('일정 수정'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '회의'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '안건'), findsOneWidget);
      expect(find.textContaining('09:00'), findsOneWidget);

      await tester.enterText(field('제목'), '회의 2');
      await tapVisible(tester, find.text('수정'));

      final (id, body, options) = schedules.updated.single;
      expect(id, 'schedule-1');
      expect(body.title, '회의 2');
      expect(body.description, '안건');
      expect(body.startTime, start.toUtc());
      expect(body.endTime, end.toUtc());
      expect(explicitNullFields(options), isEmpty);
      expect(find.text('일정 수정'), findsNothing);
      expect(find.text('일정이 수정되었습니다'), findsOneWidget);
    });

    testWidgets('설명을 비우면 description을 null로 보내라고 표시한다', (tester) async {
      await openEdit(tester, existing());
      await tester.enterText(field('설명 (선택사항)'), '');
      await tapVisible(tester, find.text('수정'));

      final (_, body, options) = schedules.updated.single;
      expect(body.description, isNull);
      expect(explicitNullFields(options), ['description']);
    });

    testWidgets('다음 날 00:00에 끝나는 하루짜리 일정은 종일로 연다', (tester) async {
      final day = DateTime(now.year, now.month, 10);
      await openEdit(
        tester,
        makeSchedule(
          id: 'schedule-2',
          title: '휴가',
          startTime: day.toUtc(),
          endTime: day.add(const Duration(days: 1)).toUtc(),
        ),
      );

      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
    });

    testWidgets('수정에 실패하면 시트를 두고 오류를 알린다', (tester) async {
      schedules.writeError = Exception('서버 오류');
      await openEdit(tester, existing());
      await tapVisible(tester, find.text('수정'));

      expect(find.text('일정 수정'), findsOneWidget);
      expect(find.textContaining('일정 수정에 실패했습니다'), findsOneWidget);
    });
  });
}
