import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_hourly_band.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '받지 않는 시간 띠',
  type: MeetingHourlyBand,
  path: '[모임]/내 시간 선택하기',
)
Widget meetingHourlyBand(BuildContext context) {
  final knobs = context.knobs;
  final text = knobs.object.dropdown(
    label: '자리',
    description: '시간별 격자에서 하루 범위 앞(위)과 뒤(아래)에 붙는다',
    options: const ['0:00–6:00 · 받지 않는 시간', '18:00–24:00 · 받지 않는 시간'],
  );
  final height = knobs.double.slider(
    label: '높이',
    description: '한 시간 칸 높이를 따른다. 글자가 커지면 같이 커진다',
    initialValue: 40,
    min: 24,
    max: 80,
    divisions: 14,
    precision: 0,
  );
  // 앱에서는 시각 축(폭 44) 오른쪽, 날짜 열 전체에 걸친다
  return Padding(
    padding: const EdgeInsets.fromLTRB(60, 16, 16, 16),
    child: MeetingHourlyBand(text: text, height: height),
  );
}
