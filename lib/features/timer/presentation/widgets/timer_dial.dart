import 'dart:math' as math;

import 'package:flutter/material.dart';
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

/// 한 변이 [size]인 다이얼 위의 [local] 위치가 가리키는 시간.
///
/// 12시에서 시계 방향으로 잰 각도를 분 단위로 반올림하고 1~[face] 분으로 자른다.
/// 중심에서 [size]의 5% 안쪽은 각도가 불안정해 null.
Duration? dialDurationAt(Offset local, double size, Duration face) {
  final center = size / 2;
  final dx = local.dx - center;
  final dy = local.dy - center;
  if (math.sqrt(dx * dx + dy * dy) < size * 0.05) return null;

  var angle = math.atan2(dx, -dy);
  if (angle < 0) angle += 2 * math.pi;
  final minutes = (angle / (2 * math.pi) * face.inMinutes).round().clamp(
    1,
    face.inMinutes,
  );
  return Duration(minutes: minutes);
}

/// 남은 시간을 12시부터 시계 방향으로 채운 원판으로 보여 주는 다이얼.
///
/// [onChanged]가 있으면 다이얼을 누르거나 끌어 시간을 고른다. 스크린 리더에는 [label] 이름의 분 단위 슬라이더로
/// 보이고, 초점을 받으면 방향키(위·오른쪽은 늘리기, 아래·왼쪽은 줄이기)와 +·-로 1분씩 1분~한 바퀴 시간 안에서 바꾼다.
class TimerDial extends StatelessWidget {
  const TimerDial({
    super.key,
    required this.remaining,
    required this.color,
    this.face,
    this.onChanged,
    this.label,
  });

  final Duration remaining;
  final Color color;

  /// 한 바퀴 시간. 없으면 [dialFaceFor] ([remaining])
  final Duration? face;
  final ValueChanged<Duration>? onChanged;

  /// 고르는 시간의 이름 (스크린 리더용)
  final String? label;

  static const _stepShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowUp): _StepIntent(1),
    SingleActivator(LogicalKeyboardKey.arrowRight): _StepIntent(1),
    CharacterActivator('+'): _StepIntent(1),
    SingleActivator(LogicalKeyboardKey.arrowDown): _StepIntent(-1),
    SingleActivator(LogicalKeyboardKey.arrowLeft): _StepIntent(-1),
    CharacterActivator('-'): _StepIntent(-1),
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dialFace = face ?? dialFaceFor(remaining);

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        Widget dial = SizedBox.square(
          dimension: side,
          child: CustomPaint(
            painter: _TimerDialPainter(
              fraction: remaining.inMicroseconds / dialFace.inMicroseconds,
              face: dialFace,
              fillColor: color,
              faceColor: colorScheme.surfaceContainerHighest,
              tickColor: colorScheme.onSurfaceVariant,
              knobColor: colorScheme.onSurfaceVariant,
              labelStyle:
                  Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: side * 0.055,
                  ) ??
                  TextStyle(fontSize: side * 0.055),
            ),
          ),
        );

        final onChanged = this.onChanged;
        if (onChanged != null) {
          void pick(Offset local) {
            final picked = dialDurationAt(local, side, dialFace);
            if (picked != null && picked != remaining) onChanged(picked);
          }

          // minutes분 옮긴 값. 1분~한 바퀴 시간 밖이라 그대로면 null
          Duration? stepped(int minutes) {
            final next = Duration(
              minutes: (remaining.inMinutes + minutes).clamp(
                1,
                dialFace.inMinutes,
              ),
            );
            return next == remaining ? null : next;
          }

          final up = stepped(1);
          final down = stepped(-1);
          dial = Semantics(
            container: true,
            slider: true,
            label: label,
            value: _minutesText(remaining),
            increasedValue: up == null ? null : _minutesText(up),
            decreasedValue: down == null ? null : _minutesText(down),
            onIncrease: up == null ? null : () => onChanged(up),
            onDecrease: down == null ? null : () => onChanged(down),
            child: FocusableActionDetector(
              shortcuts: _stepShortcuts,
              actions: {
                _StepIntent: CallbackAction<_StepIntent>(
                  onInvoke: (intent) {
                    final next = stepped(intent.minutes);
                    if (next != null) onChanged(next);
                    return null;
                  },
                ),
              },
              // 끌기는 스크린 리더에 늘리기·줄이기로 대신 내보인다
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onPanDown: (details) => pick(details.localPosition),
                onPanUpdate: (details) => pick(details.localPosition),
                child: dial,
              ),
            ),
          );
        }

        return Center(child: dial);
      },
    );
  }

  static String _minutesText(Duration duration) => '${duration.inMinutes}분';
}

/// 다이얼 시간을 [minutes]분 옮긴다
class _StepIntent extends Intent {
  const _StepIntent(this.minutes);

  final int minutes;
}

class _TimerDialPainter extends CustomPainter {
  _TimerDialPainter({
    required double fraction,
    required this.face,
    required this.fillColor,
    required this.faceColor,
    required this.tickColor,
    required this.knobColor,
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
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    if (side <= 0) return;
    final center = size.center(Offset.zero);
    final showLabels = side >= _minLabelSide;
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
      oldDelegate.labelStyle != labelStyle;
}
