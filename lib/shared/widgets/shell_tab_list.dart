import 'package:material_ui/material_ui.dart';

/// 탭 다섯 개의 아이콘과 이름
const shellTabs = [
  (Icons.calendar_month_rounded, '캘린더'),
  (Icons.check_circle_outline_rounded, '할 일'),
  (Icons.timer_rounded, '타이머'),
  (Icons.label_outline_rounded, '태그'),
  (Icons.person_outline_rounded, '마이페이지'),
];

/// 탭 목록. 아주 작은 화면에서 ☰ 서랍에 둔다
class ShellTabList extends StatelessWidget {
  const ShellTabList({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final int current;

  /// 탭을 고른다. 서랍은 이 목록이 닫는다
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, (icon, label)) in shellTabs.indexed)
          ListTile(
            leading: Icon(icon),
            title: Text(label),
            selected: i == current,
            onTap: () {
              Navigator.of(context).maybePop();
              onSelect(i);
            },
          ),
      ],
    );
  }
}
