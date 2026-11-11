import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

/// 다이얼 한 바퀴의 기본 시간
const dialFaceDuration = Duration(minutes: 60);

/// [duration]을 담는 다이얼 한 바퀴 시간.
///
/// 60분 이하는 60분, 더 길면 60분 단위로 올린다 (90분 → 120분).
Duration dialFaceFor(Duration duration) {
  if (duration <= dialFaceDuration) return dialFaceDuration;
  final hours = (duration.inSeconds + 3599) ~/ 3600;
  return Duration(minutes: hours * 60);
}

/// 다이얼로 고르는 시간의 단위. 끌기를 놓을 때, 스크린 리더와 키보드로 바꿀 때 이 단위로 옮긴다
const dialStep = Duration(seconds: 30);

/// 다이얼을 끄는 동안 원판과 시계가 따라가는 단위
const dialDragStep = Duration(seconds: 10);

/// 한 변이 [size]인 다이얼 위의 [local] 위치가 가리키는 시간.
///
/// 12시에서 시계 방향으로 잰 각도를 [step] 단위로 반올림하고 [step]~[face]로 자른다.
/// 중심에서 [size]의 5% 안쪽은 각도가 불안정해 null.
Duration? dialDurationAt(
  Offset local,
  double size,
  Duration face, {
  Duration step = dialStep,
}) {
  final center = size / 2;
  final dx = local.dx - center;
  final dy = local.dy - center;
  if (math.sqrt(dx * dx + dy * dy) < size * 0.05) return null;

  var angle = math.atan2(dx, -dy);
  if (angle < 0) angle += 2 * math.pi;
  final steps = face.inSeconds ~/ step.inSeconds;
  return step * (angle / (2 * math.pi) * steps).round().clamp(1, steps);
}

/// [duration]을 가장 가까운 [dialStep] 단위로 반올림하고 [dialStep]~[face]로 자른 값
Duration snapDialDuration(Duration duration, Duration face) {
  final steps = face.inSeconds ~/ dialStep.inSeconds;
  return dialStep *
      (duration.inMilliseconds / dialStep.inMilliseconds).round().clamp(
        1,
        steps,
      );
}

/// 남은 시간을 12시부터 시계 방향으로 채운 원판으로 보여 주는 다이얼.
///
/// [onChanged]가 있으면 다이얼을 누르거나 끌어 시간을 고른다. 끄는 동안 원판은 [dialDragStep] 단위로 손가락을 따라가고,
/// [onPreview]에는 놓으면 고를 값(가장 가까운 [dialStep] 단위)을 알린다. 놓거나 끌기가 취소되면 가장 가까운 [dialStep] 단위로 맞춰 [onChanged]를 부르고
/// [onPreview]에 null을 넘기며, 원판은 맞춘 값으로 짧게 움직인다. 끄는 동안 [dialStep] 경계를 넘을 때마다 선택 햅틱을 낸다.
/// 스크린 리더에는 [label] 이름의 슬라이더로 보이고, 초점을 받으면 방향키(위·오른쪽은 늘리기, 아래·왼쪽은 줄이기)와
/// +·-로 [dialStep]씩 [dialStep]~한 바퀴 시간 안에서 바꾼다.
class TimerDial extends StatefulWidget {
  const TimerDial({
    super.key,
    required this.remaining,
    required this.color,
    this.face,
    this.onChanged,
    this.onPreview,
    this.label,
    this.labels = true,
  });

  final Duration remaining;
  final Color color;

  /// 한 바퀴 시간. 없으면 [dialFaceFor] ([remaining])
  final Duration? face;
  final ValueChanged<Duration>? onChanged;

  /// 끄는 동안 손가락이 가리키는 값. 끌기가 끝나면 null
  final ValueChanged<Duration?>? onPreview;

  /// 고르는 시간의 이름 (스크린 리더용)
  final String? label;

  /// 눈금 숫자를 그릴지. 끄면 원판을 그만큼 크게 그린다
  final bool labels;

  @override
  State<TimerDial> createState() => _TimerDialState();
}

class _TimerDialState extends State<TimerDial>
    with SingleTickerProviderStateMixin {
  static const _stepShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowUp): _StepIntent(1),
    SingleActivator(LogicalKeyboardKey.arrowRight): _StepIntent(1),
    CharacterActivator('+'): _StepIntent(1),
    SingleActivator(LogicalKeyboardKey.arrowDown): _StepIntent(-1),
    SingleActivator(LogicalKeyboardKey.arrowLeft): _StepIntent(-1),
    CharacterActivator('-'): _StepIntent(-1),
  };

  /// 끄는 동안 손가락이 가리키는 값. 끌지 않으면 null
  Duration? _dragged;

  /// 놓은 뒤 맞춘 값으로 움직이기 시작한 원판의 비율
  double? _settleFrom;

  late final _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  Duration get _face => widget.face ?? dialFaceFor(widget.remaining);

  double _fraction(Duration face) {
    final target =
        (_dragged ?? widget.remaining).inMicroseconds / face.inMicroseconds;
    final from = _settleFrom;
    if (from == null || !_settle.isAnimating) return target;
    return from + (target - from) * Curves.easeOut.transform(_settle.value);
  }

  void _drag(Offset local, double side) {
    final picked = dialDurationAt(local, side, _face, step: dialDragStep);
    if (picked == null || picked == _dragged) return;
    final previous = _dragged;
    if (previous != null &&
        previous.inSeconds ~/ dialStep.inSeconds !=
            picked.inSeconds ~/ dialStep.inSeconds) {
      HapticFeedback.selectionClick();
    }
    setState(() => _dragged = picked);
    widget.onPreview?.call(snapDialDuration(picked, _face));
  }

  void _release() {
    final dragged = _dragged;
    if (dragged == null) return;
    final face = _face;
    final snapped = snapDialDuration(dragged, face);
    setState(() {
      _settleFrom = dragged.inMicroseconds / face.inMicroseconds;
      _dragged = null;
    });
    _settle.forward(from: 0);
    widget.onPreview?.call(null);
    if (snapped != widget.remaining) widget.onChanged?.call(snapped);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dialFace = _face;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        Widget dial = SizedBox.square(
          dimension: side,
          child: AnimatedBuilder(
            animation: _settle,
            builder: (context, _) => CustomPaint(
              painter: _TimerDialPainter(
                fraction: _fraction(dialFace),
                face: dialFace,
                fillColor: widget.color,
                faceColor: colorScheme.surfaceContainerHighest,
                tickColor: colorScheme.onSurfaceVariant,
                knobColor: colorScheme.onSurfaceVariant,
                labels: widget.labels,
                labelStyle:
                    Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: side * 0.055,
                    ) ??
                    TextStyle(fontSize: side * 0.055),
              ),
            ),
          ),
        );

        final onChanged = widget.onChanged;
        if (onChanged != null) {
          final remaining = widget.remaining;
          Duration? stepped(int steps) => _stepped(steps, dialFace);
          final up = stepped(1);
          final down = stepped(-1);
          dial = Semantics(
            container: true,
            slider: true,
            label: widget.label,
            value: _durationText(remaining),
            increasedValue: up == null ? null : _durationText(up),
            decreasedValue: down == null ? null : _durationText(down),
            onIncrease: up == null ? null : () => onChanged(up),
            onDecrease: down == null ? null : () => onChanged(down),
            child: FocusableActionDetector(
              shortcuts: _stepShortcuts,
              actions: {
                _StepIntent: CallbackAction<_StepIntent>(
                  onInvoke: (intent) {
                    final next = stepped(intent.steps);
                    if (next != null) onChanged(next);
                    return null;
                  },
                ),
              },
              // 끌기는 스크린 리더에 늘리기·줄이기로 대신 내보인다
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onPanDown: (details) => _drag(details.localPosition, side),
                onPanUpdate: (details) => _drag(details.localPosition, side),
                onPanEnd: (_) => _release(),
                onPanCancel: _release,
                child: dial,
              ),
            ),
          );
        }

        return Center(child: dial);
      },
    );
  }

  /// steps번 [dialStep]만큼 옮긴 값. [dialStep]~한 바퀴 시간 밖이라 그 쪽으로 옮겨지지 않으면 null
  Duration? _stepped(int steps, Duration face) {
    final remaining = widget.remaining;
    final next = Duration(
      seconds: (remaining.inSeconds + steps * dialStep.inSeconds).clamp(
        dialStep.inSeconds,
        face.inSeconds,
      ),
    );
    final moved = steps > 0 ? next > remaining : next < remaining;
    return moved ? next : null;
  }

  static String _durationText(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (seconds == 0) return '$minutes분';
    return minutes == 0 ? '$seconds초' : '$minutes분 $seconds초';
  }
}

/// 다이얼 시간을 [steps]번 [dialStep]만큼 옮긴다
class _StepIntent extends Intent {
  const _StepIntent(this.steps);

  final int steps;
}

class _TimerDialPainter extends CustomPainter {
  _TimerDialPainter({
    required double fraction,
    required this.face,
    required this.fillColor,
    required this.faceColor,
    required this.tickColor,
    required this.knobColor,
    required this.labels,
    required this.labelStyle,
  }) : fraction = fraction.clamp(0.0, 1.0);

  /// 숫자를 그리는 가장 작은 다이얼 한 변
  static const _minLabelSide = 120.0;

  final double fraction;
  final Duration face;
  final Color fillColor;
  final Color faceColor;
  final Color tickColor;
  final Color knobColor;
  final bool labels;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    if (side <= 0) return;
    final center = size.center(Offset.zero);
    final showLabels = labels && side >= _minLabelSide;
    final radius = side / 2 * (showLabels ? 0.78 : 0.96);

    canvas.drawCircle(center, radius, Paint()..color = faceColor);

    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * fraction,
        true,
        Paint()..color = fillColor,
      );
    }

    // 60칸 눈금, 한 바퀴의 1/12마다 긴 눈금
    for (var i = 0; i < 60; i++) {
      final major = i % 5 == 0;
      final angle = 2 * math.pi * i / 60 - math.pi / 2;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * radius * (major ? 0.86 : 0.93),
        center + direction * radius,
        Paint()
          ..color = tickColor
          ..strokeWidth = math.max(1, side * (major ? 0.012 : 0.005)),
      );
    }

    if (showLabels) {
      final step = face.inMinutes ~/ 12;
      final labelRadius = side / 2 * 0.89;
      for (var i = 0; i < 12; i++) {
        final angle = 2 * math.pi * i / 12 - math.pi / 2;
        final painter = TextPainter(
          text: TextSpan(text: '${i * step}', style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        final position =
            center +
            Offset(math.cos(angle), math.sin(angle)) * labelRadius -
            Offset(painter.width / 2, painter.height / 2);
        painter.paint(canvas, position);
        painter.dispose();
      }
    }

    canvas.drawCircle(center, radius * 0.08, Paint()..color = knobColor);
  }

  @override
  bool shouldRepaint(_TimerDialPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.face != face ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.faceColor != faceColor ||
      oldDelegate.tickColor != tickColor ||
      oldDelegate.knobColor != knobColor ||
      oldDelegate.labelStyle != labelStyle ||
      oldDelegate.labels != labels;
}
