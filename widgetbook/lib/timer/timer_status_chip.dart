import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_status_chip.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '타이머 상태 칩', type: TimerStatusChip, path: '[타이머]')
Widget timerStatusChip(BuildContext context) {
  final status = context.knobs.object.dropdown(
    label: '상태',
    options: const [
      TimerStatus.running,
      TimerStatus.paused,
      TimerStatus.completed,
      TimerStatus.cancelled,
    ],
    labelBuilder: (status) => timerStatusStyle(context, status).label,
  );
  // 앱에서는 타이머 목록 항목의 시각·이름 앞에 놓인다
  return Center(child: TimerStatusChip(timerStatusStyle(context, status)));
}
