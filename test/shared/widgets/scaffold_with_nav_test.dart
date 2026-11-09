import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/widgets/scaffold_with_nav.dart';

const _tabs = ['캘린더', '할 일', '타이머', '태그', '마이페이지'];

/// 하단 바는 이름을 숨기므로 접근성 이름표로 찾는다
Finder _barTab(String label) => find.bySemanticsLabel(RegExp('^$label'));

Future<void> _pumpShell(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/0',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            ScaffoldWithNavBar(navigationShell: shell),
        branches: [
          for (var i = 0; i < _tabs.length; i++)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/$i',
                  builder: (context, state) => Text('${_tabs[i]} 화면'),
                ),
              ],
            ),
        ],
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('높은 화면은 하단 바로 탭을 옮긴다', (tester) async {
    await _pumpShell(tester, const Size(360, 800));

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    await tester.tap(_barTab('타이머'));
    await tester.pumpAndSettle();
    expect(find.text('타이머 화면'), findsOneWidget);
  });

  testWidgets('낮은 화면은 왼쪽 세로 내비로 탭을 옮기고 콘텐츠 아래를 비우지 않는다', (tester) async {
    await _pumpShell(tester, const Size(844, 390));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    final rail = tester.getRect(find.byType(NavigationRail));
    final content = tester.getRect(find.text('캘린더 화면'));
    expect(content.left, greaterThanOrEqualTo(rail.right));

    await tester.tap(find.text('마이페이지'));
    await tester.pumpAndSettle();
    expect(find.text('마이페이지 화면'), findsOneWidget);
    final selected = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(selected.selectedIndex, 4);
  });

  testWidgets('창 높이가 바뀌면 그 자리에서 내비 모양을 바꾸고 탭을 유지한다', (tester) async {
    await _pumpShell(tester, const Size(360, 800));
    await tester.tap(_barTab('태그'));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(800, 360);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('태그 화면'), findsOneWidget);
  });

  testWidgets('아주 낮은 화면에서도 세로 내비가 넘치지 않는다', (tester) async {
    await _pumpShell(tester, const Size(640, 240));

    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationRail), findsOneWidget);
  });
}
