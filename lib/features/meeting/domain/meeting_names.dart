/// 참여자 이름의 최대 길이. backend처럼 유니코드 코드 포인트로 센다
const meetingNameMaxLength = 50;

/// 계정 이름이 없을 때 참여하는 이름
const meetingDefaultName = '참여자';

/// 유니코드 제어 문자(Cc). backend가 참여자 이름에서 받지 않는다
final _control = RegExp('[\u0000-\u001f\u007f-\u009f]');

/// 처음 칠할 때 참여하는 이름. 계정 이름의 제어 문자를 공백으로 바꾸고 앞뒤 공백을 뺀 앞 50자, 비면 [meetingDefaultName]
String meetingDisplayName(String? accountName) {
  final name = (accountName ?? '').replaceAll(_control, ' ').trim();
  if (name.isEmpty) return meetingDefaultName;
  final runes = name.runes;
  if (runes.length <= meetingNameMaxLength) return name;
  return String.fromCharCodes(runes.take(meetingNameMaxLength)).trimRight();
}

/// 참여자 이름 입력의 오류 문구. 쓸 수 있으면 null
String? meetingNameError(String input) {
  final name = input.trim();
  if (name.isEmpty) return '닉네임을 입력해 주세요';
  if (_control.hasMatch(name)) return '줄바꿈이나 탭은 쓸 수 없습니다';
  if (name.runes.length > meetingNameMaxLength) {
    return '닉네임은 $meetingNameMaxLength자까지 쓸 수 있습니다';
  }
  return null;
}
