import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_names.dart';

void main() {
  group('처음 참여하는 이름', () {
    test('계정 이름의 앞뒤 공백을 뺀다', () {
      expect(meetingDisplayName('  지현 '), '지현');
    });

    test('계정 이름이 없거나 비었으면 참여자다', () {
      expect(meetingDisplayName(null), '참여자');
      expect(meetingDisplayName('   '), '참여자');
      expect(meetingDisplayName('\n\t'), '참여자');
    });

    test('제어 문자는 공백으로 바꾼다', () {
      expect(meetingDisplayName('김\n지현'), '김 지현');
    });

    test('50자를 넘으면 코드 포인트로 앞 50자만 쓴다', () {
      final emoji = '😀' * 60;
      expect(meetingDisplayName(emoji).runes, hasLength(50));
      expect(meetingDisplayName('가' * 50), '가' * 50);
    });
  });

  group('이름 입력 확인', () {
    test('앞뒤 공백을 뺀 1~50자면 쓸 수 있다', () {
      expect(meetingNameError(' 지현 '), isNull);
      expect(meetingNameError('😀' * 50), isNull);
    });

    test('비었거나 공백뿐이면 입력을 요청한다', () {
      expect(meetingNameError(''), '이름을 입력해 주세요');
      expect(meetingNameError('   '), '이름을 입력해 주세요');
    });

    test('가운데의 줄바꿈·탭은 받지 않는다', () {
      expect(meetingNameError('김\n지현'), '줄바꿈이나 탭은 쓸 수 없습니다');
      expect(meetingNameError('김\t지현'), '줄바꿈이나 탭은 쓸 수 없습니다');
    });

    test('51자부터 받지 않는다', () {
      expect(meetingNameError('가' * 51), '이름은 50자까지 쓸 수 있습니다');
      expect(meetingNameError('😀' * 51), '이름은 50자까지 쓸 수 있습니다');
    });
  });
}
