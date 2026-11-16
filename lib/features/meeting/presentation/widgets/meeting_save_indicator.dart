import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_autosave.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 내 가능 시간의 저장 상태 한 줄. 저장하지 못했으면 다시 시도 버튼을 둔다
class MeetingSaveIndicator extends StatelessWidget {
  const MeetingSaveIndicator({
    super.key,
    required this.status,
    required this.onRetry,
  });

  final MeetingSaveStatus status;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (icon, text, color) = switch (status) {
      MeetingSaveStatus.idle => (null, null, null),
      MeetingSaveStatus.saving => (Icons.sync, '저장 중', scheme.onSurfaceVariant),
      MeetingSaveStatus.saved => (
        Icons.check_circle_outline,
        '저장됨',
        AppColors.of(context).success,
      ),
      MeetingSaveStatus.failed => (
        Icons.error_outline,
        '저장하지 못했습니다',
        scheme.error,
      ),
    };
    if (icon == null || text == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Icon(icon, size: 16, color: color),
          Text(text, style: theme.textTheme.bodySmall?.copyWith(color: color)),
          if (status == MeetingSaveStatus.failed)
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
