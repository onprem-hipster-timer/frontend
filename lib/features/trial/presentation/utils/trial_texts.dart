import 'package:momeet/features/trial/domain/trial_flow.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 체험하기의 문구와 견본 일정의 글

const trialTitle = '체험하기';
const trialSkip = '건너뛰기';

/// 단계 표시('1/4'). 끝에는 두지 않는다
String trialStepLabel(int number) => '$number/$trialStepCount';

/// 스크린 리더가 읽는 단계 표시
String trialStepSemantics(int number) => '$trialStepCount단계 중 $number단계';

/// 끝을 뺀 단계 수
const trialStepCount = 4;

// 단계마다 한 줄: 다음에 누를 것. 누를 것이 없는 타이머는 화면에 보이는 것을, 끝은 얻은 것을 말한다

const trialCalendarHeadline = '달력에서 $trialExamTitle 시험을 눌러 보세요';
final trialScheduleHeadline = "'${Terms.todo.withJosa('으로', '로')} 변환'을 눌러 보세요";

/// 할 일로 바꾼 뒤. 변환 단추가 바뀐 단추를 가리킨다
const trialConvertedHeadline = "'연결된 ${Terms.todo} 보기'를 눌러 보세요";
final trialTodoHeadline = '재생 버튼을 눌러 ${Terms.timer.withJosa('을', '를')} 시작해 보세요';

/// 타이머를 시작한 뒤. 할 일 줄의 남은 시간을 가리킨다
const trialStartedHeadline = '남은 시간을 눌러 보세요';
final trialTimerHeadline =
    '${Terms.timer.withJosa('이', '가')} ${Terms.focus}한 시간을 재요';
final trialEndHeadline =
    '일정이 ${Terms.todo.withJosa('이', '가')} 되고, ${Terms.focus}한 흔적이 남았어요';
const trialSignUp = '가입하고 내 일정으로 시작하기';
const trialMeetingLead = '친구와 만날 날짜는 링크 하나로 같이 정해 보세요.';
const trialMeetingAction = '${Terms.meeting} 만들기';

const trialExamTitle = '토익';
const trialExamDescription = '수험표 출력하기';
const trialExamTag = '공부';
const trialDinnerTitle = '민지랑 저녁';
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
