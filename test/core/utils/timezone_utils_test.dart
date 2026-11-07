import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/utils/timezone_utils.dart';

void main() {
  group('formatUtcOffset', () {
    test('양수 오프셋은 +HH:mm으로 표시한다', () {
      expect(formatUtcOffset(const Duration(hours: 9)), '+09:00');
    });

    test('음수 오프셋은 -HH:mm으로 표시한다', () {
      expect(formatUtcOffset(const Duration(hours: -5)), '-05:00');
    });

    test('30분 단위 오프셋을 표시한다', () {
      expect(formatUtcOffset(const Duration(hours: 5, minutes: 30)), '+05:30');
    });

    test('음수 30분 오프셋을 표시한다', () {
      expect(
        formatUtcOffset(const Duration(hours: -9, minutes: -30)),
        '-09:30',
      );
    });

    test('0은 +00:00으로 표시한다', () {
      expect(formatUtcOffset(Duration.zero), '+00:00');
    });
  });
}
