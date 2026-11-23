import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
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
                  builder: (context, state) => Scaffold(
                    appBar: AppBar(
                      leading: ShellScope.compactOf(context)
                          ? const ShellMenuButton()
                          : null,
                    ),
                    body: Text('${_tabs[i]} 화면'),
                  ),
                ),
              ],
            ),
        ],
      ),
      GoRoute(
        path: '/out',
        builder: (context, state) => const Scaffold(body: Text('셸 밖 화면')),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
  await tester.pumpAndSettle();
}

/// 알림의 보이는 면. SnackBar 자체 영역은 바깥 여백까지 잡는다
Rect _noticeRect(WidgetTester tester, String message) => tester.getRect(
  find.ancestor(of: find.text(message), matching: find.byType(Material)).first,
);

Rect _navRect(WidgetTester tester) {
  final rail = find.byType(NavigationRail);
  return tester.getRect(
    rail.evaluate().isEmpty ? find.byType(BottomNavigationBar) : rail,
  );
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

  testWidgets('하단 바는 탭 화면 아래에 놓여 그 화면을 가리지 않는다', (tester) async {
    await _pumpShell(tester, const Size(390, 844));

    final page = tester.getRect(
      find
          .ancestor(of: find.text('캘린더 화면'), matching: find.byType(Scaffold))
          .first,
    );
    expect(page.bottom, lessThanOrEqualTo(_navRect(tester).top));
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
    expect(selected.selectedIndex, _tabs.indexOf('마이페이지'));
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

  testWidgets('아주 작은 화면은 내비 없이 ☰로 탭 목록을 열어 탭을 옮긴다', (tester) async {
    await _pumpShell(tester, const Size(360, 374));

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);
    final content = tester.getRect(find.text('캘린더 화면'));
    expect(content.left, lessThan(16));

    await tester.tap(find.byTooltip('화면 이동'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('타이머'));
    await tester.pumpAndSettle();

    expect(find.text('타이머 화면'), findsOneWidget);
    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('작지 않은 화면의 탭 화면에는 ☰가 없다', (tester) async {
    await _pumpShell(tester, const Size(360, 800));

    expect(find.byTooltip('화면 이동'), findsNothing);
  });

  group('탭 화면에서 띄운 알림은 화면 안에서 내비를 가리지 않는다', () {
    for (final (layout, size) in const [
      ('휴대폰 세로의 하단 바', Size(390, 844)),
      ('넓은 화면의 하단 바', Size(1000, 1400)),
      ('낮은 화면의 세로 내비', Size(844, 390)),
    ]) {
      testWidgets(layout, (tester) async {
        await _pumpShell(tester, size);
        final page = tester.element(find.text('캘린더 화면'));
        final screen = Offset.zero & size;

        void expectClear(String message) {
          final notice = _noticeRect(tester, message);
          final nav = _navRect(tester);
          expect(notice.overlaps(nav), isFalse, reason: '알림 $notice, 내비 $nav');
          expect(screen.intersect(notice), notice);
        }

        showAppSnackBar(page, '일정이 삭제되었습니다', kind: AppNoticeKind.success);
        await tester.pumpAndSettle();
        expectClear('일정이 삭제되었습니다');

        unawaited(ScaffoldMessenger.of(page).showAppUndoSnackBar('일정을 지웠습니다'));
        await tester.pumpAndSettle();
        expectClear('일정을 지웠습니다');
      });
    }
  });

  testWidgets('떠 있던 알림은 창 높이가 바뀌어 내비 모양이 바뀌어도 새 내비를 가리지 않는다', (tester) async {
    await _pumpShell(tester, const Size(844, 800));
    showAppSnackBar(tester.element(find.text('캘린더 화면')), '저장했습니다');
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    final notice = _noticeRect(tester, '저장했습니다');
    expect(notice.overlaps(_navRect(tester)), isFalse);
  });

  group('내비가 없는 곳의 알림은 화면 바닥에 뜬다', () {
    testWidgets('셸 밖 화면', (tester) async {
      await _pumpShell(tester, const Size(1000, 1400));
      GoRouter.of(tester.element(find.text('캘린더 화면'))).go('/out');
      await tester.pumpAndSettle();

      showAppSnackBar(tester.element(find.text('셸 밖 화면')), '저장했습니다');
      await tester.pumpAndSettle();

      expect(1400 - _noticeRect(tester, '저장했습니다').bottom, lessThan(16));
    });

    testWidgets('아주 작은 화면의 탭 화면', (tester) async {
      await _pumpShell(tester, const Size(360, 374));

      showAppSnackBar(tester.element(find.text('캘린더 화면')), '저장했습니다');
      await tester.pumpAndSettle();

      expect(374 - _noticeRect(tester, '저장했습니다').bottom, lessThan(16));
    });
  });
}
