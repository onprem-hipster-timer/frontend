import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

/// 칠하는 동안 손(마우스·손가락)이 보이는 자리의 위아래 끝 가까이에 있으면 그쪽으로 화면을 부드럽게 굴린다.
///
/// 보이는 자리는 격자를 담아 위아래로 굴러가는 영역에서 머리띠 같은 위 여백(`MediaQuery` padding)을 뺀
/// 곳이다. 끝에 가까울수록(끝을 넘으면 가장) 빠르고, 격자의 그쪽 끝이 보이면 멈춘다. 화면이 굴러가면(휠 포함)
/// 그 프레임을 그린 뒤 [onScrolled]에 손의 화면 자리를 넘겨 손 아래 칸을 다시 고르게 한다.
///
/// 테스트: test/features/meeting/presentation/widgets/meeting_grid_stroke_scroll_test.dart
class MeetingGridAutoScroll {
  MeetingGridAutoScroll({
    required TickerProvider vsync,
    required this.onScrolled,
  }) {
    _ticker = vsync.createTicker(_tick);
  }

  final ValueChanged<Offset> onScrolled;
  late final Ticker _ticker;

  /// 끝에서 이 거리 안이면 굴린다
  static const edge = 56.0;

  /// 끝에 닿았을 때 1초에 굴리는 거리
  static const maxSpeed = 1100.0;

  ScrollableState? _scrollable;
  RenderBox? _grid;
  EdgeInsets _insets = EdgeInsets.zero;
  Offset? _pointer;
  Duration? _last;
  var _reselecting = false;

  /// 붓질을 시작한다. [context]는 격자 칸 자리다
  void begin(BuildContext context, Offset pointer) {
    end();
    final scrollable = Scrollable.maybeOf(context, axis: Axis.vertical);
    if (scrollable == null) return;
    _scrollable = scrollable;
    scrollable.position.addListener(_scrolled);
    _grid = context.findRenderObject() as RenderBox?;
    _insets = MediaQuery.paddingOf(context);
    moved(pointer);
  }

  /// 손이 화면의 [pointer] 자리로 왔다
  void moved(Offset pointer) {
    _pointer = pointer;
    if (_scrollable != null && !_ticker.isActive && _velocity() != 0) {
      _last = null;
      _ticker.start();
    }
  }

  /// 붓질이 끝났다
  void end() {
    _ticker.stop();
    _scrollable?.position.removeListener(_scrolled);
    _scrollable = null;
    _grid = null;
    _pointer = null;
  }

  void dispose() {
    end();
    _ticker.dispose();
  }

  static Rect _globalRect(RenderBox box) => MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );

  /// 굴러가는 영역 중 보이는 자리(화면 좌표)
  Rect? get _visible {
    final box = _scrollable?.context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final viewport = _globalRect(box);
    return Rect.fromLTRB(
      viewport.left,
      math.max(viewport.top, _insets.top),
      viewport.right,
      viewport.bottom - _insets.bottom,
    );
  }

  /// 1초에 굴릴 거리. 아래로 +, 위로 -, 굴리지 않으면 0
  double _velocity() {
    final pointer = _pointer;
    final visible = _visible;
    final grid = _grid;
    if (pointer == null || visible == null || grid == null || !grid.attached) {
      return 0;
    }
    final cells = _globalRect(grid);
    double speed(double depth) =>
        maxSpeed * math.pow((depth / edge).clamp(0.15, 1.0), 2);
    final below = pointer.dy - (visible.bottom - edge);
    if (below > 0 && cells.bottom > visible.bottom + 0.5) return speed(below);
    final above = visible.top + edge - pointer.dy;
    if (above > 0 && cells.top < visible.top - 0.5) return -speed(above);
    return 0;
  }

  void _tick(Duration elapsed) {
    final last = _last;
    _last = elapsed;
    final position = _scrollable?.position;
    final velocity = _velocity();
    if (position == null || velocity == 0) return _ticker.stop();
    if (last == null) return;
    final visible = _visible!;
    final cells = _globalRect(_grid!);
    final step = velocity * (elapsed - last).inMicroseconds / 1e6;
    // 격자 끝을 넘어 굴리지 않는다
    final delta = step > 0
        ? math.min(step, cells.bottom - visible.bottom)
        : math.max(step, cells.top - visible.top);
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target != position.pixels) position.jumpTo(target);
  }

  /// 굴러갔다: 새 자리를 그린 뒤 손 아래 칸을 다시 고르게 한다
  void _scrolled() {
    if (_reselecting) return;
    _reselecting = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _reselecting = false;
      final pointer = _pointer;
      if (pointer != null) onScrolled(pointer);
    });
  }
}
