import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_account_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_finish_action.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_layout.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_audience.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_name_chip.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slot_card.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _people = <MeetingSlotPerson>[
  (name: '모모', owner: true, guest: false, self: false),
  (name: '토끼', owner: false, guest: false, self: true),
  (name: '곰돌이', owner: false, guest: true, self: false),
];

@widgetbook.UseCase(name: '모임 화면 배치', type: MeetingLayout, path: '[모임]/화면 틀')
Widget meetingLayout(BuildContext context) {
  final knobs = context.knobs;
  final width = knobs.double.slider(
    label: '화면 폭',
    description: '840부터 격자 오른쪽에 상자를 두는 두 칸 배치가 된다. 카탈로그 화면보다 넓으면 줄여서 보인다',
    initialValue: 360,
    min: 320,
    max: 1440,
    divisions: 28,
    precision: 0,
  );
  final action = knobs.boolean(
    label: '저장하기',
    description: '내 시간을 칠한 뒤에 생긴다. 좁으면 화면 아래 띠, 넓으면 격자 아래 오른쪽',
    initialValue: true,
  );
  final account = MeetingAccountPanel(
    text: 'momo@example.com 계정으로 진행 중입니다',
    onSignOut: () {},
  );
  final link = MeetingPanel(
    title: '링크',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: () {},
                child: const Text('공유하기'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('수정하기'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const MeetingLinkAudience(level: VisibilityLevel.allowedEmails),
      ],
    ),
  );
  final participants = MeetingPanel(
    title: '일정 참여자',
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final person in [..._people, _squirrel])
          MeetingNameChip(
            name: person.name,
            owner: person.owner,
            guest: person.guest,
            self: person.self,
          ),
      ],
    ),
  );
  Widget slots({bool fill = false}) {
    final scheme = Theme.of(context).colorScheme;
    final cards = [
      for (final (title, detail) in const [
        ('3월 2일 (화)', '10:00 ~ 12:00'),
        ('3월 4일 (목)', '14:00 ~ 15:30'),
        ('3월 5일 (금)', '19:00 ~ 21:00'),
      ])
        MeetingSlotCard(
          title: title,
          detail: detail,
          people: _people,
          unavailable: const ['다람쥐'],
          pinned: false,
          onTap: () {},
          onCopy: () {},
          onAddToCalendar: () {},
        ),
    ];
    return MeetingPanel(
      title: '추천 시간',
      color: scheme.primaryContainer,
      foreground: scheme.onPrimaryContainer,
      fill: fill,
      child: fill
          ? ListView.separated(
              itemCount: cards.length,
              itemBuilder: (context, i) => cards[i],
              separatorBuilder: (context, i) => const SizedBox(height: 8),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: cards,
            ),
    );
  }

  final layout = MeetingLayout(
    main: const _GridStandIn(),
    side: [account, link, participants],
    sideFill: slots(fill: true),
    header: account,
    secondary: [slots()],
    tertiary: [participants, link],
    action: action
        ? (pinned) => MeetingFinishAction(
            phase: MeetingFinishPhase.autosaved,
            pinned: pinned,
            onPressed: () {},
          )
        : null,
  );
  return LayoutBuilder(
    builder: (context, constraints) {
      if (width <= constraints.maxWidth) {
        return Center(
          child: SizedBox(width: width, child: layout),
        );
      }
      // 화면보다 넓은 폭은 같은 비율로 줄여 한눈에 보인다
      final scale = constraints.maxWidth / width;
      return FittedBox(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: width,
          height: constraints.maxHeight / scale,
          child: layout,
        ),
      );
    },
  );
}

const MeetingSlotPerson _squirrel = (
  name: '다람쥐',
  owner: false,
  guest: false,
  self: false,
);

/// '내 시간 선택하기'(격자) 자리. 격자는 시간대 자료가 있어야 그려져 카탈로그에서는 자리만 잡는다
class _GridStandIn extends StatelessWidget {
  const _GridStandIn();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '내 시간 선택하기',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 560,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            '시간 격자',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
