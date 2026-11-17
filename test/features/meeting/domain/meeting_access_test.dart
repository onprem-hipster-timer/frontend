import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_access.dart';

void main() {
  group('이메일', () {
    for (final (input, value) in [
      ('kim@example.com', 'kim@example.com'),
      ('  Kim.Lee+meet@Mail.Example.co.kr ', 'kim.lee+meet@mail.example.co.kr'),
      ('a_b-c@sub-domain.example.io', 'a_b-c@sub-domain.example.io'),
    ]) {
      test('"$input"은 이메일 $value', () {
        expect(parseMeetingAccessEntry(input), (value: value, domain: false));
      });
    }
  });

  group('도메인', () {
    for (final (input, value) in [
      ('example.com', 'example.com'),
      ('@Example.COM', 'example.com'),
      (' korea.ac.kr ', 'korea.ac.kr'),
      ('my-company.co', 'my-company.co'),
    ]) {
      test('"$input"은 도메인 $value', () {
        expect(parseMeetingAccessEntry(input), (value: value, domain: true));
      });
    }
  });

  group('형식이 아니면 읽지 않는다', () {
    for (final input in [
      '',
      '   ',
      'kim',
      'kim@',
      '@',
      'kim@example',
      'kim@@example.com',
      'kim lee@example.com',
      'kim@exa mple.com',
      'example',
      '-example.com',
      'example-.com',
      'example..com',
      '.example.com',
      'example.c',
      'http://example.com',
      'kim@example.com/',
    ]) {
      test('"$input"', () => expect(parseMeetingAccessEntry(input), isNull));
    }
  });
}
