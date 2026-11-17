import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 한국어 낱말 안에서 줄이 바뀌지 않게 글자 사이에 단어 잇기 문자(U+2060)를 넣는다. 줄은 띄어쓰기에서만 바뀐다
String keepWords(String text) =>
    text.replaceAllMapped(RegExp(r'(?<=\S)(?=\S)'), (_) => '\u2060');

/// 방식마다 칠하는 단위를 부르는 말: 시간별 '시간', 날짜별 '날', 요일별 '요일'
String _unitOf(MeetingMode mode) => switch (mode) {
  MeetingMode.hourly => '시간',
  MeetingMode.weekly => '요일',
  MeetingMode.daily || MeetingMode.$unknown => '날',
};

/// 고른 붓으로 무엇을 칠하는지 한 줄. 확실한 것만 칠한다
String meetingBrushLine(MeetingAnswer brush, MeetingMode mode) {
  final unit = _unitOf(mode);
  final object = unit.withJosa('을', '를');
  return brush == MeetingAnswer.unavailable
      ? '절대 안 되는 $object 칠해 주세요'
      : '확실히 되는 $object 칠해 주세요';
}

/// 칠하기 도움말(물음표). 그 방식의 말만 쓴다
String meetingBrushHelp(MeetingMode mode, {required bool touch}) => [
  touch
      ? '칸을 누르면 칠하거나 지워요. 길게 누른 채 끌면 여러 칸을 한 번에 칠해요.'
      : '칸을 누르거나 누른 채 끌어서 여러 칸을 칠해요.',
  '이미 고른 붓으로 칠한 칸에서 시작하면 그 칸들을 지워요.',
  if (mode == MeetingMode.hourly)
    '날짜를 누르면 빈 날은 하루 전체를 되는 시간으로 칠하고, 표시한 날은 초기화해요.',
  '칠하면 바로 저장돼요.',
].join(' ');

/// 시간별 날짜 머리로 그날을 지운 뒤의 알림
String meetingDayResetDone(DateTime day) =>
    '${day.month}/${day.day} 일정을 초기화했어요';
