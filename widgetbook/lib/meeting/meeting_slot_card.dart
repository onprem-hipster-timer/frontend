import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slot_card.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _people = <MeetingSlotPerson>[
  (name: '모모', owner: true, guest: false, self: false),
  (name: '토끼', owner: false, guest: false, self: true),
  (name: '곰돌이', owner: false, guest: true, self: false),
];

const _longPeople = <MeetingSlotPerson>[
  (name: '모임 시간을 누구보다 먼저 맞추는 모모', owner: true, guest: false, self: false),
  (name: '닉네임이 아주 길어서 한 줄을 넘기는 토끼', owner: false, guest: false, self: true),
  (name: '게스트로 들어온 이름 긴 곰돌이 손님', owner: false, guest: true, self: false),
];

@widgetbook.UseCase(name: '추천 시간 카드', type: MeetingSlotCard, path: '[모임]/추천 시간')
Widget meetingSlotCard(BuildContext context) {
  final knobs = context.knobs;
  final title = knobs.string(label: '날짜', initialValue: '3월 2일 (화)');
  final detail = knobs.string(label: '시각', initialValue: '10:00 ~ 12:00');
  final pinned = knobs.boolean(
    label: '고정',
    description: '카드를 눌러 이름을 카드 안에 둔 상태. 고정하지 않으면 마우스를 올릴 때 이름이 카드 아래에 뜬다',
  );
  final unavailable = knobs.boolean(label: '안 되는 사람 있음', initialValue: true);
  final calendar = knobs.boolean(label: '내 달력에 넣기', initialValue: true);
  final long = knobs.boolean(label: '긴 이름');
  final width = knobs.double.slider(
    label: '카드 폭',
    description:
        '260보다 좁으면 펼침 표시와 버튼이 시각 아래 줄로 내려가고, 넓으면 \'내 달력에 넣기\'만 맨 아래 줄에 선다. '
        '좁은데 한 줄에 안 들어가면 \'내 달력에 넣기\'를 아래 줄로 내린다',
    initialValue: 328,
    min: 192,
    max: 480,
    divisions: 36,
    precision: 0,
  );
  // 앱에서는 '추천 시간' 상자의 primaryContainer 바탕 위, 높이 제한 없는 줄에 놓여 내용 높이만큼이다
  return ColoredBox(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: width,
          child: MeetingSlotCard(
            title: title,
            detail: detail,
            people: long ? _longPeople : _people,
            unavailable: [if (unavailable) long ? '오늘은 하루 종일 바쁜 다람쥐' : '다람쥐'],
            pinned: pinned,
            onTap: () {},
            onCopy: () {},
            onAddToCalendar: calendar ? () {} : null,
          ),
        ),
      ),
    ),
  );
}
