import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_legend.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '참여자 색 설명',
  type: MeetingGridLegend,
  path: '[모임]/내 시간 선택하기',
)
Widget meetingGridLegend(BuildContext context) {
  final knobs = context.knobs;
  final total = knobs.int.slider(
    label: '다른 참여자 수',
    description: '0명이면 아무것도 보이지 않는다. 다섯 명이 넘으면 색은 다섯 단계로 묶인다',
    initialValue: 3,
    min: 0,
    max: 20,
  );
  final self = knobs.boolean(
    label: '로그인함',
    description: "로그인했으면 '다른 참여자', 로그인 전 방문자에게는 '참여자'",
    initialValue: true,
  );
  // 앱에서는 격자 바로 아래, 왼쪽에 붙는다
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Align(
      alignment: AlignmentDirectional.topStart,
      child: MeetingGridLegend(othersTotal: total, hasSelf: self),
    ),
  );
}
