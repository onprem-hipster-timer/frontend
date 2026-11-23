import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_brush_picker.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '붓 고르기',
  type: MeetingBrushPicker,
  path: '[모임]/되는 시간 칠하기',
)
Widget meetingBrushPicker(BuildContext context) {
  return const Center(
    child: Padding(padding: EdgeInsets.all(16), child: _BrushHost()),
  );
}

/// 누르면 고른 붓이 바뀌도록 값을 쥔다
class _BrushHost extends StatefulWidget {
  const _BrushHost();

  @override
  State<_BrushHost> createState() => _BrushHostState();
}

class _BrushHostState extends State<_BrushHost> {
  var _brush = MeetingAnswer.available;

  @override
  Widget build(BuildContext context) => MeetingBrushPicker(
    value: _brush,
    onChanged: (brush) => setState(() => _brush = brush),
  );
}
