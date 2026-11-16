import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_shading.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_geometry.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_painter.dart';

const _touchDevices = {
  PointerDeviceKind.touch,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.unknown,
};

/// 격자 칸 자리. 칸을 그리고 칠하기 동작을 받는다.
///
/// 마우스는 누른 채 끌면 바로 칠한다. 터치는 칸을 누르면 그 칸만 바꾸고, 길게 누른 채 끌면 여러 칸을
/// 칠한다(그냥 끌면 화면이 굴러간다). 칠한 칸에서 시작하면 지운다. 끈 범위는 시작 칸과 지금 칸을
/// 꼭짓점으로 하는 사각형이고, 손을 떼면 [onPaint]로 넘긴다.
///
/// [onPaint]가 없으면 칠할 수 없는 격자다. 칸을 누르거나 끌기 시작하면 칠하지 않고 [onLocked]를 부른다.
class MeetingGridCells extends StatefulWidget {
  const MeetingGridCells({
    super.key,
    required this.shading,
    required this.shape,
    required this.onPaint,
    this.onLocked,
  });

  final MeetingShading shading;
  final MeetingCellShape shape;
  final MeetingPaint? onPaint;
  final VoidCallback? onLocked;

  @override
  State<MeetingGridCells> createState() => _MeetingGridCellsState();
}

class _MeetingGridCellsState extends State<MeetingGridCells> {
  MeetingGridDrag? _drag;
  var _mouseDown = false;

  MeetingGrid get _grid => widget.shading.grid;

  void _begin(MeetingGridGeometry geometry, Offset position) {
    final place = geometry.placeAt(position);
    final cell = _grid.at(place.$1, place.$2);
    if (cell == null) return;
    if (widget.onPaint == null) return widget.onLocked?.call();
    setState(
      () => _drag = MeetingGridDrag(
        place,
        place,
        available: !widget.shading.isMine(cell),
      ),
    );
  }

  void _move(MeetingGridGeometry geometry, Offset position) {
    final drag = _drag;
    if (drag == null) return;
    final place = geometry.placeAt(position);
    if (place == drag.current) return;
    setState(
      () => _drag = MeetingGridDrag(
        drag.anchor,
        place,
        available: drag.available,
      ),
    );
  }

  void _end() {
    final drag = _drag;
    if (drag == null) return;
    setState(() => _drag = null);
    widget.onPaint?.call(
      _grid.within(drag.anchor, drag.current),
      available: drag.available,
    );
  }

  void _cancel() {
    if (_drag != null) setState(() => _drag = null);
  }

  void _toggle(MeetingCell cell) {
    final onPaint = widget.onPaint;
    if (onPaint == null) return widget.onLocked?.call();
    onPaint([cell], available: !widget.shading.isMine(cell));
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

  /// 터치의 누르기(한 칸)와 길게 누른 뒤 끌기(여러 칸)
  Map<Type, GestureRecognizerFactory> _touchGestures(
    MeetingGridGeometry geometry,
  ) => {
    TapGestureRecognizer:
        GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(supportedDevices: _touchDevices),
          (recognizer) =>
              recognizer.onTapUp = (details) =>
                  _tapAt(geometry, details.localPosition),
        ),
    LongPressGestureRecognizer:
        GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(supportedDevices: _touchDevices),
          (recognizer) {
            recognizer
              ..onLongPressStart = (details) {
                HapticFeedback.selectionClick();
                _begin(geometry, details.localPosition);
              }
              ..onLongPressMoveUpdate = (details) {
                _move(geometry, details.localPosition);
              }
              ..onLongPressEnd = (_) {
                _end();
              }
              ..onLongPressCancel = _cancel;
          },
        ),
  };

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
              gestures: _touchGestures(geometry),
              child: RepaintBoundary(
                child: CustomPaint(
                  size: geometry.size,
                  painter: MeetingGridPainter(
                    shading: widget.shading,
                    geometry: geometry,
                    drag: _drag,
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
        );
      },
    );
  }
}
