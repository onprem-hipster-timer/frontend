import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_glass_bar.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_page_title.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '모임 화면 제목', type: MeetingPageTitle, path: '[모임]/화면 틀')
Widget meetingPageTitle(BuildContext context) {
  final knobs = context.knobs;
  final title = knobs.string(label: '제목', initialValue: '3월 동아리 정기 모임');
  final owner = knobs.boolean(
    label: '주인',
    description: '모임을 만든 사람에게만 제목 옆에 모임 설정을 여는 연필이 있다',
    initialValue: true,
  );
  final back = knobs.boolean(label: '뒤로 가기', description: '앞 화면이 있을 때');
  // 앱에서는 모임 화면 머리띠의 제목 자리에 놓인다
  return Align(
    alignment: Alignment.topCenter,
    child: MeetingGlassBar(
      title: MeetingPageTitle(title, onEdit: owner ? () {} : null),
      back: back,
      under: false,
    ),
  );
}
