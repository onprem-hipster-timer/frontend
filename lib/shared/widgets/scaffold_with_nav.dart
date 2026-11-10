import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/shared/widgets/shell_scope.dart';
import 'package:momeet/shared/widgets/shell_tab_list.dart';

export 'package:momeet/shared/widgets/shell_menu_button.dart';
export 'package:momeet/shared/widgets/shell_scope.dart';

/// 화면 높이가 이보다 낮으면(가로 휴대폰 등) 하단 바 대신 왼쪽 세로 내비를 쓴다
const _railBelowHeight = 500.0;

/// 긴 변과 짧은 변이 모두 이보다 작으면(접는 폰 덮개 화면 등) 내비를 숨기고 ☰로 탭을 옮긴다
const _compactBelowSide = 480.0;

/// 탭 화면을 감싸는 스캐폴드. go_router의 StatefulShellRoute와 함께 쓴다.
///
/// 보통은 콘텐츠 위에 떠 있는 알약 모양 하단 바를, 낮은 화면에서는 왼쪽 세로 내비를 둔다.
/// 아주 작은 화면은 내비 없이 화면 전체를 쓰고, 각 탭 화면의 ☰([ShellMenuButton])로 탭 목록을 연다.
class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final current = navigationShell.currentIndex;
    final size = MediaQuery.sizeOf(context);
    if (size.longestSide < _compactBelowSide) {
      return Scaffold(
        drawer: Drawer(
          child: SafeArea(
            child: SingleChildScrollView(
              child: ShellTabList(current: current, onSelect: _onTap),
            ),
          ),
        ),
        body: Builder(
          builder: (context) => ShellScope(
            compact: true,
            current: current,
            onSelect: _onTap,
            openTabs: () => Scaffold.of(context).openDrawer(),
            child: navigationShell,
          ),
        ),
      );
    }
    if (size.height < _railBelowHeight) {
      return Scaffold(
        body: Row(
          children: [
            _SideNav(current: current, onSelect: _onTap),
            const VerticalDivider(width: 1),
            Expanded(
              child: ShellScope(
                compact: false,
                current: current,
                onSelect: _onTap,
                openTabs: () {},
                child: navigationShell,
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          // 하단 바가 콘텐츠를 가리지 않게 그 높이만큼 비운다
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: ShellScope(
                compact: false,
                current: current,
                onSelect: _onTap,
                openTabs: () {},
                child: navigationShell,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _FloatingNavBar(current: current, onSelect: _onTap),
          ),
        ],
      ),
    );
  }

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // 같은 탭을 다시 누르면 그 탭의 첫 화면으로 간다
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// 낮은 화면의 왼쪽 세로 내비
class _SideNav extends StatelessWidget {
  const _SideNav({required this.current, required this.onSelect});

  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      right: false,
      child: SingleChildScrollView(
        child: IntrinsicHeight(
          child: NavigationRail(
            selectedIndex: current,
            onDestinationSelected: onSelect,
            labelType: NavigationRailLabelType.all,
            groupAlignment: 0,
            destinations: [
              for (final (icon, label) in shellTabs)
                NavigationRailDestination(icon: Icon(icon), label: Text(label)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 콘텐츠 위에 떠 있는 알약 모양 하단 바
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({required this.current, required this.onSelect});

  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: AppRadius.pillAll,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.pillAll,
        child: BottomNavigationBar(
          currentIndex: current,
          onTap: onSelect,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.transparent,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: theme.primaryColor,
          unselectedItemColor: theme.colorScheme.onSurfaceVariant,
          items: [
            for (final (icon, label) in shellTabs)
              BottomNavigationBarItem(
                icon: Icon(icon, size: 28),
                label: label,
                tooltip: label,
              ),
          ],
        ),
      ),
    );
  }
}
