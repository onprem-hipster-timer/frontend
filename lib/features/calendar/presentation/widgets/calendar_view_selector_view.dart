import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';

/// 고를 수 있는 보기와 그 아이콘·이름
const _views = [
  (CalendarViewType.day, Icons.view_day, '일간'),
  (CalendarViewType.week, Icons.view_week, '주간'),
  (CalendarViewType.month, Icons.calendar_view_month, '월간'),
  (CalendarViewType.agenda, Icons.view_list, '목록'),
];

/// 화면 폭이 이보다 좁으면 보기를 메뉴로 고른다
const _menuBelowWidth = 600.0;

/// 달력 보기(일·주·월·목록) 고르기. 넓은 화면은 아이콘을 나란히, 좁은 화면은 지금 보기의
/// 아이콘을 누르면 여는 메뉴로 보인다. 고른 보기로 [onSelected]를 부른다
class CalendarViewSelectorView extends StatelessWidget {
  const CalendarViewSelectorView({
    super.key,
    required this.current,
    required this.onSelected,
  });

  /// 지금 보기
  final CalendarViewType current;
  final ValueChanged<CalendarViewType> onSelected;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < _menuBelowWidth) {
      final (_, icon, _) = _views.firstWhere(
        (view) => view.$1 == current,
        orElse: () => _views[2],
      );
      return PopupMenuButton<CalendarViewType>(
        icon: Icon(icon),
        tooltip: '보기 바꾸기',
        initialValue: current,
        onSelected: onSelected,
        itemBuilder: (context) => [
          for (final (view, icon, label) in _views)
            PopupMenuItem(
              value: view,
              child: ListTile(
                leading: Icon(icon),
                title: Text(label),
                contentPadding: EdgeInsets.zero,
              ),
            ),
        ],
      );
    }

    return SegmentedButton<CalendarViewType>(
      segments: [
        for (final (view, icon, label) in _views)
          ButtonSegment(
            value: view,
            icon: Icon(icon, size: 16),
            tooltip: label,
          ),
      ],
      selected: {current},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onSelected(selection.first),
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
    );
  }
}
