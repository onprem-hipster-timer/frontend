import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_home_button.dart';
import 'package:momeet/features/mypage/presentation/widgets/my_meeting_tile.dart';
import 'package:momeet_widgetbook/calendar/holiday_detail_sheet.dart';
import 'package:momeet_widgetbook/calendar/schedule_list_sheet.dart';
import 'package:momeet_widgetbook/meeting/meeting_home_button.dart';
import 'package:momeet_widgetbook/mypage/my_meeting_tile.dart';
import 'package:momeet_widgetbook/sample_provider_scope.dart';
import 'package:momeet_widgetbook/shared/scaffold_with_nav.dart';
import 'package:widgetbook/widgetbook.dart';

import 'support/pump_use_case.dart';

Future<void> _pump(
  WidgetTester tester,
  WidgetBuilder builder, {
  Brightness brightness = Brightness.light,
}) => pumpUseCase(
  tester,
  WidgetbookUseCase(name: 'use-case', builder: builder),
  brightness: brightness,
);

void main() {
  testWidgets('앱 이미지(assets/...)가 카탈로그 번들에서 그려진다', (tester) async {
    await _pump(tester, meetingHomeButton);
    final image = find.descendant(
      of: find.byType(MeetingHomeButton),
      matching: find.byType(Image),
    );
    await tester.runAsync(
      () => precacheImage(
        tester.widget<Image>(image).image,
        tester.element(image),
      ),
    );
    await tester.pump();

    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
  });

  testWidgets('앱 화면으로 가는 단추는 안내 화면을 띄우고, 뒤로 가면 use case로 돌아온다', (tester) async {
    await _pump(tester, myMeetingTile);

    await tester.tap(find.byType(MyMeetingTile));
    await tester.pumpAndSettle();
    expect(
      find.text('앱에서는 여기서 \'모임\' 화면이 열립니다.\n카탈로그에는 그 화면이 없어 이 안내로 대신합니다.'),
      findsOneWidget,
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(MyMeetingTile), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('use case 안의 화면 이동은 브라우저 주소를 바꾸지 않는다', (tester) async {
    final reported = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.navigation,
      (call) async {
        if (call.method == 'routeInformationUpdated') {
          reported.add((call.arguments as Map)['uri'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.navigation,
        null,
      ),
    );
    await _pump(tester, myMeetingTile);

    await tester.tap(find.byType(MyMeetingTile));
    await tester.pumpAndSettle();

    // Widgetbook과 appBuilder의 MaterialApp이 알리는 주소만 있다
    expect(reported, isNot(anyElement(startsWith('/use-case'))));
    expect(reported, isNot(anyElement(startsWith('/meetings'))));
  });

  testWidgets('go로 옮긴 안내 화면에서도 뒤로 가면 use case로 돌아온다', (tester) async {
    await _pump(tester, meetingHomeButton);

    await tester.tap(find.byType(MeetingHomeButton));
    await tester.pumpAndSettle();
    expect(find.text('캘린더'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(MeetingHomeButton), findsOneWidget);
  });

  testWidgets('시트의 닫기 단추로 닫아도 시트를 다시 그린다', (tester) async {
    await _pump(tester, holidayDetailSheet);

    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();

    expect(find.text('닫기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('시트를 닫고 앱 화면으로 가도 안내 화면이 뜬다', (tester) async {
    await _pump(tester, scheduleListSheet);

    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(find.text('일정 상세'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('라우터 안에서도 테마·언어 애드온이 use case에 걸린다', (tester) async {
    late BuildContext context;
    await _pump(tester, (c) {
      context = c;
      return const SizedBox();
    }, brightness: Brightness.dark);

    expect(Theme.of(context).brightness, Brightness.dark);
    expect(Localizations.localeOf(context), const Locale('ko', 'KR'));
  });

  testWidgets('탭 화면 틀은 내비를 눌러 탭을 옮긴다', (tester) async {
    await _pump(tester, scaffoldWithNavBar);
    expect(find.text('캘린더 화면'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.label_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('태그 화면'), findsOneWidget);
    expect(find.text('캘린더 화면'), findsNothing);
  });

  testWidgets('견본으로 덮어쓰지 않은 프로바이더를 읽으면 오류가 난다', (tester) async {
    final real = Provider((ref) => '진짜');
    final sample = Provider((ref) => '견본');
    await tester.pumpWidget(
      SampleProviderScope(
        overrides: [sample.overrideWithValue('덮어씀')],
        child: Consumer(
          builder: (context, ref, _) => Text(
            '${ref.watch(sample)} ${ref.watch(real)}',
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isStateError);
  });
}
