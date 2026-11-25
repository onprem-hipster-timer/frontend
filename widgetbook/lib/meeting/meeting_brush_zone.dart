import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_brush_zone.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '칠하기 붓과 안내',
  type: MeetingBrushZone,
  path: '[모임]/내 시간 선택하기',
)
Widget meetingBrushZone(BuildContext context) {
  final mode = context.knobs.object.dropdown(
    label: '받는 방식',
    description: '붓 아래 안내가 칠하는 칸(시간·날·요일)에 맞춰 바뀐다',
    options: const [MeetingMode.hourly, MeetingMode.daily, MeetingMode.weekly],
    labelBuilder: (mode) => switch (mode) {
      MeetingMode.hourly => '시간별',
      MeetingMode.weekly => '요일별',
      _ => '날짜별',
    },
  );
  // 앱에서는 '내 시간 선택하기' 제목과 격자 사이, 화면 폭으로 놓인다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: _ZoneHost(mode: mode),
  );
}

/// 누르면 고른 붓과 안내가 바뀌도록 붓을 쥔다
class _ZoneHost extends StatefulWidget {
  const _ZoneHost({required this.mode});

  final MeetingMode mode;

  @override
  State<_ZoneHost> createState() => _ZoneHostState();
}

class _ZoneHostState extends State<_ZoneHost> {
  var _brush = MeetingAnswer.available;

  @override
  Widget build(BuildContext context) => MeetingBrushZone(
    brush: _brush,
    mode: widget.mode,
    onBrushChanged: (brush) => setState(() => _brush = brush),
  );
}
