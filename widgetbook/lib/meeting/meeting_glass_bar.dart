import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_glass_bar.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_page_title.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '모임 화면 상단 바',
  type: MeetingGlassBar,
  path: '[모임]/화면 틀',
)
Widget meetingGlassBar(BuildContext context) {
  final knobs = context.knobs;
  final title = knobs.string(label: '제목', initialValue: '동아리 정기 모임');
  final owner = knobs.boolean(
    label: '모임 주인',
    description: '주인에게는 제목 옆에 모임 설정을 여는 연필이 있다',
    initialValue: true,
  );
  final back = knobs.boolean(
    label: '뒤로 가기',
    description: '앞 화면이 있을 때(예: 달력에서 모임을 연 경우) 배지 앞에 생긴다',
  );
  final under = knobs.boolean(
    label: '본문이 아래로 지나감',
    description: '본문을 굴려 바 아래로 지나가면 그 자리를 흐리게 비추고 바탕색을 옅게 깐다',
    initialValue: true,
  );
  final scheme = Theme.of(context).colorScheme;
  // 바 뒤로 비치는 모습을 보도록 본문을 바 아래부터 채운다
  return Scaffold(
    extendBodyBehindAppBar: true,
    appBar: MeetingGlassBar(
      title: MeetingPageTitle(title, onEdit: owner ? () {} : null),
      back: back,
      under: under,
    ),
    body: ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        under ? 16 : kToolbarHeight + 16,
        16,
        16,
      ),
      children: [
        for (var i = 0; i < 12; i++)
          Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: i.isEven ? scheme.primary : scheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
      ],
    ),
  );
}
