import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 칸마다 [changes]의 답으로 칠하거나 지운다
typedef MeetingPaint = void Function(Map<MeetingCell, MeetingAnswer> changes);

/// 다른 방식으로 칠한 묶음(묶음의 칸들)이라 붓이 칠하지 못했다
typedef MeetingBlocked = void Function(List<List<MeetingCell>> groups);

/// 일요일(0)·토요일(6) 글자 색. 평일은 null
Color? meetingWeekendColor(BuildContext context, int sundayFirstColumn) =>
    switch (sundayFirstColumn) {
      0 => AppColors.of(context).holiday,
      6 => AppColors.of(context).saturday,
      _ => null,
    };

/// 칸 모양. 시간별은 날짜마다 이어진 세로 띠, 날짜별·요일별은 떨어진 타일이다
@immutable
class MeetingCellShape {
  const MeetingCellShape({
    required this.columnGap,
    required this.rowGap,
    required this.height,
    this.continuous = false,
  });

  /// 시간별: 슬롯 분에 비례하는 줄 높이(30분이면 26), 너무 작거나 크지 않게. [minRowHeight]보다는 높다
  factory MeetingCellShape.hourly({
    required int slotMinutes,
    required double columnGap,
    double minRowHeight = 0,
  }) {
    final rowHeight = math.max(
      (26 * slotMinutes / 30).clamp(20, 64).toDouble(),
      minRowHeight,
    );
    return MeetingCellShape(
      columnGap: columnGap,
      rowGap: 0,
      height: (_, _) => rowHeight,
      continuous: true,
    );
  }

  /// 날짜별 달력 칸. 날짜 숫자가 들어갈 높이는 지킨다
  static final daily = MeetingCellShape(
    columnGap: 4,
    rowGap: 4,
    height: (width, scaler) => math.max(
      (width * 0.75).clamp(40, 64).toDouble(),
      scaler.scale(14) + 16,
    ),
  );

  /// 요일별 일곱 칸
  static final weekly = MeetingCellShape(
    columnGap: 4,
    rowGap: 4,
    height: (width, scaler) =>
        math.max((width * 0.9).clamp(48, 72).toDouble(), scaler.scale(14) + 24),
  );

  final double columnGap;
  final double rowGap;

  /// 칸 너비와 글자 배율에 따른 칸 높이
  final double Function(double cellWidth, TextScaler scaler) height;

  /// 한 열의 칸이 맞닿은 띠인지
  final bool continuous;
}

/// 너비가 [width]일 때 칸의 자리와 크기
@immutable
class MeetingGridGeometry {
  MeetingGridGeometry(this.grid, this.shape, this.width, TextScaler scaler)
    : cellWidth = grid.columns == 0
          ? 0
          : (width - shape.columnGap * (grid.columns - 1)) / grid.columns {
    cellHeight = shape.height(cellWidth, scaler);
  }

  final MeetingGrid grid;
  final MeetingCellShape shape;
  final double width;
  final double cellWidth;
  late final double cellHeight;

  Size get size => Size(
    width,
    grid.rows * cellHeight + math.max(0, grid.rows - 1) * shape.rowGap,
  );

  Rect rectOf(int column, int row) => Rect.fromLTWH(
    column * (cellWidth + shape.columnGap),
    row * (cellHeight + shape.rowGap),
    cellWidth,
    cellHeight,
  );

  /// 시간별의 시 묶음: 같은 정시(벽시계 시)에 드는 줄들의 처음과 끝, 위에서부터. 하루 범위가 정시에 시작하거나
  /// 끝나지 않으면 처음·끝 묶음은 한 시간보다 짧고, 슬롯이 15분이면 네 줄, 60분이면 한 줄이 한 묶음이다
  List<(int, int)> hourBlocks() {
    final blocks = <(int, int)>[];
    for (var row = 0; row < grid.rowMinutes.length; row++) {
      final hour = grid.rowMinutes[row] ~/ 60;
      if (blocks.isNotEmpty && grid.rowMinutes[blocks.last.$1] ~/ 60 == hour) {
        blocks.last = (blocks.last.$1, row);
      } else {
        blocks.add((row, row));
      }
    }
    return blocks;
  }

  /// [column] 열의 [block] 시 묶음 모양: 모서리를 조금 둥글린 사각형. 이웃한 묶음과 틈 없이 맞닿는다
  RRect hourBlock(int column, (int, int) block) => RRect.fromRectAndRadius(
    rectOf(column, block.$1).expandToInclude(rectOf(column, block.$2)),
    const Radius.circular(AppRadius.sm),
  );

  /// 칸 자리 [first]~[last](이어진 칸)를 두르는 사각형들: 시간별은 열마다, 날짜별·요일별은 줄마다 하나
  List<Rect> runRects(int first, int last) {
    final groups = <int, Rect>{};
    for (var i = first; i <= last && i < grid.cells.length; i++) {
      final cell = grid.cells[i];
      final rect = rectOf(cell.column, cell.row);
      groups.update(
        shape.continuous ? cell.column : cell.row,
        (r) => r.expandToInclude(rect),
        ifAbsent: () => rect,
      );
    }
    return groups.values.toList();
  }

  /// [position]이 든 자리. 칸 사이 틈은 앞 칸, 격자 밖은 가장자리 자리다
  (int, int) placeAt(Offset position) => (
    (position.dx / (cellWidth + shape.columnGap)).floor().clamp(
      0,
      grid.columns - 1,
    ),
    (position.dy / (cellHeight + shape.rowGap)).floor().clamp(0, grid.rows - 1),
  );

  @override
  bool operator ==(Object other) =>
      other is MeetingGridGeometry &&
      other.grid == grid &&
      other.width == width &&
      other.cellHeight == cellHeight;

  @override
  int get hashCode => Object.hash(grid, width, cellHeight);
}

/// 끄는 중인 사각형(시작 자리와 지금 자리)과 지우는지(시작 칸이 이미 붓의 답이면 지운다)
@immutable
class MeetingGridDrag {
  const MeetingGridDrag(this.anchor, this.current, {required this.clear});

  final (int, int) anchor;
  final (int, int) current;
  final bool clear;
}

/// 격자 색. 다른 참여자 농도는 내 칸과 같은 색을 옅게 깐다. 내 불가능 칸은 그 위를 바탕색으로 덮어 흐리게 하고
/// 빗금을 긋는다(색 없이도 가려진다)
@immutable
class MeetingGridColors {
  const MeetingGridColors({
    required this.base,
    required this.border,
    required this.line,
    required this.mine,
    required this.onMine,
    required this.veil,
    required this.hatch,
    required this.muted,
    required this.ring,
    required this.ringInner,
    required this.dim,
    required this.missing,
    required this.text,
    required this.sunday,
    required this.saturday,
  });

  factory MeetingGridColors.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final app = AppColors.of(context);
    return MeetingGridColors(
      base: scheme.surfaceContainerLowest,
      border: scheme.outline.withValues(alpha: 0.55),
      line: scheme.outlineVariant,
      mine: scheme.primary,
      onMine: scheme.onPrimary,
      veil: scheme.surfaceContainerLowest.withValues(alpha: 0.5),
      hatch: scheme.onSurfaceVariant.withValues(alpha: 0.5),
      muted: scheme.onSurfaceVariant,
      ring: scheme.onSurface,
      ringInner: scheme.surface,
      dim: scheme.surface.withValues(alpha: 0.35),
      missing: scheme.onSurface.withValues(alpha: 0.06),
      text: scheme.onSurface,
      sunday: app.holiday,
      saturday: app.saturday,
    );
  }

  final Color base;
  final Color border;
  final Color line;

  /// 내 가능 칸
  final Color mine;
  final Color onMine;

  /// 내 불가능 칸을 흐리게 덮는 색
  final Color veil;

  /// 내 불가능 칸의 빗금
  final Color hatch;

  /// 내 불가능 칸의 글자
  final Color muted;

  /// 강조한 추천 시간의 테두리(바깥 진한 줄과 안쪽 밝은 줄)와, 그 밖의 칸을 옅게 덮는 색
  final Color ring;
  final Color ringInner;
  final Color dim;

  /// 일광 절약 시간으로 없는 시각의 자리
  final Color missing;
  final Color text;
  final Color sunday;
  final Color saturday;

  /// 농도 단계(1~5)마다 덮는 내 칸 색의 불투명도
  static const _shadeAlphas = [0.0, 0.16, 0.3, 0.44, 0.58, 0.72];

  /// [level] 단계 농도의 색. 0이면 null
  Color? shade(int level) =>
      level == 0 ? null : mine.withValues(alpha: _shadeAlphas[level]);

  /// [shape] 안을 내 불가능 칸으로 덮는다: 흐리게 덮고 빗금. [opacity]는 바뀌는 중의 진하기다
  void paintUnavailable(Canvas canvas, RRect shape, {double opacity = 1}) {
    if (opacity <= 0) return;
    final bounds = shape.outerRect;
    final stroke = Paint()
      ..color = hatch.withValues(alpha: hatch.a * opacity)
      ..strokeWidth = 1;
    canvas
      ..save()
      ..clipRRect(shape)
      ..drawRect(
        bounds,
        Paint()..color = veil.withValues(alpha: veil.a * opacity),
      );
    // 이웃한 칸의 빗금이 이어지게 화면 좌표의 같은 사선 위에 긋는다
    const gap = 6.0;
    final first = ((bounds.left + bounds.top) / gap).floor() * gap;
    for (var c = first; c < bounds.right + bounds.bottom; c += gap) {
      canvas.drawLine(
        Offset(c - bounds.top, bounds.top),
        Offset(c - bounds.bottom, bounds.bottom),
        stroke,
      );
    }
    canvas.restore();
  }

  @override
  bool operator ==(Object other) =>
      other is MeetingGridColors &&
      other.base == base &&
      other.border == border &&
      other.mine == mine &&
      other.veil == veil &&
      other.text == text;

  @override
  int get hashCode => Object.hash(base, border, mine, veil, text);
}
