import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_brush.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_shading.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_run_highlight.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_cells.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_geometry.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_hourly_band.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 시간별 격자: 위에 날짜, 왼쪽에 정각 시각, 가운데 칸. 하루 범위 밖의 시간은 칸 위아래에 한 시간 높이의 '받지
/// 않는 시간' 띠([MeetingHourlyBand])로 보이고, 축에 띠의 위 끝 시각(0:00, 범위의 끝)을 적어 실제 시각을 알린다.
/// 띠는 칸이 아니라 칠할 수 없고, 칸에서 띠로 끈 붓질은 범위 끝 칸에서 멈춘다.
///
/// 날짜 머리를 누르면 답하지 않은 날은 그날 전체를 되는 칸으로 칠하고, 답한 날은 그날을 지운다([brushDay]).
/// 날짜 열이 너무 좁아지면 시각은 왼쪽에 둔 채 날짜와 칸을 옆으로 굴린다.
class MeetingHourlyGrid extends StatelessWidget {
  const MeetingHourlyGrid({
    super.key,
    required this.shading,
    required this.brush,
    required this.onPaint,
    required this.onLocked,
    this.onResetDay,
    this.highlight,
  });

  final MeetingShading shading;
  final MeetingAnswer brush;
  final MeetingPaint? onPaint;
  final VoidCallback? onLocked;

  /// 답한 날을 지운다. 없으면 바로 지운다
  final ValueChanged<List<MeetingCell>>? onResetDay;

  /// 강조할 추천 시간 카드
  final MeetingRunHighlight? highlight;

  static const _columnGap = 6.0;

  /// 날짜 열이 이보다 좁아지면 옆으로 굴린다
  static const _minColumnWidth = 40.0;

  /// [column] 날짜 전체를 칠한다
  void _paintDay(int column) {
    final onPaint = this.onPaint;
    if (onPaint == null) return onLocked?.call();
    final grid = shading.grid;
    final day = [
      for (final cell in grid.cells)
        if (cell.column == column) cell,
    ];
    if (day.isEmpty) return;
    final answered = day.any(
      (cell) => shading.answerAt(cell) != MeetingAnswer.unanswered,
    );
    final onResetDay = this.onResetDay;
    if (answered && onResetDay != null) return onResetDay(day);
    onPaint(brushDay(day, shading.answerAt));
  }

  /// 시각을 적는 줄: 첫 줄과 정각
  static List<int> _labelRows(MeetingGrid grid) => [
    for (final (row, minute) in grid.rowMinutes.indexed)
      if (row == 0 || minute % 60 == 0) row,
  ];

  /// 칸 모양. 큰 글자에서도 시각 글자([labelHeight])가 다음 시각과 겹치지 않게 줄을 늘리고 칸을 넓힌다
  static MeetingCellShape _shape(
    MeetingGrid grid,
    List<int> labelRows,
    double labelHeight,
  ) {
    final rowsPerLabel = [
      for (var i = 0; i < labelRows.length; i++)
        (i + 1 < labelRows.length ? labelRows[i + 1] : grid.rows) -
            labelRows[i],
    ].reduce(math.min);
    return MeetingCellShape.hourly(
      slotMinutes: grid.rowMinutes.length > 1
          ? grid.rowMinutes[1] - grid.rowMinutes[0]
          : 60,
      columnGap: _columnGap,
      minRowHeight: (labelHeight + 4) / rowsPerLabel,
    );
  }

  /// 띠와 칸 사이 틈
  static const _bandGap = 4.0;

  /// 하루 범위 밖의 띠 글: 위(0시~시작)와 아래(끝~24시). 범위가 그 끝에 닿으면 null
  static ({String? upper, String? lower, int start, int end}) _bands(
    MeetingGrid grid,
  ) {
    final start = grid.rowMinutes.first;
    final end = grid.cells.map((cell) => cell.endMinute).fold(start, math.max);
    String text(int from, int to) =>
        '${minuteLabel(from)}–${minuteLabel(to)} · 받지 않는 시간';
    return (
      upper: start > 0 ? text(0, start) : null,
      lower: end < minutesPerDay ? text(end, minutesPerDay) : null,
      start: start,
      end: end,
    );
  }

  @override
  Widget build(BuildContext context) {
    final grid = shading.grid;
    final scaler = MediaQuery.textScalerOf(context);
    final theme = Theme.of(context).textTheme;
    final labelStyle = theme.labelSmall!;
    final fontSize = scaler.scale(labelStyle.fontSize!);
    final labelRows = _labelRows(grid);
    final shape = _shape(
      grid,
      labelRows,
      fontSize * (labelStyle.height ?? 1.2),
    );
    final rowHeight = shape.height(0, scaler);
    final labelWidth = math.max(44.0, fontSize * 3 + 8);
    final headHeight =
        scaler.scale(labelStyle.fontSize!) * 1.4 +
        scaler.scale(theme.titleSmall!.fontSize!) * 1.4 +
        4;
    final bands = _bands(grid);
    // 띠는 한 시간 덩어리 높이로 줄여 둔다(글이 들어갈 높이는 지킨다)
    final slot = grid.rowMinutes.length > 1
        ? grid.rowMinutes[1] - grid.rowMinutes[0]
        : 60;
    final bandHeight = math.max(rowHeight * 60 / slot, fontSize * 1.4 + 12);
    final top = bands.upper == null ? 0.0 : bandHeight + _bandGap;
    final cellsHeight = grid.rows * rowHeight;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: headHeight + 8),
          child: SizedBox(
            width: labelWidth,
            height:
                top +
                cellsHeight +
                (bands.lower == null ? 0 : _bandGap + bandHeight),
            child: _HourLabels(
              marks: [
                if (bands.upper != null) (0, minuteLabel(0)),
                for (final row in labelRows)
                  (top + row * rowHeight, minuteLabel(grid.rowMinutes[row])),
                if (bands.lower != null)
                  (top + cellsHeight + _bandGap, minuteLabel(bands.end)),
              ],
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final needed =
                  grid.columns * _minColumnWidth +
                  (grid.columns - 1) * _columnGap;
              final body = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: headHeight,
                    child: _DayHeads(
                      shading: shading,
                      gap: _columnGap,
                      onTap: _paintDay,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (bands.upper case final text?) ...[
                    MeetingHourlyBand(text: text, height: bandHeight),
                    const SizedBox(height: _bandGap),
                  ],
                  MeetingGridCells(
                    shading: shading,
                    shape: shape,
                    brush: brush,
                    onPaint: onPaint,
                    highlight: highlight,
                    onLocked: onLocked,
                  ),
                  if (bands.lower case final text?) ...[
                    const SizedBox(height: _bandGap),
                    MeetingHourlyBand(text: text, height: bandHeight),
                  ],
                ],
              );
              if (needed <= constraints.maxWidth) return body;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: needed, child: body),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 날짜 머리 줄
class _DayHeads extends StatelessWidget {
  const _DayHeads({
    required this.shading,
    required this.gap,
    required this.onTap,
  });

  final MeetingShading shading;
  final double gap;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final grid = shading.grid;
    return Row(
      children: [
        for (final (i, day) in grid.columnDays.indexed) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: _DayHead(
              day: day,
              answers: [
                for (final cell in grid.cells)
                  if (cell.column == i) shading.answerAt(cell),
              ],
              onTap: () => onTap(i),
            ),
          ),
        ],
      ],
    );
  }
}

/// 시간별 왼쪽의 시각: 띠의 위 끝(0:00), 첫 줄(정각이 아니어도), 정각, 아래 띠의 위 끝(범위의 끝)
class _HourLabels extends StatelessWidget {
  const _HourLabels({required this.marks});

  /// 위에서부터의 자리와 시각
  final List<(double, String)> marks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExcludeSemantics(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final (top, label) in marks)
            Positioned(
              top: top - 1,
              left: 0,
              right: 6,
              // 한 줄로 두고, 칸보다 넓은 글꼴이면 칸에 맞춰 줄인다
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 시간별의 날짜 머리: 요일과 '3.1'. 누르면 답하지 않은 날은 그날 전체를 되는 칸으로, 답한 날은 지운다
class _DayHead extends StatelessWidget {
  const _DayHead({
    required this.day,
    required this.answers,
    required this.onTap,
  });

  final DateTime day;

  /// 그날 칸마다 내 답
  final List<MeetingAnswer> answers;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = answers.any((answer) => answer != MeetingAnswer.unanswered)
        ? '그날 일정을 초기화합니다'
        : '하루 전체를 되는 시간으로 칠합니다';
    return Semantics(
      label: '${meetingDayLabel(day)} 하루 전체',
      hint: hint,
      button: true,
      excludeSemantics: true,
      child: Tooltip(
        message: hint,
        child: InkWell(
          borderRadius: AppRadius.smAll,
          onTap: onTap,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              children: [
                Text(
                  weekdayName(day.weekday - 1),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:
                        meetingWeekendColor(context, day.weekday % 7) ??
                        theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${day.month}.${day.day}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
