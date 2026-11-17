import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 한국어 낱말 안에서 줄이 바뀌지 않게 글자 사이에 단어 잇기 문자(U+2060)를 넣는다. 줄은 띄어쓰기에서만 바뀐다
String keepWords(String text) =>
    text.replaceAllMapped(RegExp(r'(?<=\S)(?=\S)'), (_) => '\u2060');

/// 방식마다 칠하는 단위를 부르는 말: 시간별 '시간', 날짜별 '날', 요일별 '요일'
String _unitOf(MeetingMode mode) => switch (mode) {
  MeetingMode.hourly => '시간',
  MeetingMode.weekly => '요일',
  MeetingMode.daily || MeetingMode.$unknown => '날',
};

/// 고른 붓으로 무엇을 칠하는지 한 줄. 시간별은 하루마다, 날짜별·요일별은 모임 전체가 한 방식이다
String meetingBrushLine(MeetingAnswer brush, MeetingMode mode) {
  final unit = _unitOf(mode);
  final rest = mode == MeetingMode.hourly ? '그날 나머지는' : '나머지는 모두';
  return brush == MeetingAnswer.unavailable
      ? '안 되는 $unit만 칠해 주세요. $rest 되는 걸로 볼게요.'
      : '되는 $unit만 칠해 주세요. $rest 안 되는 걸로 볼게요.';
}

/// 칠하기 도움말(물음표). 그 방식의 말만 쓴다
String meetingBrushHelp(MeetingMode mode, {required bool touch}) {
  final hourly = mode == MeetingMode.hourly;
  final unit = _unitOf(mode);
  return [
    touch
        ? '칸을 누르면 칠하거나 지워요. 길게 누른 채 끌면 여러 칸을 한 번에 칠해요.'
        : '칸을 누르거나 누른 채 끌어서 여러 칸을 칠해요.',
    hourly
        ? '날마다 되는 시간이나 안 되는 시간 중 한 가지로 표시해요. 날마다 다르게 표시할 수 있어요.'
        : '되는 $unit이나 안 되는 $unit 중 한 가지로 표시해요.',
    '이미 고른 붓으로 칠한 칸에서 시작하면 그 칸들을 되돌려요.',
    hourly
        ? '날짜를 누르면 빈 날은 하루 전체를 되는 시간으로 칠하고, 표시한 날은 초기화해요.'
        : "다른 쪽으로 바꾸려면 '일정 초기화하기'로 초기화해요.",
    '칠하면 바로 저장돼요.',
  ].join(' ');
}

/// 다른 방식으로 표시한 묶음에 [brush]로 칠하려 했을 때의 알림: 그 방식의 규칙과 지금 표시, 초기화 단추, 초기화
/// 전에 묻는 말([meetingResetQuestion]). 시간별은 막힌 날들([days], 붓질 순서)을 부른다
({String message, String action, String question}) meetingBlockedText(
  MeetingAnswer brush,
  MeetingMode mode,
  List<DateTime> days,
) {
  final unit = _unitOf(mode);
  final marked = brush == MeetingAnswer.unavailable ? '되는' : '안 되는';
  final question = meetingResetQuestion(mode, days);
  if (mode != MeetingMode.hourly) {
    return (
      message:
          '이 모임은 되는 $unit이나 안 되는 $unit 중 한 가지로만 표시할 수 있어요. '
          '지금은 $marked $unit로 표시 중이에요.',
      action: '일정 초기화하기',
      question: question,
    );
  }
  return (
    message:
        '하루는 되는 시간이나 안 되는 시간 중 한 가지로만 표시할 수 있어요. '
        '${_daysName(days)}은 $marked 시간으로 표시 중이에요.',
    action: '${_daysLabel(days)} 일정 초기화하기',
    question: question,
  );
}

/// 초기화하기 전에 묻는 말: 시간별은 그날([days])에 표시한 시간, 날짜별·요일별은 모임에 표시한 날·요일
String meetingResetQuestion(MeetingMode mode, List<DateTime> days) =>
    mode == MeetingMode.hourly
    ? '${_daysName(days)}에 표시한 시간을 모두 지울까요?'
    : '이 모임에 표시한 ${_unitOf(mode)}을 모두 지울까요?';

/// 시간별 날짜 머리로 그날을 지운 뒤의 알림
String meetingDayResetDone(DateTime day) =>
    '${day.month}/${day.day} 일정을 초기화했어요';

/// '11월 23일', 여럿이면 '11월 23일 외 2일'
String _daysName(List<DateTime> days) {
  final first = days.first;
  final others = days.length - 1;
  return '${first.month}월 ${first.day}일${others == 0 ? '' : ' 외 $others일'}';
}

/// 단추에 쓰는 '11/23', 여럿이면 '3일'
String _daysLabel(List<DateTime> days) => days.length == 1
    ? '${days.first.month}/${days.first.day}'
    : '${days.length}일';
