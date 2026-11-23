import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/mypage/presentation/widgets/my_meeting_tile.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _modes = {
  '시간별': MeetingMode.hourly,
  '날짜별': MeetingMode.daily,
  '요일별': MeetingMode.weekly,
};

const _visibility = {
  '공개': VisibilityLevel.public,
  '비공개': VisibilityLevel.private,
  '표시 없음': null,
};

@widgetbook.UseCase(name: '내 모임 항목', type: MyMeetingTile, path: '[마이페이지]')
Widget myMeetingTile(BuildContext context) {
  final knobs = context.knobs;
  final title = knobs.string(label: '제목', initialValue: '3월 동아리 정기 모임');
  final mode = knobs.object.dropdown(
    label: '받는 방식',
    options: _modes.keys.toList(),
  );
  final days = knobs.int.slider(
    label: '기간(일)',
    description: '하루면 날짜 하나만, 여러 날이면 첫날–끝날로 쓴다',
    initialValue: 5,
    min: 1,
    max: 14,
  );
  final visibility = knobs.object.dropdown(
    label: '공개 여부',
    description: '공개는 지구 모양, 그 밖의 공개 범위는 모두 자물쇠와 비공개로 보인다',
    options: _visibility.keys.toList(),
  );
  final start = DateTime(2026, 3, 2);
  final meeting = MeetingRead(
    id: 'sample',
    title: title,
    startDate: start,
    endDate: start.add(Duration(days: days - 1)),
    excludedDates: const [],
    timezone: 'Asia/Seoul',
    mode: _modes[mode]!,
    startTime: '09:00',
    endTime: '18:00',
    timeSlotMinutes: 30,
    createdAt: start,
    updatedAt: start,
    visibilityLevel: _visibility[visibility],
  );
  // 앱에서는 '내 모임' 카드 안에 이 줄이 구분선을 두고 이어진다. 누르면 모임 화면으로 가는데 카탈로그에는 화면 이동이 없다
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: MyMeetingTile(meeting: meeting),
    ),
  );
}
