import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_section_title.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

typedef _Title = ({String title, String? caption, String? help, bool emphasis});

/// 전체 설정 폼의 소제목들
final _titles = <String, _Title>{
  '모임 날짜': (
    title: meetingFormDatesTitle,
    caption: meetingRangeGuide,
    help: null,
    emphasis: false,
  ),
  '모임 날짜 (끝나는 날 고르는 중)': (
    title: meetingFormDatesTitle,
    caption: meetingRangeStartedHint(DateTime(2027, 3, 2)),
    help: null,
    emphasis: true,
  ),
  '모임 시간': (
    title: '${Terms.meeting} 시간',
    caption: '최대 범위 설정',
    help:
        '참여자가 가능한 시간을 고를 범위입니다. '
        '시간별은 $hourlyMaxDays일 이하 날짜의 하루 시간 범위를, 날짜별은 날짜만, '
        '요일별은 한 주의 요일만 받습니다.',
    emphasis: false,
  ),
  '공개 여부': (
    title: '공개 여부',
    caption: null,
    help:
        '허용하면 링크가 있는 누구나 이 ${Terms.meeting.withJosa('을', '를')} 볼 수 있습니다. '
        '비허용이면 나만 볼 수 있습니다.',
    emphasis: false,
  ),
  '게스트 로그인': (
    title: '게스트 로그인',
    caption: null,
    help:
        '허용하면 회원이 아니어도 닉네임과 비밀번호로 참여할 수 있습니다. '
        '공개 ${Terms.meeting}에서만 허용할 수 있습니다.',
    emphasis: false,
  ),
};

@widgetbook.UseCase(
  name: '설정 소제목',
  type: MeetingSectionTitle,
  path: '[모임]/모임 만들기',
)
Widget meetingSectionTitle(BuildContext context) {
  final which = context.knobs.object.dropdown(
    label: '소제목',
    description: '끝나는 날 고르는 중: 모임 날짜에서 시작일을 누른 뒤 설명을 강조한다',
    options: _titles.keys.toList(),
    initialOption: '모임 시간',
  );
  final title = _titles[which]!;
  // 앱에서는 전체 설정 폼 안 왼쪽에 붙는다
  return Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: MeetingSectionTitle(
        title.title,
        caption: title.caption,
        help: title.help,
        captionEmphasis: title.emphasis,
      ),
    ),
  );
}
