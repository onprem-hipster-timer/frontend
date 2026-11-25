import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view_selector_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '달력 보기 고르기',
  type: CalendarViewSelectorView,
  path: '[달력]',
)
Widget calendarViewSelectorView(BuildContext context) {
  final knobs = context.knobs;
  final current = knobs.object
      .dropdown(
        label: '지금 보기',
        options: const [
          (CalendarViewType.day, '일간'),
          (CalendarViewType.week, '주간'),
          (CalendarViewType.month, '월간'),
          (CalendarViewType.agenda, '목록'),
        ],
        labelBuilder: (option) => option.$2,
        initialOption: (CalendarViewType.month, '월간'),
      )
      .$1;
  final wide = knobs.boolean(
    label: '넓은 화면',
    description: '화면 폭이 600 이상이면 네 보기를 나란히 두고, 좁으면 지금 보기 아이콘을 눌러 메뉴에서 고른다',
  );
  // 앱에서는 달력 화면 위 도구 줄의 오른쪽 끝, 다음 기간 버튼 뒤에 놓인다.
  // 노브를 바꾸면 고른 보기를 버리고 노브 값으로 돌아간다
  final selector = Align(
    alignment: Alignment.topRight,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: _Selector(key: ValueKey(current), initial: current),
    ),
  );
  if (!wide) return selector;
  final media = MediaQuery.of(context);
  return MediaQuery(
    data: media.copyWith(size: Size(800, media.size.height)),
    child: selector,
  );
}

/// 고른 보기가 바로 보이도록 값을 들고 있는다
class _Selector extends StatefulWidget {
  const _Selector({super.key, required this.initial});

  final CalendarViewType initial;

  @override
  State<_Selector> createState() => _SelectorState();
}

class _SelectorState extends State<_Selector> {
  late var _current = widget.initial;

  @override
  Widget build(BuildContext context) {
    return CalendarViewSelectorView(
      current: _current,
      onSelected: (view) => setState(() => _current = view),
    );
  }
}
