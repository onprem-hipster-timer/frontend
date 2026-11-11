import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view_style.dart';

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
}
