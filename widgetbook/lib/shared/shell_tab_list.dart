import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/widgets/shell_tab_list.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '탭 목록 서랍', type: ShellTabList, path: '[공통]/화면 틀')
Widget shellTabList(BuildContext context) {
  final current = context.knobs.object.dropdown(
    label: '지금 탭',
    description: '아주 작은 화면(접는 폰 덮개 화면 등)에서 ☰를 누르면 여는 서랍. 누르면 고른 탭이 바뀐다',
    options: List.generate(shellTabs.length, (i) => i),
    labelBuilder: (i) => shellTabs[i].$2,
  );
  // 앱에서는 왼쪽에서 열리는 서랍 안에 둔다
  return Align(
    alignment: Alignment.centerLeft,
    child: _TabDrawer(key: ValueKey(current), initial: current),
  );
}

class _TabDrawer extends StatefulWidget {
  const _TabDrawer({super.key, required this.initial});

  final int initial;

  @override
  State<_TabDrawer> createState() => _TabDrawerState();
}

class _TabDrawerState extends State<_TabDrawer> {
  late var _current = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: SingleChildScrollView(
          child: ShellTabList(
            current: _current,
            onSelect: (i) => setState(() => _current = i),
          ),
        ),
      ),
    );
  }
}
