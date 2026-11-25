import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/shared/widgets/shell_menu_button.dart';
import 'package:momeet/shared/widgets/shell_scope.dart';
import 'package:momeet/shared/widgets/shell_tab_list.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '화면 이동 버튼 (☰)',
  type: ShellMenuButton,
  path: '[공통]/화면 틀',
)
Widget shellMenuButton(BuildContext context) => const _CompactShell();

/// 아주 작은 화면의 탭 셸처럼 하단 바 없이 ☰로 탭 목록 서랍을 연다
class _CompactShell extends StatefulWidget {
  const _CompactShell();

  @override
  State<_CompactShell> createState() => _CompactShellState();
}

class _CompactShellState extends State<_CompactShell> {
  var _current = 3;

  void _select(int index) => setState(() => _current = index);

  @override
  Widget build(BuildContext context) {
    final label = shellTabs[_current].$2;
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: SingleChildScrollView(
            child: ShellTabList(current: _current, onSelect: _select),
          ),
        ),
      ),
      body: Builder(
        builder: (context) => ShellScope(
          compact: true,
          current: _current,
          onSelect: _select,
          openTabs: () => Scaffold.of(context).openDrawer(),
          child: Scaffold(
            appBar: AppBar(
              leading: const ShellMenuButton(),
              title: Text(label),
            ),
            body: AppEmptyState(
              icon: shellTabs[_current].$1,
              title: '$label 화면',
              message: '왼쪽 위 ☰를 눌러 다른 화면으로 옮겨 보세요',
            ),
          ),
        ),
      ),
    );
  }
}
