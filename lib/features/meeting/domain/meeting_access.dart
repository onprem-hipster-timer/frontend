/// 비공개 모임을 열 수 있게 정한 이메일 하나 또는 도메인 하나. [domain]이면 그 도메인의 이메일로 로그인한 사람이다
typedef MeetingAccessEntry = ({String value, bool domain});

const _label = '[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?';
const _domain = '(?:$_label\\.)+[a-z]{2,63}';

final _emailPattern = RegExp('^[^\\s@/]+@$_domain\$');
final _domainPattern = RegExp('^$_domain\$');

/// [input]을 이메일이나 도메인으로 읽는다. 앞뒤 공백을 떼고 소문자로 맞추며, 도메인 앞의 '@'는 뗀다(같은 이메일은
/// 대소문자와 상관없이 같은 값이 된다). 형식이 아니면 null
///
/// 테스트: test/features/meeting/domain/meeting_access_test.dart
MeetingAccessEntry? parseMeetingAccessEntry(String input) {
  final text = input.trim().toLowerCase();
  if (_emailPattern.hasMatch(text)) return (value: text, domain: false);
  final domain = text.startsWith('@') ? text.substring(1) : text;
  if (_domainPattern.hasMatch(domain)) return (value: domain, domain: true);
  return null;
}
