import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_guest_import_phase.dart';

/// 회원의 모임 화면 위: 따로 둔 게스트 세션의 시간을 옮기는 중이거나 옮기지 못했으면 조용한 한 줄(못 했으면
/// '다시 시도')이다. 그 밖의 [phase]에는 아무것도 없다
class MeetingGuestImportNoticeView extends StatelessWidget {
  const MeetingGuestImportNoticeView({
    super.key,
    required this.phase,
    required this.onRetry,
  });

  /// 옮기는 단계. 모르면 null
  final MeetingGuestImportPhase? phase;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final phase = this.phase;
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final style = theme.textTheme.bodyMedium?.copyWith(color: color);
    final (Widget lead, String text) = switch (phase) {
      MeetingGuestImportPhase.importing => (
        const SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        '게스트로 넣은 시간을 옮기는 중이에요',
      ),
      MeetingGuestImportPhase.failed => (
        Icon(Icons.sync_problem, size: 18, color: color),
        '게스트로 넣은 시간을 아직 옮기지 못했어요',
      ),
      _ => (const SizedBox.shrink(), ''),
    };
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        liveRegion: true,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            lead,
            Text(text, style: style),
            if (phase == MeetingGuestImportPhase.failed)
              TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
