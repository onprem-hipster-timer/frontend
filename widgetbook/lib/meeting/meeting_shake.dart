import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_mode_selector.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_shake.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_meeting_c.dart';

@widgetbook.UseCase(name: '떨어서 알리기', type: MeetingShake, path: '[모임]/화면 틀')
Widget meetingShake(BuildContext context) {
  final reduce = context.knobs.boolean(
    label: '애니메이션 줄이기',
    description: meetingReduceMotionDescription,
  );
  // 앱에서는 날짜를 바꿔 받는 방식이 저절로 바뀌었을 때 방식 고르기가 이렇게 떤다
  return meetingMotionSetting(
    context,
    reduce: reduce,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: MeetingReplay(
        label: '떨기',
        builder: (context, count) => Align(
          alignment: Alignment.topLeft,
          child: MeetingShake(
            count: count,
            child: MeetingModeSelector(
              mode: MeetingMode.daily,
              hourlyEnabled: false,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}
