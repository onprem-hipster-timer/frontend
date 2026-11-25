import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/shared/widgets/scaffold_with_nav.dart';
import 'package:momeet/shared/widgets/shell_tab_list.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../preview_router.dart';

const _tabRoutes = [
  AppRoute.calendar,
  AppRoute.todo,
  AppRoute.timer,
  AppRoute.tags,
  AppRoute.mypage,
];

/// 화면 크기마다 내비 모양이 다르다. null이면 미리보기 화면 크기 그대로다
const _screens = <String, Size?>{
  '보통 화면 (하단 바)': null,
  '낮은 화면 (왼쪽 세로 내비)': Size(780, 360),
  '아주 작은 화면 (☰ 서랍)': Size(300, 420),
};

@widgetbook.UseCase(name: '탭 화면 틀', type: ScaffoldWithNavBar, path: '[공통]/화면 틀')
Widget scaffoldWithNavBar(BuildContext context) {
  final screen =
      _screens[context.knobs.object.dropdown(
        label: '화면',
        description:
            '높이가 500보다 낮으면(가로로 든 휴대폰) 왼쪽 세로 내비, 긴 변도 480보다 짧으면(접는 폰 덮개 화면) '
            '내비를 숨기고 각 화면의 ☰로 탭 목록을 연다. 그 밖에는 떠 있는 하단 바',
        options: _screens.keys.toList(),
      )];
  final shell = PreviewRouter(
    initialLocation: AppRoute.calendar.path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          for (final (i, route) in _tabRoutes.indexed)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: route.path,
                  builder: (context, state) => _TabScreen(i),
                ),
              ],
            ),
        ],
      ),
    ],
  );
  if (screen == null) return shell;
  // 미리보기보다 큰 화면은 줄여 보인다. 누르는 자리도 함께 줄어든다
  return ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Center(
      child: FittedBox(
        child: SizedBox.fromSize(
          size: screen,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(size: screen),
            child: shell,
          ),
        ),
      ),
    ),
  );
}

/// 탭 하나의 첫 화면 자리. 아주 작은 화면이면 앱 화면처럼 앱바 왼쪽에 ☰가 있다
class _TabScreen extends StatelessWidget {
  const _TabScreen(this.index);

  final int index;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = shellTabs[index];
    return Scaffold(
      appBar: AppBar(
        leading: ShellScope.compactOf(context) ? const ShellMenuButton() : null,
        title: Text(label),
      ),
      body: AppEmptyState(
        icon: icon,
        title: '$label 화면',
        message: '앱에서는 여기에 $label 화면이 놓입니다. 내비를 눌러 탭을 옮겨 보세요',
      ),
    );
  }
}
