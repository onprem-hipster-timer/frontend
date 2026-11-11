import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_time_range_fields.dart';

void main() {
  final timed = (
    start: DateTime(2026, 11, 9, 9, 30),
    end: DateTime(2026, 11, 10, 11),
    allDay: false,
  );

  group('종일', () {
    test('켜면 시작은 그날 00:00, 종료는 그날 23:59', () {
      final r = withAllDay(timed, true);
      expect(r.start, DateTime(2026, 11, 9));
      expect(r.end, DateTime(2026, 11, 10, 23, 59));
      expect(r.allDay, isTrue);
    });

    test('끄면 시각은 그대로 둔다', () {
      final r = withAllDay(withAllDay(timed, true), false);
      expect(r.start, DateTime(2026, 11, 9));
      expect(r.end, DateTime(2026, 11, 10, 23, 59));
      expect(r.allDay, isFalse);
    });
  });

  group('시작 바꾸기', () {
    test('종료보다 이르면 종료는 그대로', () {
      final r = withStart(timed, DateTime(2026, 11, 10, 8));
      expect(r.end, timed.end);
    });

    test('종료와 같으면 종료는 그대로', () {
      final r = withStart(timed, timed.end);
      expect(r.end, timed.end);
    });

    test('종료보다 늦으면 종료를 1시간 뒤로 옮긴다', () {
      final r = withStart(timed, DateTime(2026, 11, 12, 15));
      expect(r.end, DateTime(2026, 11, 12, 16));
    });

    test('종일이면 종료를 그날 23:59로 옮긴다', () {
      final allDay = withAllDay(timed, true);
      final r = withStart(allDay, DateTime(2026, 11, 12));
      expect(r.end, DateTime(2026, 11, 12, 23, 59));
    });
  });

  group('종료 바꾸기', () {
    test('시작보다 늦으면 시작은 그대로', () {
      final r = withEnd(timed, DateTime(2026, 11, 9, 10));
      expect(r.start, timed.start);
    });

    test('시작보다 빠르면 시작을 1시간 앞으로 옮긴다', () {
      final r = withEnd(timed, DateTime(2026, 11, 8, 12));
      expect(r.start, DateTime(2026, 11, 8, 11));
    });

    test('종일이면 시작을 그날 00:00으로 옮긴다', () {
      final allDay = withAllDay(timed, true);
      final r = withEnd(allDay, DateTime(2026, 11, 7, 23, 59));
      expect(r.start, DateTime(2026, 11, 7));
    });
  });
}
