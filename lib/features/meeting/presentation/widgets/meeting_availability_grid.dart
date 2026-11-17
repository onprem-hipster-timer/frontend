import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_shading.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_cells.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_geometry.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 내 시간 격자와 색 설명. 방식마다 모양이 다르다.
///
/// - 시간별: 위에 날짜, 왼쪽에 정각 시각, 날짜마다 세로 띠(정각 실선, 그 밖의 칸 경계 점선)
/// - 날짜별: 일요일부터의 요일 머리와 달력 칸
/// - 요일별: 월요일부터 일곱 칸
///
/// [onPaint]가 없으면 칠할 수 없고, 칸을 누르면 [onLocked]를 부른다([MeetingGridCells]).
class MeetingAvailabilityGrid extends StatelessWidget {
  const MeetingAvailabilityGrid({
    super.key,
    required this.shading,
    required this.onPaint,
    this.onLocked,
  });

  final MeetingShading shading;
  final MeetingPaint? onPaint;
  final VoidCallback? onLocked;

  @override
  Widget build(BuildContext context) {
    final grid = shading.grid;
    if (grid.cells.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('이 모임 기간에는 고를 수 있는 날이 없습니다'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        switch (grid.mode) {
          MeetingMode.hourly => _HourlyGrid(
            shading: shading,
            onPaint: onPaint,
            onLocked: onLocked,
          ),
          MeetingMode.weekly => MeetingGridCells(
            shading: shading,
            shape: MeetingCellShape.weekly,
            onPaint: onPaint,
            onLocked: onLocked,
          ),
          MeetingMode.daily || MeetingMode.$unknown => _DailyGrid(
            shading: shading,
            onPaint: onPaint,
            onLocked: onLocked,
          ),
        },
        const SizedBox(height: 12),
        _Legend(othersTotal: shading.othersTotal, hasSelf: shading.hasSelf),
      ],
    );
  }
}

/// 시간별: 위에 날짜, 왼쪽에 정각 시각, 가운데 칸
class _HourlyGrid extends StatelessWidget {
  const _HourlyGrid({
    required this.shading,
    required this.onPaint,
    required this.onLocked,
  });

  final MeetingShading shading;
  final MeetingPaint? onPaint;
  final VoidCallback? onLocked;

  static const _columnGap = 6.0;

  @override
  Widget build(BuildContext context) {
    final grid = shading.grid;
    final scaler = MediaQuery.textScalerOf(context);
    final labelStyle = Theme.of(context).textTheme.labelSmall!;
    final fontSize = scaler.scale(labelStyle.fontSize!);
    // 큰 글자에서도 시각 글자가 다음 시각과 겹치지 않게 줄을 늘리고 칸을 넓힌다
    final labelRows = [
      for (final (row, minute) in grid.rowMinutes.indexed)
        if (row == 0 || minute % 60 == 0) row,
    ];
    final rowsPerLabel = [
      for (var i = 0; i < labelRows.length; i++)
        (i + 1 < labelRows.length ? labelRows[i + 1] : grid.rows) -
            labelRows[i],
    ].reduce(math.min);
    final shape = MeetingCellShape.hourly(
      slotMinutes: grid.rowMinutes.length > 1
          ? grid.rowMinutes[1] - grid.rowMinutes[0]
          : 60,
      columnGap: _columnGap,
      minRowHeight: (fontSize * (labelStyle.height ?? 1.2) + 4) / rowsPerLabel,
    );
    final rowHeight = shape.height(0, scaler);
    final labelWidth = math.max(44.0, fontSize * 3 + 8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(width: labelWidth),
            for (final (i, day) in grid.columnDays.indexed) ...[
              if (i > 0) const SizedBox(width: _columnGap),
              Expanded(child: _DayHead(day: day)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              height: grid.rows * rowHeight,
              child: _HourLabels(
                rows: labelRows,
                grid: grid,
                rowHeight: rowHeight,
              ),
            ),
            Expanded(
              child: MeetingGridCells(
                shading: shading,
                shape: shape,
                onPaint: onPaint,
                onLocked: onLocked,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 시간별 왼쪽의 정각 시각(첫 줄은 정각이 아니어도 둔다)
class _HourLabels extends StatelessWidget {
  const _HourLabels({
    required this.rows,
    required this.grid,
    required this.rowHeight,
  });

  /// 시각을 적는 줄
  final List<int> rows;
  final MeetingGrid grid;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExcludeSemantics(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final row in rows)
            Positioned(
              top: row * rowHeight - 1,
              left: 0,
              right: 6,
              // 한 줄로 두고, 칸보다 넓은 글꼴이면 칸에 맞춰 줄인다
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  minuteLabel(grid.rowMinutes[row]),
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

/// 시간별의 날짜 머리: 요일과 '3.1'
class _DayHead extends StatelessWidget {
  const _DayHead({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          children: [
            Text(
              weekdayName(day.weekday - 1),
              style: theme.textTheme.labelSmall?.copyWith(
                color:
                    _weekendColor(context, day.weekday % 7) ??
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
    );
  }
}

const _sundayFirstHeads = ['일', '월', '화', '수', '목', '금', '토'];

/// 날짜별: 일요일부터의 요일 머리와 달력 칸
class _DailyGrid extends StatelessWidget {
  const _DailyGrid({
    required this.shading,
    required this.onPaint,
    required this.onLocked,
  });

  final MeetingShading shading;
  final MeetingPaint? onPaint;
  final VoidCallback? onLocked;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    final gap = MeetingCellShape.daily.columnGap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              for (var column = 0; column < 7; column++) ...[
                if (column > 0) SizedBox(width: gap),
                Expanded(
                  child: Text(
                    _sundayFirstHeads[column],
                    textAlign: TextAlign.center,
                    style: style?.copyWith(
                      color: _weekendColor(context, column),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        MeetingGridCells(
          shading: shading,
          shape: MeetingCellShape.daily,
          onPaint: onPaint,
          onLocked: onLocked,
        ),
      ],
    );
  }
}

/// 일요일(0)·토요일(6) 글자 색. 평일은 null
Color? _weekendColor(BuildContext context, int sundayFirstColumn) =>
    switch (sundayFirstColumn) {
      0 => AppColors.of(context).holiday,
      6 => AppColors.of(context).saturday,
      _ => null,
    };

/// 색 설명: 내 시간과 다른 참여자 농도(1명 ~ 모두). 내 시간이 없으면(로그인 전) 참여자 농도만
class _Legend extends StatelessWidget {
  const _Legend({required this.othersTotal, required this.hasSelf});

  final int othersTotal;
  final bool hasSelf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = MeetingGridColors.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final levels = {
      for (var count = 1; count <= othersTotal; count++)
        availabilityShade(count, othersTotal),
    };
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (hasSelf)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Swatch(colors.mine, border: colors.border),
              const SizedBox(width: 4),
              Text('내 시간', style: style),
            ],
          ),
        if (othersTotal > 0)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${hasSelf ? '다른 참여자' : '참여자'} 1명', style: style),
              const SizedBox(width: 6),
              for (final level in levels)
                _Swatch(
                  Color.alphaBlend(colors.shade(level)!, colors.base),
                  border: colors.border,
                ),
              if (othersTotal > 1) ...[
                const SizedBox(width: 4),
                Text('$othersTotal명', style: style),
              ],
            ],
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.color, {required this.border});

  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.only(right: 2),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: border),
        borderRadius: AppRadius.xsAll,
      ),
    );
  }
}
