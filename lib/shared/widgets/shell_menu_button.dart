import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/widgets/shell_scope.dart';

/// 아주 작은 화면의 탭 화면 앱바 왼쪽 ☰. 누르면 탭 목록을 연다
class ShellMenuButton extends StatelessWidget {
  const ShellMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: '화면 이동',
      onPressed: ShellScope.maybeOf(context)?.openTabs,
    );
  }
}
