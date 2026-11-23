import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_mode_selector.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '받는 방식 고르기',
  type: MeetingModeSelector,
  path: '[모임]/모임 만들기',
)
Widget meetingModeSelector(BuildContext context) {
  final hourly = context.knobs.boolean(
    label: '시간별 고를 수 있음',
    description: '고른 날짜가 $hourlyMaxDays일을 넘으면 시간별을 고를 수 없다',
    initialValue: true,
  );
  // 앱에서는 전체 설정 폼의 '모임 시간' 소제목 아래에 놓인다
  return Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: _Selector(hourlyEnabled: hourly),
    ),
  );
}

/// 누르면 고른 방식이 바뀐다
class _Selector extends StatefulWidget {
  const _Selector({required this.hourlyEnabled});

  final bool hourlyEnabled;

  @override
  State<_Selector> createState() => _SelectorState();
}

class _SelectorState extends State<_Selector> {
  var _mode = MeetingMode.daily;

  @override
  Widget build(BuildContext context) {
    return MeetingModeSelector(
      mode: _mode,
      hourlyEnabled: widget.hourlyEnabled,
      onChanged: (mode) => setState(() => _mode = mode),
    );
  }
}
