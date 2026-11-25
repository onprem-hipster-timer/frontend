import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view_style.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

void main() {
  test('일·주 보기의 한 시간 칸은 글자 배율만큼 높아진다', () {
    final colors = ColorScheme.fromSeed(seedColor: Colors.blue);
    double heightAt(double scale) => calendarTimeSlotViewSettings(
      colors,
      use24HourFormat: true,
      textScaler: TextScaler.linear(scale),
    ).timeIntervalHeight;

    expect(heightAt(1), 60);
    expect(heightAt(2), 120);
  });

  test('달력 패키지에 넘기는 글자 스타일은 모두 앱 글꼴이다', () {
    final colors = ColorScheme.fromSeed(seedColor: Colors.blue);
    final header = calendarViewHeaderStyle(colors);
    final month = calendarMonthViewSettings(colors, 3);
    final timeSlot = calendarTimeSlotViewSettings(
      colors,
      use24HourFormat: true,
      textScaler: TextScaler.noScaling,
    );
    final schedule = calendarScheduleViewSettings(colors);
    final styles = <TextStyle?>[
      header.dayTextStyle,
      header.dateTextStyle,
      month.monthCellStyle.textStyle,
      month.monthCellStyle.trailingDatesTextStyle,
      month.monthCellStyle.leadingDatesTextStyle,
      timeSlot.timeTextStyle,
      schedule.appointmentTextStyle,
      schedule.dayHeaderSettings.dayTextStyle,
      schedule.dayHeaderSettings.dateTextStyle,
      schedule.monthHeaderSettings.monthTextStyle,
      for (final region in calendarHolidayRegions([
        const HolidayItem(
          locdate: '20260301',
          seq: 1,
          dateKind: '01',
          dateName: '삼일절',
          isHoliday: true,
        ),
      ], Colors.red))
        region.textStyle,
    ];

    for (final (i, style) in styles.indexed) {
      expect(style?.fontFamily, AppTheme.fontFamily, reason: '$i');
      expect(
        style?.fontFamilyFallback,
        AppTheme.fontFamilyFallback,
        reason: '$i',
      );
    }
  });
}
