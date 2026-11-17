import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_reveal_step.dart';

/// 모임 만들기 폼의 배치. 넓으면 날짜를 왼쪽, 나머지를 오른쪽 칸에 두고, 좁으면 같은 순서로 위에서 아래로 쌓는다.
///
/// 단계는 쉬운 것부터 차례로 나타난다(날짜 → 시간 → 공개·게스트 → 제목). [revealed]는 보이는 단계 수(1~4)이고,
/// 나타난 단계는 사라지지 않는다. [animate]면 새로 나타나는 단계가 펼쳐지며 보이게 굴린다([MeetingRevealStep])
class MeetingCreateLayout extends StatelessWidget {
  const MeetingCreateLayout({
    super.key,
    required this.dates,
    required this.time,
    required this.sharing,
    required this.title,
    required this.revealed,
    required this.animate,
  });

  /// 이 폭부터 두 칸
  static const twoColumnsFrom = 720.0;

  final Widget dates;
  final Widget time;
  final Widget sharing;
  final Widget title;

  /// 보이는 단계 수(1: 날짜만 ~ 4: 제목까지)
  final int revealed;

  /// 새로 나타나는 단계를 펼치며 보일지(되살린 폼처럼 처음부터 보이면 false)
  final bool animate;

  static const _announcements = [
    '모임 시간을 정해 주세요',
    '공개 여부와 게스트 로그인을 정해 주세요',
    '제목을 짓고 화살표를 눌러 주세요',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= twoColumnsFrom;
        Widget step(int index, Widget child, double gap) => MeetingRevealStep(
          key: ValueKey(index),
          animate: animate,
          announcement: _announcements[index],
          child: Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : gap),
            child: child,
          ),
        );
        final settings = [
          if (revealed > 1) step(0, time, 0),
          if (revealed > 2) step(1, sharing, 24),
          if (revealed > 3) step(2, title, 28),
        ];
        return SingleChildScrollView(
          padding: EdgeInsets.all(
            wide ? 32 : 16,
          ).add(EdgeInsets.only(top: MediaQuery.paddingOf(context).top)),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: wide
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: dates),
                            const SizedBox(width: 40),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: settings,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        dates,
                        if (settings.isNotEmpty) const SizedBox(height: 24),
                        ...settings,
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
