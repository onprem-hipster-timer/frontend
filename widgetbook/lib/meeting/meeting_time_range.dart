import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_time_range.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '하루 시간 범위',
  type: MeetingTimeRange,
  path: '[모임]/모임 만들기',
)
Widget meetingTimeRange(BuildContext context) {
  // 앱에서는 시간 범위 질문과 전체 설정 폼의 '모임 시간' 아래에 놓인다
  return const Align(
    alignment: Alignment.topLeft,
    child: Padding(padding: EdgeInsets.all(16), child: _Range()),
  );
}

/// 고른 시각을 들고 있다. 시작을 끝 뒤로 옮기면 끝을 한 시간 뒤로 민다
class _Range extends StatefulWidget {
  const _Range();

  @override
  State<_Range> createState() => _RangeState();
}

class _RangeState extends State<_Range> {
  var _start = meetingDefaultStartHour;
  var _end = meetingDefaultEndHour;

  @override
  Widget build(BuildContext context) {
    return MeetingTimeRange(
      startHour: _start,
      endHour: _end,
      onStartChanged: (hour) => setState(() {
        _start = hour;
        if (_end <= hour) _end = hour + 1;
      }),
      onEndChanged: (hour) => setState(() => _end = hour),
    );
  }
}
