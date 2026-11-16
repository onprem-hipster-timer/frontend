import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_name_sheet.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../../../helpers/sheet_host.dart';
import '../../meeting_fixtures.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  late FakeMeetingsClient meetings;

  setUp(() {
    meetings = FakeMeetingsClient(meeting: makeMeeting())
      ..availability = [
        availabilityOf('participant-user-1', name: '지현', userId: 'user-1'),
      ];
  });

  /// 모임 화면처럼 모임 값을 불러 둔 채 시트를 연다
  Future<void> openSheet(WidgetTester tester) => pumpSheetHost(
    tester,
    overrides: meetingOverrides(meetings: meetings),
    open: (context) {
      ProviderScope.containerOf(
        context,
        listen: false,
      ).listen(meetingBoardProvider('meeting-1'), (_, _) {});
      showMeetingNameSheet(context, meetingId: 'meeting-1', currentName: '지현');
    },
  );

  Finder field() => find.byType(TextFormField);

  testWidgets('지금 이름을 채워 연다', (tester) async {
    await openSheet(tester);

    expect(find.text('내 이름'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '지현'), findsOneWidget);
  });

  testWidgets('비우거나 줄바꿈·탭을 넣거나 50자를 넘기면 알리고 보내지 않는다', (tester) async {
    await openSheet(tester);

    for (final (input, message) in [
      ('   ', '이름을 입력해 주세요'),
      ('김\t지현', '줄바꿈이나 탭은 쓸 수 없습니다'),
      ('가' * 51, '이름은 50자까지 쓸 수 있습니다'),
    ]) {
      await tester.enterText(field(), input);
      await tapVisible(tester, find.text('저장'));
      expect(find.text(message), findsOneWidget);
    }
    expect(meetings.participations, isEmpty);
  });

  testWidgets('저장하면 새 이름으로 참여 요청을 다시 보내고 닫은 뒤 알린다', (tester) async {
    await openSheet(tester);

    await tester.enterText(field(), '  새 이름 ');
    await tapVisible(tester, find.text('저장'));

    expect(meetings.participations, ['새 이름']);
    expect(find.text('내 이름'), findsNothing);
    expect(find.text('이름을 바꿨습니다'), findsOneWidget);
  });

  testWidgets('바꾸지 못하면 시트를 두고 알린다', (tester) async {
    meetings.participateError = Exception('끊김');
    await openSheet(tester);

    await tester.enterText(field(), '새 이름');
    await tapVisible(tester, find.text('저장'));

    expect(find.text('내 이름'), findsOneWidget);
    expect(find.textContaining('이름을 바꾸지 못했습니다'), findsOneWidget);
  });
}
