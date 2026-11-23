import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_share_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_timer.dart';

@widgetbook.UseCase(name: '공유 설정 버튼', type: TimerShareButton, path: '[타이머]')
Widget timerShareButton(BuildContext context) {
  final level = context.knobs.object
      .dropdown(
        label: '공유 범위',
        options: const <(String, VisibilityLevel?)>[
          ('비공개', null),
          ('친구 공개', VisibilityLevel.friends),
          ('선택한 친구', VisibilityLevel.selected),
          ('이메일 지정', VisibilityLevel.allowedEmails),
          ('전체 공개', VisibilityLevel.public),
        ],
        labelBuilder: (option) => option.$1,
      )
      .$2;
  // 앱에서는 대시보드의 내 타이머 작업 제목 뒤에 놓인다
  return Center(
    child: TimerShareButton(timer: sampleTimer(visibilityLevel: level)),
  );
}
