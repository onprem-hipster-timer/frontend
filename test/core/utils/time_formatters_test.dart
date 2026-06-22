import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/utils/time_formatters.dart';

void main() {
  group('formatDuration', () {
    test('HH:MM:SS 형식으로 변환한다', () {
      expect(
        formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '01:02:03',
      );
    });

    test('0은 00:00:00으로 표시한다', () {
      expect(formatDuration(Duration.zero), '00:00:00');
    });

    test('분/초는 60으로 나눈 나머지로 표시한다', () {
      expect(
        formatDuration(const Duration(minutes: 90, seconds: 75)),
        '01:31:15',
      );
    });

    test('100시간 이상도 그대로 표시한다', () {
      expect(formatDuration(const Duration(hours: 100)), '100:00:00');
    });
  });

  group('formatTime', () {
    test('HH:MM 형식으로 변환한다', () {
      expect(formatTime(DateTime(2025, 1, 1, 9, 5)), '09:05');
    });

    test('자정·정오를 올바르게 표시한다', () {
      expect(formatTime(DateTime(2025, 1, 1, 0, 0)), '00:00');
      expect(formatTime(DateTime(2025, 1, 1, 12, 0)), '12:00');
    });

    test('UTC DateTime은 로컬로 변환해 표시한다', () {
      final utc = DateTime.utc(2025, 1, 1, 0, 0);
      final local = utc.toLocal();
      final expected =
          '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
      expect(formatTime(utc), expected);
    });
  });
}
