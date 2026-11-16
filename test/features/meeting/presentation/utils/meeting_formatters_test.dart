import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';

import '../../meeting_fixtures.dart';

/// 2027년 3월의 [day]일 (3월 1일은 월요일)
DateTime march(int day) => DateTime.utc(2027, 3, day);

void main() {
  group('기간', () {
    test('하루면 그날만 보인다', () {
      final meeting = makeMeeting(
        startDate: march(3),
        endDate: march(3),
        availableDays: [2],
      );
      expect(meetingPeriodText(meeting), '3월 3일 (수)');
    });

    test('기간 안의 요일을 모두 받으면 첫날과 마지막 날만 보인다', () {
      final meeting = makeMeeting(
        startDate: march(1),
        endDate: march(5),
        availableDays: [0, 1, 2, 3, 4],
      );
      expect(meetingPeriodText(meeting), '3월 1일 (월) ~ 3월 5일 (금)');
    });

    test('기간 안의 요일을 일부만 받으면 그 요일을 덧붙인다', () {
      final meeting = makeMeeting(
        startDate: march(1),
        endDate: march(15),
        availableDays: [0, 4],
      );
      expect(meetingPeriodText(meeting), '3월 1일 (월) ~ 3월 15일 (월) 중 월·금');
    });

    test('기간 밖의 요일 번호는 셈하지 않는다', () {
      final meeting = makeMeeting(
        startDate: march(1),
        endDate: march(2),
        availableDays: [0, 1, 5],
      );
      expect(meetingPeriodText(meeting), '3월 1일 (월) ~ 3월 2일 (화)');
    });
  });

  group('하루 시간 범위', () {
    test('정각 시각을 시:00으로 보인다', () {
      expect(meetingHoursText(makeMeeting()), '6:00 ~ 18:00');
    });

    test('끝이 00:00이면 하루의 끝인 24:00으로 보인다', () {
      final meeting = makeMeeting(startTime: '22:00:00', endTime: '00:00:00');
      expect(meetingHoursText(meeting), '22:00 ~ 24:00');
    });
  });

  group('시간 기준', () {
    test('서울은 한국 시간 기준이다', () {
      expect(timezoneBasisText('Asia/Seoul'), '한국 시간 기준');
    });

    test('그 밖의 시간대는 이름을 그대로 쓴다', () {
      expect(timezoneBasisText('Mars/Olympus'), 'Mars/Olympus 기준');
    });
  });
}
