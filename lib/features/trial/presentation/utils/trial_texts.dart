import 'package:momeet/features/trial/domain/trial_flow.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 체험하기의 문구와 견본 일정의 글

const trialTitle = '체험하기';

/// 체험하기를 보는 동안의 브라우저 탭 제목. web/demo.html의 <title>과 같다
const trialDocumentTitle = '가입 없이 체험하기 | 모모밋';
const trialSkip = '건너뛰기';

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
const trialTimerLead = '이 시간에는 이 일 하나만 하면 돼요.';
const trialEndLead = '앱 세 개를 오가던 일이 한곳에서 이어졌어요.';

const trialSignUp = '가입하고 내 일정으로 시작하기';
const trialMeetingLead = '친구와 만날 날짜는 링크 하나로 같이 정해 보세요.';
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

/// [flow]에서 스크린 리더에 알리는 글: 앞 줄과 큰 한 줄
String trialAnnouncement(TrialFlow flow) =>
    '${trialLead(flow)} ${trialHeadline(flow)}';
