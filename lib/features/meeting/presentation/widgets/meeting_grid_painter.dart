import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_shading.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_geometry.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 바뀐 내 칸이 이전 답에서 지금 답으로 넘어가는 중: 칸 자리([MeetingCell.index])마다 이전 답과 진행(0~1)
typedef MeetingGridTransition = ({List<MeetingAnswer> from, double progress});

/// 격자 칸을 그린다. 다른 참여자 농도를 깔고, 내 가능 칸은 진하게 덮고, 내 불가능 칸은 흐리게 덮어 빗금을
/// 긋는다. 끄는 중이면 그 붓질의 결과([preview])를, 바뀌는 중이면 이전 답에서 지금 답으로 섞어 그린다.
///
/// 칸마다 스크린 리더 항목(날짜·시각, 내 답, 되는·안 되는 사람 수)과 누르기 동작을 둔다. [onToggle]이
/// 없으면(칠할 수 없는 격자) 누르기 동작을 두지 않는다.
class MeetingGridPainter extends CustomPainter {
  MeetingGridPainter({
    required this.shading,
    required this.geometry,
    required this.preview,
    required this.colors,
    required this.textStyle,
    required this.scaler,
    required this.direction,
    required this.onToggle,
    this.transition,
    super.repaint,
  });

  final MeetingShading shading;
  final MeetingGridGeometry geometry;

  /// 끄는 중이면 그 붓질로 바뀔 칸의 답
  final Map<MeetingCell, MeetingAnswer>? preview;
  final MeetingGridColors colors;
  final TextStyle textStyle;
  final TextScaler scaler;
  final TextDirection direction;
  final ValueChanged<MeetingCell>? onToggle;

  /// 그릴 때마다 읽는 바뀌는 중의 값. 없으면 지금 답 그대로다
  final MeetingGridTransition? Function()? transition;

  MeetingGrid get grid => shading.grid;

  MeetingAnswer _shown(MeetingCell cell) =>
      preview?[cell] ?? shading.answerAt(cell);

  @override
  void paint(Canvas canvas, Size size) {
    final transition = this.transition?.call();
    if (geometry.shape.continuous) {
      _paintColumns(canvas, transition);
    } else {
      _paintTiles(canvas, transition);
    }
  }

  /// [cell] 자리([shape])에 다른 참여자 농도와 내 답을 칠한다
  void _paintCell(
    Canvas canvas,
    RRect shape,
    MeetingCell cell,
    MeetingGridTransition? transition,
  ) {
    final shade = colors.shade(
      availabilityShade(shading.othersCountAt(cell), shading.othersTotal),
    );
    if (shade != null) canvas.drawRRect(shape, Paint()..color = shade);
    final now = _shown(cell);
    final before = transition?.from[cell.index] ?? now;
    final t = before == now ? 1.0 : transition!.progress;
    if (before != now) _paintAnswer(canvas, shape, before, 1 - t);
    _paintAnswer(canvas, shape, now, t);
  }

  void _paintAnswer(
    Canvas canvas,
    RRect shape,
    MeetingAnswer answer,
    double opacity,
  ) {
    switch (answer) {
      case MeetingAnswer.available:
        canvas.drawRRect(
          shape,
          Paint()..color = colors.mine.withValues(alpha: opacity),
        );
      case MeetingAnswer.unavailable:
        colors.paintUnavailable(canvas, shape, opacity: opacity);
      case MeetingAnswer.unanswered:
        break;
    }
  }

  /// 시간별: 날짜마다 둥근 띠 하나에 칸을 채우고 정각은 실선, 그 밖의 칸 경계는 점선
  void _paintColumns(Canvas canvas, MeetingGridTransition? transition) {
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
        final rect = RRect.fromRectAndRadius(
          geometry.rectOf(column, row),
          Radius.zero,
        );
        if (cell == null) {
          canvas.drawRRect(rect, Paint()..color = colors.missing);
        } else {
          _paintCell(canvas, rect, cell, transition);
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
  void _paintTiles(Canvas canvas, MeetingGridTransition? transition) {
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
      _paintCell(canvas, rounded, cell, transition);
      canvas.drawRRect(rounded, border);
      _paintLabel(canvas, rect, cell);
    }
  }

  /// 칸 가운데 글자. 요일별은 요일, 날짜별은 날(첫 칸과 매달 1일은 '3.1'). 내 불가능 칸은 흐린 글자에 줄을 긋는다
  void _paintLabel(Canvas canvas, Rect rect, MeetingCell cell) {
    final answer = _shown(cell);
    final color = switch (answer) {
      MeetingAnswer.available => colors.onMine,
      MeetingAnswer.unavailable => colors.muted,
      MeetingAnswer.unanswered => switch (cell.day.weekday) {
        DateTime.sunday => colors.sunday,
        DateTime.saturday => colors.saturday,
        _ => colors.text,
      },
    };
    final text = grid.mode == MeetingMode.weekly
        ? weekdayName(cell.column)
        : cell.index == 0 || cell.day.day == 1
        ? '${cell.day.month}.${cell.day.day}'
        : '${cell.day.day}';
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          decoration: answer == MeetingAnswer.unavailable
              ? TextDecoration.lineThrough
              : null,
          decorationColor: color,
        ),
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

  /// 칸의 사람 수 안내: '다른 참여자 2명, 1명 불가'
  String? _hint(MeetingCell cell) {
    final others = shading.othersCountAt(cell);
    final unavailable = shading.othersUnavailableCountAt(cell);
    return [
      if (others > 0) '${shading.hasSelf ? '다른 참여자' : '참여자'} $others명',
      if (unavailable > 0) '$unavailable명 불가',
    ].join(', ');
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder {
    final onToggle = this.onToggle;
    return (size) => [
      for (final cell in grid.cells)
        CustomPainterSemantics(
          rect: geometry.rectOf(cell.column, cell.row),
          properties: SemanticsProperties(
            label: meetingCellLabel(grid, cell),
            value: switch (shading.answerAt(cell)) {
              MeetingAnswer.available => '가능',
              MeetingAnswer.unavailable => '불가능',
              MeetingAnswer.unanswered => null,
            },
            hint: _hint(cell),
            selected: shading.hasSelf
                ? shading.answerAt(cell) == MeetingAnswer.available
                : null,
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
      oldDelegate.preview != preview ||
      oldDelegate.colors != colors ||
      oldDelegate.scaler != scaler;

  @override
  bool shouldRebuildSemantics(MeetingGridPainter oldDelegate) =>
      oldDelegate.shading != shading ||
      oldDelegate.geometry != geometry ||
      (oldDelegate.onToggle == null) != (onToggle == null);
}
