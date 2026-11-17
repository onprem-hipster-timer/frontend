import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/shared/ui/ui.dart';

const _weekdayHeads = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// 모임 날짜 달력. 일요일부터 한 주를 놓고, [firstDay]가 든 달 앞으로는 넘기지 않는다
class MeetingCalendar extends StatefulWidget {
  const MeetingCalendar({
    super.key,
    required this.firstDay,
    required this.stateOf,
    required this.onDayTap,
    this.shownDay,
  });

  /// 고를 수 있는 첫날(오늘)
  final DateTime firstDay;

  /// 처음 보일 달의 날. 없으면 [firstDay]의 달이다
  final DateTime? shownDay;

  /// 날짜 칸의 상태
  final MeetingDayState Function(DateTime day) stateOf;

  final ValueChanged<DateTime> onDayTap;

  @override
  State<MeetingCalendar> createState() => _MeetingCalendarState();
}

class _MeetingCalendarState extends State<MeetingCalendar> {
  late DateTime _month = DateTime.utc(
    (widget.shownDay ?? widget.firstDay).year,
    (widget.shownDay ?? widget.firstDay).month,
  );

  void _move(int months) =>
      setState(() => _month = DateTime.utc(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final first = DateTime.utc(widget.firstDay.year, widget.firstDay.month);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: AppRadius.xlAll,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MonthHeader(
              month: _month,
              onPrevious: _month.isAfter(first) ? () => _move(-1) : null,
              onNext: () => _move(1),
            ),
            const SizedBox(height: 4),
            const _WeekdayHeads(),
            _MonthGrid(
              month: _month,
              stateOf: widget.stateOf,
              onDayTap: widget.onDayTap,
            ),
          ],
        ),
      ),
    );
  }
}

/// 연도 · 큰 달 숫자 · 영문 달 이름과 이전·다음 달 버튼
class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: '이전 달',
          onPressed: onPrevious,
        ),
        Expanded(
          child: Semantics(
            label: '${month.year}년 ${month.month}월',
            excludeSemantics: true,
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                Text('${month.year}', style: text.titleMedium),
                Text('${month.month}', style: text.displaySmall),
                Text(meetingMonthName(month), style: text.titleMedium),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: '다음 달',
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// 요일 머리 줄. 일요일·토요일은 공휴일·토요일 색이다
class _WeekdayHeads extends StatelessWidget {
  const _WeekdayHeads();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  _weekdayHeads[i],
                  textAlign: TextAlign.center,
                  style: style?.copyWith(color: _weekendColor(context, i)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 일요일(0)·토요일(6) 글자 색. 평일은 null
Color? _weekendColor(BuildContext context, int column) => switch (column) {
  0 => AppColors.of(context).holiday,
  6 => AppColors.of(context).saturday,
  _ => null,
};

/// 한 달의 날짜 칸. 앞뒤 달의 날은 비워 둔다
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.stateOf,
    required this.onDayTap,
  });

  final DateTime month;
  final MeetingDayState Function(DateTime day) stateOf;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final lead = month.weekday % 7;
    final length = DateTime.utc(month.year, month.month + 1, 0).day;
    final rows = ((lead + length) / 7).ceil();
    final height = math.max(
      40.0,
      MediaQuery.textScalerOf(context).scale(14) * 1.4 + 12,
    );
    return Column(
      children: [
        for (var row = 0; row < rows; row++)
          SizedBox(
            height: height,
            child: Row(
              children: [
                for (var column = 0; column < 7; column++)
                  Expanded(
                    child: switch (row * 7 + column - lead + 1) {
                      final day when day >= 1 && day <= length => _DayCell(
                        day: DateTime.utc(month.year, month.month, day),
                        state: stateOf(
                          DateTime.utc(month.year, month.month, day),
                        ),
                        onTap: onDayTap,
                      ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 날짜 칸 하나. 고른 날은 동그라미로 채우고, 고를 수 없는 날은 흐리게, 뺀 날은 빈 동그라미 안에 흐리게 줄을
/// 긋는다(요일 색 없이)
class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.state, required this.onTap});

  final DateTime day;
  final MeetingDayState state;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = state == MeetingDayState.selected;
    final excluded = state == MeetingDayState.excluded;
    final tappable = state != MeetingDayState.unavailable;
    // 달력처럼 흐린 날은 요일 색 없이 흐린 날짜 색이다
    final color = state == MeetingDayState.unavailable || excluded
        ? scheme.onSurface.withValues(alpha: 0.4)
        : _weekendColor(context, day.weekday % 7) ?? scheme.onSurface;
    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter =
            math.min(constraints.maxWidth, constraints.maxHeight) - 4;
        return MergeSemantics(
          child: Semantics(
            label: meetingDayLabel(day),
            hint: excluded ? '뺀 날' : null,
            selected: selected,
            button: true,
            enabled: tappable,
            child: InkResponse(
              onTap: tappable ? () => onTap(day) : null,
              radius: diameter / 2,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (selected || excluded)
                    SizedBox.square(
                      dimension: diameter,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: selected ? scheme.primaryContainer : null,
                          border: excluded
                              ? Border.all(color: scheme.outline)
                              : null,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  // 좁은 칸·큰 글자에서는 숫자를 칸에 맞춰 줄인다
                  Padding(
                    padding: const EdgeInsets.all(2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ExcludeSemantics(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: color,
                            fontWeight: selected ? FontWeight.w700 : null,
                            decoration: excluded
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: color,
                            decorationThickness: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
