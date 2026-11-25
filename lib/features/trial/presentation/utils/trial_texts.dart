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

const trialCalendarHeadline = '달력에 시험이 잡혀 있어요';
const trialCalendarGuide = '시험 날짜를 눌러 열어 보세요.';

final trialScheduleHeadline = '이 시험을 ${Terms.todo.withJosa('으로', '로')} 바꿔 보세요';
final trialScheduleGuide =
    "'${Terms.todo.withJosa('으로', '로')} 변환'을 누르면 일정이 ${Terms.todo.withJosa('과', '와')} 이어져요.";

final trialTodoHeadline = '${Terms.todo.withJosa('이', '가')} 생겼어요';
const trialTodoGuide = '재생 버튼을 눌러 ${Terms.focus}을 시작해 보세요.';

const trialTimerHeadline = '${Terms.focus}한 시간이 기록돼요';

/// [allocated]는 시작한 타이머의 정한 시간
String trialTimerGuide(Duration allocated) =>
    '체험에서는 ${allocated.inMinutes}분이 ${trialTimerSweep.inSeconds}초 만에 지나가요.';

final trialEndHeadline =
    '달력의 한 줄이 ${Terms.todo.withJosa('이', '가')} 되고, ${Terms.focus}한 시간으로 남았어요';
const trialSignUp = '가입하고 내 일정으로 시작하기';
const trialMeetingLead = '민지와의 약속은 날짜가 아직 대충이죠. 링크 하나로 같이 정해 보세요.';
const trialMeetingAction = '${Terms.meeting} 만들기';

const trialExamTitle = '토익 시험';
const trialExamDescription = '수험표와 신분증 챙기기';
const trialExamTag = '공부';
const trialDinnerTitle = '민지랑 저녁';
const trialDinnerDescription = '이번 주쯤, 날짜는 같이 정하기';
const trialDinnerTag = '친구';
