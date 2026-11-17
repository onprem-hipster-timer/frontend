import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_brush.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_shading.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_run_highlight.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_geometry.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_painter.dart';
import 'package:momeet/shared/ui/ui.dart';

const _touchDevices = {
  PointerDeviceKind.touch,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.unknown,
};

/// 격자 칸 자리. 칸을 그리고 칠하기 동작을 받는다.
///
/// 붓([brush])은 가능 또는 불가능이다([brushStroke]). 마우스는 누른 채 끌면 바로 칠한다. 터치는 칸을 누르면
/// 그 칸만 바꾸고, 길게 누른 채 끌면 여러 칸을 칠한다(그냥 끌면 화면이 굴러간다). 이미 붓의 답인 칸에서
/// 시작하면 반대로 칠한다. 끈 범위는 시작 칸과 지금 칸을 꼭짓점으로 하는 사각형이고, 끄는 동안 결과를 그대로
/// 보이고 손을 떼면 [onPaint]로 넘긴다. 다른 방식으로 칠한 묶음은 바꾸지 않고 [onBlocked]로 알린다. 누르기 등으로
/// 내 칸이 바뀌거나 붓질에 함께 채워진 칸은 짧게 섞여 바뀐다(애니메이션을 줄였으면 바로).
///
/// [onPaint]가 없으면 칠할 수 없는 격자다. 칸을 누르거나 끌기 시작하면 칠하지 않고 [onLocked]를 부른다.
class MeetingGridCells extends StatefulWidget {
  const MeetingGridCells({
    super.key,
    required this.shading,
    required this.shape,
    required this.onPaint,
    this.brush = MeetingAnswer.available,
    this.onBlocked,
    this.highlight,
    this.onLocked,
  });

  final MeetingShading shading;
  final MeetingCellShape shape;
  final MeetingPaint? onPaint;
  final MeetingAnswer brush;
  final MeetingBlocked? onBlocked;

  /// 강조할 추천 시간 카드. 고정하면 그 칸이 보이게 굴리고, 칠하기 시작하면 고정을 푼다
  final MeetingRunHighlight? highlight;
  final VoidCallback? onLocked;

  @override
  State<MeetingGridCells> createState() => _MeetingGridCellsState();
}

class _MeetingGridCellsState extends State<MeetingGridCells>
    with SingleTickerProviderStateMixin {
  MeetingGridDrag? _drag;
  var _mouseDown = false;
  late final _fade = _AnswerFade(this);

  MeetingGrid get _grid => widget.shading.grid;

  @override
  void didUpdateWidget(MeetingGridCells oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shading != widget.shading) {
      _fade.changed(
        oldWidget.shading,
        widget.shading,
        animate: !MediaQuery.disableAnimationsOf(context),
      );
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  /// [cells]를 붓으로 한 번 칠한 결과
  MeetingStroke _stroke(List<MeetingCell> cells, {required bool clear}) =>
      brushStroke(
        _grid,
        widget.shading.answerAt,
        cells,
        widget.brush,
        clear: clear,
      );

  /// [cell]에서 시작하면 지우는지: 이미 붓의 답이면 지운다
  bool _clears(MeetingCell cell) =>
      widget.shading.answerAt(cell) == widget.brush;

  /// 끄는 중인 붓질의 결과
  MeetingStroke? get _result {
    final drag = _drag;
    return drag == null
        ? null
        : _stroke(_grid.within(drag.anchor, drag.current), clear: drag.clear);
  }

  /// 끄는 동안 보일 칸: 끈 사각형만. 함께 채워지는 칸은 손을 뗀 뒤 섞여 나타난다
  Map<MeetingCell, MeetingAnswer>? get _preview {
    final drag = _drag;
    if (drag == null) return null;
    final covered = _grid.within(drag.anchor, drag.current).toSet();
    return Map.of(_result!.changes)
      ..removeWhere((cell, _) => !covered.contains(cell));
  }

  void _begin(MeetingGridGeometry geometry, Offset position) {
    final place = geometry.placeAt(position);
    final cell = _grid.at(place.$1, place.$2);
    if (cell == null) return;
    if (widget.onPaint == null) return widget.onLocked?.call();
    widget.highlight?.unpin();
    setState(() => _drag = MeetingGridDrag(place, place, clear: _clears(cell)));
  }

  void _move(MeetingGridGeometry geometry, Offset position) {
    final drag = _drag;
    if (drag == null) return;
    final place = geometry.placeAt(position);
    if (place == drag.current) return;
    setState(
      () => _drag = MeetingGridDrag(drag.anchor, place, clear: drag.clear),
    );
  }

  void _end() {
    final result = _result;
    if (result == null) return;
    // 끄는 동안 이미 보인 칸은 다시 섞지 않는다
    _fade.shown = _preview;
    setState(() => _drag = null);
    _commit(result);
  }

  void _commit(MeetingStroke stroke) {
    if (stroke.changes.isNotEmpty) widget.onPaint?.call(stroke.changes);
    if (stroke.blocked.isNotEmpty) widget.onBlocked?.call(stroke.blocked);
  }

  void _cancel() {
    if (_drag != null) setState(() => _drag = null);
  }

  void _toggle(MeetingCell cell) {
    if (widget.onPaint == null) return widget.onLocked?.call();
    widget.highlight?.unpin();
    _commit(_stroke([cell], clear: _clears(cell)));
  }

  void _tapAt(MeetingGridGeometry geometry, Offset position) {
    final (column, row) = geometry.placeAt(position);
    final cell = _grid.at(column, row);
    if (cell != null) _toggle(cell);
  }

  void _pointerDown(MeetingGridGeometry geometry, PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.mouse ||
        event.buttons != kPrimaryMouseButton) {
      return;
    }
    _mouseDown = true;
    _begin(geometry, event.localPosition);
  }

  void _pointerUp({required bool cancelled}) {
    if (!_mouseDown) return;
    _mouseDown = false;
    cancelled ? _cancel() : _end();
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final colors = MeetingGridColors.of(context);
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = MeetingGridGeometry(
          _grid,
          widget.shape,
          constraints.maxWidth,
          scaler,
        );
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Listener(
            onPointerDown: (event) => _pointerDown(geometry, event),
            onPointerMove: (event) {
              if (_mouseDown) _move(geometry, event.localPosition);
            },
            onPointerUp: (_) => _pointerUp(cancelled: false),
            onPointerCancel: (_) => _pointerUp(cancelled: true),
            child: RawGestureDetector(
              excludeFromSemantics: true,
              gestures: _touchGestures(
                onTap: (at) => _tapAt(geometry, at),
                onStart: (at) => _begin(geometry, at),
                onMove: (at) => _move(geometry, at),
                onEnd: _end,
                onCancel: _cancel,
              ),
              child: _RevealPinned(
                highlight: widget.highlight,
                geometry: geometry,
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: geometry.size,
                    painter: MeetingGridPainter(
                      shading: widget.shading,
                      geometry: geometry,
                      preview: _preview,
                      transition: _fade.value,
                      highlighted: () => widget.highlight?.shown,
                      repaint: Listenable.merge([
                        _fade.controller,
                        widget.highlight,
                      ]),
                      colors: colors,
                      textStyle: textStyle,
                      scaler: scaler,
                      direction: direction,
                      onToggle: widget.onPaint == null ? null : _toggle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 터치의 누르기(한 칸)와 길게 누른 뒤 끌기(여러 칸)
Map<Type, GestureRecognizerFactory> _touchGestures({
  required ValueChanged<Offset> onTap,
  required ValueChanged<Offset> onStart,
  required ValueChanged<Offset> onMove,
  required VoidCallback onEnd,
  required VoidCallback onCancel,
}) => {
  TapGestureRecognizer:
      GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
        () => TapGestureRecognizer(supportedDevices: _touchDevices),
        (recognizer) =>
            recognizer.onTapUp = (details) => onTap(details.localPosition),
      ),
  LongPressGestureRecognizer:
      GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
        () => LongPressGestureRecognizer(supportedDevices: _touchDevices),
        (recognizer) => recognizer
          ..onLongPressStart = (details) {
            HapticFeedback.selectionClick();
            onStart(details.localPosition);
          }
          ..onLongPressMoveUpdate = (details) {
            onMove(details.localPosition);
          }
          ..onLongPressEnd = (_) {
            onEnd();
          }
          ..onLongPressCancel = onCancel,
      ),
};

/// 추천 시간 카드를 고정하면 그 칸이 화면에 보이게 굴린다(애니메이션을 줄였으면 바로). 마우스를 올린 것만으로는
/// 굴리지 않는다
class _RevealPinned extends StatefulWidget {
  const _RevealPinned({
    required this.highlight,
    required this.geometry,
    required this.child,
  });

  final MeetingRunHighlight? highlight;
  final MeetingGridGeometry geometry;
  final Widget child;

  @override
  State<_RevealPinned> createState() => _RevealPinnedState();
}

class _RevealPinnedState extends State<_RevealPinned> {
  MeetingRunKey? _pinned;

  @override
  void initState() {
    super.initState();
    _pinned = widget.highlight?.pinned;
    widget.highlight?.addListener(_changed);
  }

  @override
  void didUpdateWidget(_RevealPinned oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlight != widget.highlight) {
      oldWidget.highlight?.removeListener(_changed);
      widget.highlight?.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.highlight?.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final pinned = widget.highlight?.pinned;
    if (pinned == _pinned) return;
    _pinned = pinned;
    final grid = widget.geometry.grid;
    if (pinned == null || pinned.last >= grid.cells.length) return;
    final rect = widget.geometry
        .runRects(pinned.first, pinned.last)
        .reduce((a, b) => a.expandToInclude(b));
    showAppRect(context, rect.inflate(16));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// 바뀐 내 칸을 이전 답에서 지금 답으로 짧게 섞는다
class _AnswerFade {
  _AnswerFade(TickerProvider vsync)
    : controller = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 180),
        value: 1,
      );

  final AnimationController controller;

  /// 섞기 시작한 이전 답(칸 자리마다)
  List<MeetingAnswer>? _from;

  /// 끄는 동안 이미 보인 결과. 다음 바뀜에서 이 칸은 섞지 않는다
  Map<MeetingCell, MeetingAnswer>? shown;

  /// [before]에서 [after]로 바뀌었다. 내 답이 바뀐 칸이 있으면 섞는다
  void changed(
    MeetingShading before,
    MeetingShading after, {
    required bool animate,
  }) {
    final shown = this.shown;
    this.shown = null;
    if (!animate || before.grid != after.grid) return;
    final from = [
      for (final cell in before.grid.cells)
        shown?[cell] ?? before.answerAt(cell),
    ];
    if (!after.grid.cells.any(
      (cell) => from[cell.index] != after.answerAt(cell),
    )) {
      return;
    }
    _from = from;
    controller.forward(from: 0);
  }

  MeetingGridTransition? value() {
    final from = _from;
    return from == null || controller.isCompleted
        ? null
        : (from: from, progress: Curves.easeOut.transform(controller.value));
  }

  void dispose() => controller.dispose();
}
