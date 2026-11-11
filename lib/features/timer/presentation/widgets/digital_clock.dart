import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/utils/time_formatters.dart';

/// 디지털 시계 위젯
///
/// HH:MM:SS 형식으로 남은 시간을 표시합니다. 집중 시간이 끝나면([timeUp]) 에러 색,
/// 활성 타이머 없이 고른 시간이면([idle]) 흐린 색으로 표시합니다.
class DigitalClock extends StatelessWidget {
  final Duration duration;
  final bool timeUp;
  final bool idle;
  final bool compact;

  const DigitalClock({
    super.key,
    required this.duration,
    this.timeUp = false,
    this.idle = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeText = formatDuration(duration);

    return Text(
      timeText,
      style: theme.textTheme.displayLarge?.copyWith(
        fontFamily: 'monospace', // 등폭 폰트 사용
        fontSize: compact ? 24 : 28,
        fontWeight: FontWeight.w400,
        color: timeUp
            ? theme.colorScheme.error
            : !idle
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        letterSpacing: 2,
      ),
    );
  }
}
