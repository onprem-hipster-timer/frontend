import 'package:material_ui/material_ui.dart';

/// 탭 셸이 아래 화면에 알리는 값. 아주 작은 화면이면 [compact]이고, 탭은 ☰로 옮긴다.
class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.compact,
    required this.current,
    required this.onSelect,
    required this.openTabs,
    required super.child,
  });

  /// 세로 내비·하단 바 없이 ☰로 탭을 옮기는 아주 작은 화면인지
  final bool compact;

  /// 지금 탭 번호
  final int current;

  /// 탭을 고른다
  final ValueChanged<int> onSelect;

  /// 탭 목록 서랍을 연다
  final VoidCallback openTabs;

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  /// 셸 안의 아주 작은 화면인지
  static bool compactOf(BuildContext context) =>
      maybeOf(context)?.compact ?? false;

  @override
  bool updateShouldNotify(ShellScope oldWidget) =>
      compact != oldWidget.compact || current != oldWidget.current;
}
