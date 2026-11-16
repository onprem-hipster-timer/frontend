import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:momeet/features/meeting/domain/meeting_shading.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_geometry.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 격자 칸을 그린다. 내 칸(끄는 중이면 끄는 값)은 진하게, 그 밖은 다른 참여자 농도로 칠한다.
///
/// 칸마다 스크린 리더 항목(날짜·시각, 내 시간인지, 되는 사람 수)과 누르기 동작을 둔다. [onToggle]이
/// 없으면(칠할 수 없는 격자) 누르기 동작을 두지 않는다.
class MeetingGridPainter extends CustomPainter {
  MeetingGridPainter({
    required this.shading,
    required this.geometry,
    required this.drag,
    required this.colors,
    required this.textStyle,
    required this.scaler,
    required this.direction,
    required this.onToggle,
  });

  final MeetingShading shading;
  final MeetingGridGeometry geometry;
  final MeetingGridDrag? drag;
  final MeetingGridColors colors;
  final TextStyle textStyle;
  final TextScaler scaler;
  final TextDirection direction;
  final ValueChanged<MeetingCell>? onToggle;

  MeetingGrid get grid => shading.grid;

  bool _mine(MeetingCell cell) {
    final drag = this.drag;
    return drag != null && drag.covers(cell)
        ? drag.available
        : shading.isMine(cell);
  }

  Color? _fill(MeetingCell cell) => _mine(cell)
      ? colors.mine
      : colors.shade(
          availabilityShade(shading.othersCountAt(cell), shading.othersTotal),
        );

  @override
  void paint(Canvas canvas, Size size) {
    if (geometry.shape.continuous) {
      _paintColumns(canvas);
    } else {
      _paintTiles(canvas);
    }
  }

  /// 시간별: 날짜마다 둥근 띠 하나에 칸을 채우고 정각은 실선, 그 밖의 칸 경계는 점선
  void _paintColumns(Canvas canvas) {
    final line = Paint()
      ..color = colors.line
      ..strokeWidth = 1;
    for (var column = 0; column < grid.columns; column++) {
      final band = Rect.fromLTWH(
        geometry.rectOf(column, 0).left,
        0,
        geometry.cellWidth,
        geometry.size.height,
      );
      final rounded = RRect.fromRectAndRadius(
        band,
        const Radius.circular(AppRadius.sm),
      );
      canvas
        ..save()
        ..clipRRect(rounded)
        ..drawRect(band, Paint()..color = colors.base);
      for (var row = 0; row < grid.rows; row++) {
        final cell = grid.at(column, row);
        final fill = cell == null ? colors.missing : _fill(cell);
        if (fill != null) {
          canvas.drawRect(geometry.rectOf(column, row), Paint()..color = fill);
        }
      }
      for (var row = 1; row < grid.rows; row++) {
        final y = row * geometry.cellHeight;
        if (grid.rowMinutes[row] % 60 == 0) {
          canvas.drawLine(Offset(band.left, y), Offset(band.right, y), line);
          continue;
        }
        for (var x = band.left + 2; x < band.right; x += 7) {
          final end = math.min(x + 4, band.right);
          canvas.drawLine(Offset(x, y), Offset(end, y), line);
        }
      }
      canvas
        ..restore()
        ..drawRRect(
          rounded,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = colors.border,
        );
    }
  }

  /// 날짜별·요일별: 하루마다 둥근 타일과 날짜(요일) 글자
  void _paintTiles(Canvas canvas) {
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..color = colors.border;
    for (final cell in grid.cells) {
      final rect = geometry.rectOf(cell.column, cell.row);
      final rounded = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(AppRadius.md),
      );
      canvas.drawRRect(rounded, Paint()..color = colors.base);
      final fill = _fill(cell);
      if (fill != null) canvas.drawRRect(rounded, Paint()..color = fill);
      canvas.drawRRect(rounded, border);
      _paintLabel(canvas, rect, cell);
    }
  }

  /// 칸 가운데 글자. 요일별은 요일, 날짜별은 날(첫 칸과 매달 1일은 '3.1')
  void _paintLabel(Canvas canvas, Rect rect, MeetingCell cell) {
    final color = _mine(cell)
        ? colors.onMine
        : switch (cell.day.weekday) {
            DateTime.sunday => colors.sunday,
            DateTime.saturday => colors.saturday,
            _ => colors.text,
          };
    final text = grid.mode == MeetingMode.weekly
        ? weekdayName(cell.column)
        : cell.index == 0 || cell.day.day == 1
        ? '${cell.day.month}.${cell.day.day}'
        : '${cell.day.day}';
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
      textDirection: direction,
      textScaler: scaler,
    )..layout();
    // 좁은 칸·큰 글자에서는 글자를 칸에 맞춰 줄인다
    final room = rect.deflate(4);
    final scale = math.min(
      1.0,
      math.min(room.width / painter.width, room.height / painter.height),
    );
    canvas
      ..save()
      ..translate(rect.center.dx, rect.center.dy)
      ..scale(scale);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
    painter.dispose();
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder {
    final others = shading.hasSelf ? '다른 참여자' : '참여자';
    final onToggle = this.onToggle;
    return (size) => [
      for (final cell in grid.cells)
        CustomPainterSemantics(
          rect: geometry.rectOf(cell.column, cell.row),
          properties: SemanticsProperties(
            label: meetingCellLabel(grid, cell),
            value: shading.isMine(cell) ? '내 시간' : null,
            hint: switch (shading.othersCountAt(cell)) {
              0 => null,
              final count => '$others $count명',
            },
            selected: shading.hasSelf ? shading.isMine(cell) : null,
            button: onToggle != null,
            onTap: onToggle == null ? null : () => onToggle(cell),
            textDirection: direction,
          ),
        ),
    ];
  }

  @override
  bool shouldRepaint(MeetingGridPainter oldDelegate) =>
      oldDelegate.shading != shading ||
      oldDelegate.geometry != geometry ||
      oldDelegate.drag != drag ||
      oldDelegate.colors != colors ||
      oldDelegate.scaler != scaler;

  @override
  bool shouldRebuildSemantics(MeetingGridPainter oldDelegate) =>
      oldDelegate.shading != shading ||
      oldDelegate.geometry != geometry ||
      (oldDelegate.onToggle == null) != (onToggle == null);
}
