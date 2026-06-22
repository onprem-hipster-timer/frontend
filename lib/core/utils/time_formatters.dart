/// 범용 시간/기간 포맷터
///
/// timer·calendar 등 여러 feature가 공유하는 표시용 포맷 함수들입니다.
library;

/// Duration을 HH:MM:SS 형식의 문자열로 변환
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

/// DateTime을 HH:MM 형식으로 변환 (시간 표시용)
String formatTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
