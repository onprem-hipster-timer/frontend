import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_create_layout.dart';

/// 모임 만들기 질문 화면의 틀(질문 하나를 묻는 동안의 폭)에 [child]를 놓는다
Widget meetingCreateFrame(Widget child) =>
    MeetingCreateLayout(maxWidth: 640, builder: (context, wide) => child);

/// 기기 설정의 '애니메이션 줄이기'를 [reduce]로 바꿔 [child]를 그린다
Widget meetingMotionSetting(
  BuildContext context, {
  required bool reduce,
  required Widget child,
}) => MediaQuery(
  data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
  child: child,
);

/// '애니메이션 줄이기' 노브의 설명
const meetingReduceMotionDescription = '기기 설정에서 애니메이션을 줄이면 움직이지 않고 바로 바뀐다';

/// 움직임을 다시 보는 버튼과 그 아래의 미리보기. [builder]는 버튼을 누른 횟수를 받는다
class MeetingReplay extends StatefulWidget {
  const MeetingReplay({super.key, required this.label, required this.builder});

  final String label;
  final Widget Function(BuildContext context, int count) builder;

  @override
  State<MeetingReplay> createState() => _MeetingReplayState();
}

class _MeetingReplayState extends State<MeetingReplay> {
  var _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _count++),
            icon: const Icon(Icons.replay),
            label: Text(widget.label),
          ),
        ),
        const SizedBox(height: 16),
        widget.builder(context, _count),
      ],
    );
  }
}
