import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 타이머 상태 표시에 쓰는 아이콘, 배경·글자색, 이름
typedef TimerStatusStyle = ({IconData icon, Color bg, Color fg, String label});

/// 타이머 상태별 아이콘, 색, 이름
TimerStatusStyle timerStatusStyle(BuildContext context, TimerStatus status) {
  final cs = Theme.of(context).colorScheme;
  switch (status) {
    case TimerStatus.running:
      return (
        icon: Icons.play_arrow,
        bg: AppColors.of(context).successContainer,
        fg: AppColors.of(context).onSuccessContainer,
        label: '진행 중',
      );
    case TimerStatus.paused:
      return (
        icon: Icons.pause,
        bg: AppColors.of(context).warningContainer,
        fg: AppColors.of(context).onWarningContainer,
        label: '일시정지',
      );
    case TimerStatus.cancelled:
      return (
        icon: Icons.cancel_outlined,
        bg: cs.surfaceContainerHighest,
        fg: cs.onSurfaceVariant,
        label: '취소',
      );
    default:
      return (
        icon: Icons.check_circle_outline,
        bg: cs.primaryContainer,
        fg: cs.onPrimaryContainer,
        label: '완료',
      );
  }
}

/// 타이머 상태 칩
class TimerStatusChip extends StatelessWidget {
  const TimerStatusChip(this.style, {super.key});

  final TimerStatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: style.bg, borderRadius: AppRadius.smAll),
      child: Text(
        style.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: style.fg,
        ),
      ),
    );
  }
}
