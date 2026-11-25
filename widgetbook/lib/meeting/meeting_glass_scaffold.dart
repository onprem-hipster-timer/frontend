import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_glass_scaffold.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_page_title.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _slots = [
  ('3월 2일 (월)', '10:00 ~ 12:00', '5명 모두 가능'),
  ('3월 3일 (화)', '14:00 ~ 16:00', '4명 가능'),
  ('3월 4일 (수)', '19:00 ~ 21:00', '4명 가능'),
  ('3월 5일 (목)', '09:00 ~ 10:30', '3명 가능'),
  ('3월 6일 (금)', '18:00 ~ 20:00', '3명 가능'),
  ('3월 9일 (월)', '13:00 ~ 15:00', '3명 가능'),
  ('3월 10일 (화)', '10:00 ~ 11:00', '2명 가능'),
  ('3월 11일 (수)', '16:00 ~ 18:00', '2명 가능'),
];

@widgetbook.UseCase(
  name: '모임 화면 틀',
  type: MeetingGlassScaffold,
  path: '[모임]/화면 틀',
)
Widget meetingGlassScaffold(BuildContext context) {
  final knobs = context.knobs;
  final title = knobs.string(label: '제목', initialValue: '3월 동아리 정기 모임');
  final owner = knobs.boolean(
    label: '모임 주인',
    description: '주인에게는 제목 옆에 모임 설정을 여는 연필이 있다',
    initialValue: true,
  );
  final count = knobs.int.slider(
    label: '본문 길이',
    description: '본문을 굴려 머리띠 아래로 지나가게 하면 머리띠가 흐려지고 아래에 선이 생긴다. 짧으면 굴러가지 않는다',
    initialValue: _slots.length,
    min: 1,
    max: _slots.length,
  );
  // 앱에서는 모임·만들기·만든 뒤 화면 전체를 감싼다. 본문은 머리띠 뒤에서 시작하므로 위 여백에 머리띠 높이를 더한다
  return MeetingGlassScaffold(
    title: MeetingPageTitle(title, onEdit: owner ? () {} : null),
    body: Builder(
      builder: (context) => ListView(
        padding: const EdgeInsets.all(
          16,
        ).add(EdgeInsets.only(top: MediaQuery.paddingOf(context).top)),
        children: [
          for (final (day, time, people) in _slots.take(count))
            Card(
              child: ListTile(
                title: Text(day),
                subtitle: Text(time),
                trailing: Text(people),
              ),
            ),
        ],
      ),
    ),
  );
}
