import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_glass_bar.dart';

/// 탭 셸 밖 모임 화면(만들기·만든 뒤·모임)의 공용 틀: 유리 머리띠와 그 아래로 지나가는 본문.
///
/// 본문은 머리띠 뒤로 이어지고(본문의 굴림 영역은 위 여백에 `MediaQuery.paddingOf(context).top`을 더한다),
/// 처음에는 머리띠가 비어 보인다. 본문이 머리띠 아래로 굴러가면 머리띠 자리만 흐리게 비치고 바탕색을 옅게 깔며
/// 아래에 가는 선을 긋는다(짧게 바뀌고, 애니메이션을 줄였으면 바로). 왼쪽에는 홈으로 가는 서비스 배지를 두고, 앞 화면이 있으면
/// 그 앞에 뒤로 가기를 둔다.
///
/// 테스트: test/features/meeting/presentation/widgets/meeting_glass_scaffold_test.dart
class MeetingGlassScaffold extends StatefulWidget {
  const MeetingGlassScaffold({
    super.key,
    required this.title,
    required this.body,
  });

  final Widget title;
  final Widget body;

  @override
  State<MeetingGlassScaffold> createState() => _MeetingGlassScaffoldState();
}

class _MeetingGlassScaffoldState extends State<MeetingGlassScaffold> {
  var _under = false;

  /// 본문의 바깥 굴림 영역이 머리띠 아래로 굴러갔는지
  bool _scrolled(ScrollNotification notification) {
    if (notification.depth == 0 && notification.metrics.axis == Axis.vertical) {
      final under = notification.metrics.extentBefore > 0;
      if (under != _under) setState(() => _under = under);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: MeetingGlassBar(
        title: widget.title,
        back: context.canPop(),
        under: _under,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _scrolled,
        child: widget.body,
      ),
    );
  }
}
