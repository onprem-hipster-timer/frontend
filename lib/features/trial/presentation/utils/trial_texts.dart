import 'package:momeet/features/trial/domain/trial_flow.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 체험하기의 문구와 견본 일정의 글

const trialTitle = '체험하기';

/// 체험하기를 보는 동안의 브라우저 탭 제목. web/demo.html의 <title>과 같다
const trialDocumentTitle = '가입 없이 체험하기 | 모모밋';
const trialSkip = '건너뛰기';

/// 견본 모임 화면 그림을 스크린 리더가 읽는 한 줄
const trialMeetingPreviewLabel = '친구들이 되는 시간을 칠한 ${Terms.meeting} 화면';

/// 단계 표시('1/4'). 끝에는 두지 않는다
String trialStepLabel(int number) => '$number/$trialStepCount';

/// 스크린 리더가 읽는 단계 표시
String trialStepSemantics(int number) => '$trialStepCount단계 중 $number단계';

/// 끝을 뺀 단계 수
const trialStepCount = 4;

// 단계마다 큰 한 줄: 다음에 누를 것. 누를 것이 없는 타이머는 화면에 보이는 것을, 끝은 얻은 것을 말한다.
// 그 위의 앞 줄([trialLead])은 그 단계가 덜어 주는 하루의 번거로움이나 얻는 것을 말한다. 끝의 마침표까지 쓴다

const trialCalendarHeadline = '달력에서 $trialExamTitle을 눌러 보세요';
final trialScheduleHeadline = "'${Terms.todo.withJosa('으로', '로')} 변환'을 눌러 보세요";

/// 할 일로 바꾼 뒤. 변환 단추가 바뀐 단추를 가리킨다
const trialConvertedHeadline = "'연결된 ${Terms.todo} 보기'를 눌러 보세요";
final trialTodoHeadline = '재생 버튼을 눌러 ${Terms.timer.withJosa('을', '를')} 시작해 보세요';

/// 타이머를 시작한 뒤. 할 일 줄의 남은 시간을 가리킨다
const trialStartedHeadline = '남은 시간을 눌러 보세요';
final trialTimerHeadline =
    '얼마나 ${Terms.focus}했는지는 ${Terms.timer.withJosa('이', '가')} 재요';
final trialEndHeadline =
    '일정이 ${Terms.todo.withJosa('이', '가')} 되고, ${Terms.focus}한 흔적이 남았어요';

const trialCalendarLead = '시험 날짜만 적어 두면 준비는 자꾸 밀려요.';
const trialScheduleLead = '달력에 적은 일을 또 옮겨 적지 않아도 돼요.';

/// 할 일로 바꾼 뒤
const trialConvertedLead = '이제 시험은 날짜가 아니라 준비할 일이에요.';
final trialTodoLead = '${Terms.todo.withJosa('을', '를')} 정해 놓고도 시작이 제일 어렵죠.';

/// 타이머를 시작한 뒤
const trialStartedLead = '시작이 반이라죠. 방금 그 반을 했어요.';

/// 타이머를 시작한 뒤 큰 한 줄 아래
final trialStartedGuide =
    '이 ${Terms.timer.withJosa('은', '는')} 다른 기기에서도 실시간으로 같이 흘러요. 곧 친구에게도 보여 줄 수 있어요.';
const trialTimerLead = '이 시간에는 이 일 하나만 하면 돼요.';
const trialEndLead = '앱 세 개를 오가던 일이 한곳에서 이어졌어요.';

const trialSignUp = '가입하고 내 일정으로 시작하기';

/// 끝에서 가입하기 아래의 물음. 누르면 그 답([trialMeetingLead])과 모임 만들기가 펼쳐진다
const trialMeetingQuestion = '$trialDinnerTitle 날짜는 아직 못 정했는데요?';
const trialMeetingLead = "'언제 돼?'를 주고받는 대신, 링크 하나로 다 같이 되는 날을 찾아요.";
const trialMeetingAction = '${Terms.meeting} 만들기';

const trialExamTitle = '어학 시험';
const trialExamDescription = '수험표 출력하기';
const trialExamTag = '공부';
const trialDinnerTitle = '길동이랑 저녁';
const trialDinnerDescription = '이번 주쯤, 날짜는 같이 정하기';
const trialDinnerTag = '친구';

/// [flow]의 한 줄
String trialHeadline(TrialFlow flow) => switch (flow.step) {
  TrialStep.calendar => trialCalendarHeadline,
  TrialStep.schedule =>
    flow.todo == null ? trialScheduleHeadline : trialConvertedHeadline,
  TrialStep.todo =>
    flow.timer == null ? trialTodoHeadline : trialStartedHeadline,
  TrialStep.timer => trialTimerHeadline,
  TrialStep.end => trialEndHeadline,
};

/// [flow]의 앞 줄
String trialLead(TrialFlow flow) => switch (flow.step) {
  TrialStep.calendar => trialCalendarLead,
  TrialStep.schedule =>
    flow.todo == null ? trialScheduleLead : trialConvertedLead,
  TrialStep.todo => flow.timer == null ? trialTodoLead : trialStartedLead,
  TrialStep.timer => trialTimerLead,
  TrialStep.end => trialEndLead,
};

/// [flow]의 앞 줄이 방금 누른 것으로 얻은 것을 말하는 보상 줄인가: 할 일로 바꾼 뒤, 타이머를 시작한 뒤, 끝
bool trialLeadRewards(TrialFlow flow) => switch (flow.step) {
  TrialStep.schedule => flow.todo != null,
  TrialStep.todo => flow.timer != null,
  TrialStep.end => true,
  TrialStep.calendar || TrialStep.timer => false,
};

/// [flow]의 큰 한 줄 아래 안내. 타이머를 시작한 뒤에만 있다
String? trialGuide(TrialFlow flow) =>
    flow.step == TrialStep.todo && flow.timer != null
    ? trialStartedGuide
    : null;

/// [flow]에서 스크린 리더에 알리는 글: 앞 줄, 큰 한 줄, (있으면) 안내
String trialAnnouncement(TrialFlow flow) {
  final shown = '${trialLead(flow)} ${trialHeadline(flow)}';
  final guide = trialGuide(flow);
  return guide == null ? shown : '$shown. $guide';
}
