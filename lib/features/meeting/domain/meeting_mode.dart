/// 시간별의 날짜 수 상한(일). 넘으면 시간 격자가 화면에 들어가지 않는다
const hourlyMaxDays = 5;

/// 요일별의 기간(일)
const weeklyDays = 7;

/// [hour]시 정각의 backend 시각 문자열. 24시는 하루의 끝인 00:00이다
String clockOf(int hour) => '${(hour % 24).toString().padLeft(2, '0')}:00:00';
