import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_access.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 카탈로그의 '오늘'. 날짜가 고정이어야 달력·요약 문구가 늘 같게 보인다
final meetingSampleToday = DateTime.utc(2027, 3, 2);

/// 2027년 3월 [day]일
DateTime meetingSampleDay(int day) => DateTime.utc(2027, 3, day);

/// 비공개 모임에 넣어 둔 예시 이메일·도메인
const meetingSampleAccess = [
  'momo@example.com',
  'tokki@example.com',
  'example.org',
];

/// 질문의 화면 이름(모임 만들기 요약의 이름과 같다)
const meetingQuestionNames = {
  MeetingQuestion.range: '기간',
  MeetingQuestion.exclusions: '제외',
  MeetingQuestion.mode: '받는 방식',
  MeetingQuestion.time: '시간',
  MeetingQuestion.visibility: '공개 여부',
  MeetingQuestion.guests: '게스트',
  MeetingQuestion.access: '참여할 사람',
  MeetingQuestion.title: '제목',
};

/// [question]을 묻는 차례까지 앞 질문에 답한 모임 만들기 흐름: 3월 8일~12일, 시간별 6~18시, 공개·게스트
/// 허용. [private]이면 비공개에 예시 이메일·도메인을, [excluded]면 3월 10일을 뺀다
MeetingFlow meetingFlowAt(
  MeetingQuestion question, {
  bool private = false,
  bool excluded = false,
}) {
  var flow = const MeetingFlow();
  if (question == MeetingQuestion.range) return flow;
  flow = flow.tapDay(meetingSampleDay(8)).tapDay(meetingSampleDay(12));
  if (question == MeetingQuestion.exclusions) return flow;
  flow = excluded
      ? flow.tapDay(meetingSampleDay(10)).confirmExclusions()
      : flow.skipExclusions();
  if (question == MeetingQuestion.mode) return flow;
  flow = flow.chooseMode(MeetingMode.hourly);
  if (question == MeetingQuestion.time) return flow;
  flow = flow.acceptDefaultHours();
  if (question == MeetingQuestion.visibility) return flow;
  final closed =
      question == MeetingQuestion.access ||
      (private && question != MeetingQuestion.guests);
  if (closed) {
    flow = flow.choosePublic(false);
    if (question == MeetingQuestion.access) return flow;
    flow = meetingSampleAccess
        .map(parseMeetingAccessEntry)
        .nonNulls
        .fold(flow, (flow, entry) => flow.addAccessEntry(entry))
        .confirmAccess();
  } else {
    flow = flow.choosePublic(true);
    if (question == MeetingQuestion.guests) return flow;
    flow = flow.chooseGuests(true);
  }
  return flow;
}

/// 답을 누르면 다음 질문으로 넘어가도록 흐름과 제목 칸을 쥔다. 노브를 바꿔 처음부터 다시 보이려면 부르는
/// 쪽이 [key]를 바꾼다
class MeetingFlowHost extends StatefulWidget {
  const MeetingFlowHost({
    super.key,
    required this.initial,
    required this.builder,
  });

  final MeetingFlow initial;
  final Widget Function(
    BuildContext context,
    MeetingFlow flow,
    ValueChanged<MeetingFlow> onChanged,
    TextEditingController title,
  )
  builder;

  @override
  State<MeetingFlowHost> createState() => _MeetingFlowHostState();
}

class _MeetingFlowHostState extends State<MeetingFlowHost> {
  late var _flow = widget.initial;
  final _title = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    _flow,
    (flow) => setState(() => _flow = flow),
    _title,
  );
}

/// 화면 폭 노브의 선택지. null은 미리보기 기기 폭 그대로다
const meetingWidthOptions = <String, double?>{
  '기기 폭 그대로': null,
  '720 (넓은 배치가 시작하는 폭)': 720,
  '1024 (태블릿·노트북)': 1024,
};

/// [width]가 있으면 그 폭으로 그리고, 기기보다 넓으면 옆으로 굴린다
class MeetingWidthFrame extends StatelessWidget {
  const MeetingWidthFrame({
    super.key,
    required this.width,
    required this.child,
  });

  final double? width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = this.width;
    if (width == null) return child;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          height: constraints.maxHeight,
          child: child,
        ),
      ),
    );
  }
}
