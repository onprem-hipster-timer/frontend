import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/shared_preferences_provider.dart';
import 'package:momeet/features/settings/presentation/widgets/timezone_selection_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../../../helpers/sheet_host.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late SharedPreferences prefs;

  Future<void> open(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'user_timezone': 'Asia/Seoul'});
    prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showTimezoneSelectionSheet(context),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  testWidgets('지금 타임존에 표시를 하고, 검색어로 목록을 거른다', (tester) async {
    await open(tester);

    expect(find.text('타임존 선택'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'seoul');
    await tester.pumpAndSettle();

    expect(find.text('Asia/Seoul'), findsOneWidget);
    expect(find.text('Asia/Tokyo'), findsNothing);
    expect(
      tester.getSemantics(find.text('Asia/Seoul')).flagsCollection.isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets('검색어를 지우면 전체 목록으로 돌아간다', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'seoul');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byIcon(Icons.clear));

    expect(find.textContaining('/'), findsWidgets);
    expect(find.textContaining('/').evaluate().length, greaterThan(1));
  });

  testWidgets('고르면 저장하고 닫는다', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'tokyo');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Asia/Tokyo'));

    expect(find.text('타임존 선택'), findsNothing);
    expect(prefs.getString('user_timezone'), 'Asia/Tokyo');
  });

  testWidgets('닫기 버튼은 바꾸지 않고 닫는다', (tester) async {
    await open(tester);
    await tapVisible(tester, find.byIcon(Icons.close));

    expect(find.text('타임존 선택'), findsNothing);
    expect(prefs.getString('user_timezone'), 'Asia/Seoul');
  });
}
