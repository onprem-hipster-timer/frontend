import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/utils/timezone_utils.dart';

void main() {
  group('deviceTimezoneOffsetString', () {
    test('±HH:MM 형식의 문자열을 반환한다', () {
      final result = deviceTimezoneOffsetString();
      expect(result, matches(RegExp(r'^[+-]\d{2}:\d{2}$')));
    });

    test('결과 길이가 6이다 (+09:00)', () {
      final result = deviceTimezoneOffsetString();
      expect(result.length, 6);
    });

    test('부호가 + 또는 -이다', () {
      final result = deviceTimezoneOffsetString();
      expect(result[0], anyOf('+', '-'));
    });

    test('기기 타임존 오프셋과 일치한다', () {
      final offset = DateTime.now().timeZoneOffset;
      final result = deviceTimezoneOffsetString();

      final totalMinutes = offset.inMinutes;
      final expectedHours = totalMinutes ~/ 60;
      final expectedMinutes = totalMinutes.remainder(60).abs();
      final expectedSign = totalMinutes >= 0 ? '+' : '-';
      final expected =
          '$expectedSign${expectedHours.abs().toString().padLeft(2, '0')}:${expectedMinutes.toString().padLeft(2, '0')}';

      expect(result, expected);
    });
  });
}
