import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/providers/holiday_provider.dart';
import 'package:momeet/features/calendar/presentation/widgets/marquee_text.dart';
import 'package:momeet/features/calendar/presentation/utils/schedule_formatters.dart'
    as fmt;
import 'package:momeet/shared/ui/ui.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// 월 보기의 날짜 칸. 날짜 숫자와, 공휴일이면 그 이름을 보인다.
///
/// 공휴일을 불러오는 중이거나 못 불러오면 날짜만 보인다.
class CalendarMonthCell extends ConsumerWidget {
  const CalendarMonthCell({super.key, required this.details});

  final MonthCellDetails details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = details.date;
    final isToday = fmt.isSameDay(date, DateTime.now());
    final visible = details.visibleDates;
    final isCurrentMonth = date.month == visible[visible.length ~/ 2].month;
    final highlightWeekends = ref.watch(
      calendarSettingsProvider.select((s) => s.highlightWeekends),
    );
    final holiday = ref
        .watch(currentHolidaysProvider)
        .whenOrNull(data: (holidays) => holidayOn(holidays, date));
    final dateStyle = _dateTextStyle(
      date: date,
      isHoliday: holiday != null,
      isCurrentMonth: isCurrentMonth,
      highlightWeekends: highlightWeekends,
      colorScheme: colorScheme,
      colors: AppColors.of(context),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
        color: isToday
            ? colorScheme.primary.withValues(alpha: 0.1)
            : colorScheme.surface,
      ),
      // 날짜 숫자와 공휴일 이름을 한 줄에 둔다. 이름이 길면 줄여 숫자를 가리지 않는다
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 좁은 칸·큰 글자에서는 숫자를 칸 폭에 맞춰 줄인다
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topLeft,
                child: _DayNumber(
                  day: date.day,
                  isToday: isToday,
                  color: dateStyle.color,
                  weight: dateStyle.weight,
                ),
              ),
            ),
            if (holiday != null) ...[
              const SizedBox(width: 4),
              // 칸에 다 들어가지 않는 이름은 두 번 흘려 보인 뒤 말줄임으로 둔다
              Expanded(
                child: Align(
                  alignment: Alignment.topRight,
                  child: MarqueeText(
                    holiday.dateName,
                    active: true,
                    loops: 2,
                    style: TextStyle(
                      color: AppColors.of(context).holiday,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 날짜 숫자. 오늘이면 강조 색 동그라미(글자가 크면 알약 모양) 안에 둔다.
class _DayNumber extends StatelessWidget {
  const _DayNumber({
    required this.day,
    required this.isToday,
    required this.color,
    required this.weight,
  });

  final int day;
  final bool isToday;
  final Color color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return isToday
        // 지름 24에서 시작해 글자가 커지면 함께 커진다
        ? Container(
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: colorScheme.primary,
              shape: const StadiumBorder(),
            ),
            child: Text(
              '$day',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        : Text(
            '$day',
            style: TextStyle(color: color, fontSize: 14, fontWeight: weight),
          );
  }
}

/// 날짜 숫자 스타일.
///
/// 한국 달력 관례에 따라 공휴일·일요일은 빨강, 토요일은 파랑으로 표시하고,
/// 나머지는 현재 달 여부에 따라 기본/흐림 색을 쓴다. 주말 강조는
/// [highlightWeekends] 설정으로 끌 수 있으나, 공휴일은 항상 강조한다.
({Color color, FontWeight weight}) _dateTextStyle({
  required DateTime date,
  required bool isHoliday,
  required bool isCurrentMonth,
  required bool highlightWeekends,
  required ColorScheme colorScheme,
  required AppColors colors,
}) {
  final isSunday = date.weekday == DateTime.sunday;
  final isSaturday = date.weekday == DateTime.saturday;

  if (isHoliday || (highlightWeekends && isSunday)) {
    return (color: colors.holiday, weight: FontWeight.w600);
  }
  if (highlightWeekends && isSaturday) {
    return (color: colors.saturday, weight: FontWeight.w600);
  }
  final base = isCurrentMonth
      ? colorScheme.onSurface
      : colorScheme.onSurface.withValues(alpha: 0.4);
  return (color: base, weight: FontWeight.normal);
}
