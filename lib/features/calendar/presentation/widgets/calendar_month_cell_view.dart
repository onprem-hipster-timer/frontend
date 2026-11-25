import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/marquee_text.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 월 보기의 날짜 칸. 날짜 숫자와, 공휴일이면 그 이름([holidayName])을 보인다.
class CalendarMonthCellView extends StatelessWidget {
  const CalendarMonthCellView({
    super.key,
    required this.date,
    required this.isToday,
    required this.isCurrentMonth,
    required this.highlightWeekends,
    this.holidayName,
  });

  final DateTime date;
  final bool isToday;

  /// 보고 있는 달의 날짜인지. 아니면 숫자를 흐리게 쓴다
  final bool isCurrentMonth;
  final bool highlightWeekends;

  /// 그날 공휴일 이름. 공휴일이 아니면 null
  final String? holidayName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final holidayName = this.holidayName;
    final dateStyle = _dateTextStyle(
      date: date,
      isHoliday: holidayName != null,
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
            if (holidayName != null) ...[
              const SizedBox(width: 4),
              // 칸에 다 들어가지 않는 이름은 두 번 흘려 보인 뒤 말줄임으로 둔다
              Expanded(
                child: Align(
                  alignment: Alignment.topRight,
                  child: MarqueeText(
                    holidayName,
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
