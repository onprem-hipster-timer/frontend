import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:momeet/features/meeting/domain/meeting_shading.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_autosave.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_grid.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_geometry.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_help_icon.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_save_indicator.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_timezone_label.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

/// '내 시간 선택하기': 제목 줄(시간별이면 하루 범위, 도움말, 저장 상태), 시간 기준, 안내 한 줄, 격자.
///
/// [onPaint]가 없으면(로그인 전) 도움말과 저장 상태 대신 로그인하면 칠할 수 있다고 적고, 칸을 누르면
/// [onLocked]를 부른다.
class MeetingAvailabilitySection extends StatelessWidget {
  const MeetingAvailabilitySection({
    super.key,
    required this.meeting,
    required this.shading,
    this.status = MeetingSaveStatus.idle,
    this.onPaint,
    this.onRetry,
    this.onLocked,
  });

  final MeetingRead meeting;
  final MeetingShading shading;
  final MeetingSaveStatus status;
  final MeetingPaint? onPaint;
  final VoidCallback? onRetry;
  final VoidCallback? onLocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final touch = switch (theme.platform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => true,
      _ => false,
    };
    final locked = onPaint == null;
    final onRetry = this.onRetry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Semantics(
              header: true,
              child: Text(
                '내 시간 선택하기',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (shading.grid.mode == MeetingMode.hourly)
              _RangeChip(meetingHoursText(meeting)),
            if (!locked) ...[
              MeetingHelpIcon(
                touch
                    ? '칸을 누르면 칠하거나 지웁니다. 길게 누른 채 끌면 여러 칸을 한 번에 칠하고, '
                          '칠한 칸에서 시작하면 지웁니다. 칠하면 바로 저장됩니다.'
                    : '칸을 누르거나 누른 채 끌어서 칠합니다. 칠한 칸에서 시작하면 지웁니다. '
                          '칠하면 바로 저장됩니다.',
              ),
              if (onRetry != null)
                MeetingSaveIndicator(status: status, onRetry: onRetry),
            ],
          ],
        ),
        const SizedBox(height: 4),
        MeetingTimezoneLabel(meeting.timezone),
        if (locked)
          const _Hint(icon: Icons.lock_outline, text: '로그인하면 내 시간을 칠할 수 있어요')
        else if (status == MeetingSaveStatus.idle)
          _Hint(
            icon: touch ? Icons.touch_app_outlined : Icons.mouse_outlined,
            text: touch ? '길게 누른 채 끌면 여러 칸을 칠합니다' : '누른 채 끌면 여러 칸을 칠합니다',
          ),
        const SizedBox(height: 16),
        MeetingAvailabilityGrid(
          shading: shading,
          onPaint: onPaint,
          onLocked: onLocked,
        ),
      ],
    );
  }
}

/// 시간 기준 아래의 안내 한 줄
class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caption = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: caption?.color),
          const SizedBox(width: 4),
          Flexible(child: Text(text, style: caption)),
        ],
      ),
    );
  }
}

/// 시간별 하루 범위 알약
class _RangeChip extends StatelessWidget {
  const _RangeChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.pillAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Text(text, style: theme.textTheme.labelMedium),
      ),
    );
  }
}
