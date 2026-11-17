import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

/// '저장하기'의 상태
enum MeetingFinishPhase {
  /// 바꾼 것이 있다(누를 수 있다)
  ready,

  /// 남은 저장을 기다리는 중
  saving,

  /// 모두 저장해 입력을 마쳤다(다음에 바꿀 때까지 조용하다)
  done,

  /// 저장하지 못했다(다시 누를 수 있다)
  failed,
}

/// 내 시간을 다 칠한 뒤 누르는 '저장하기'와 그 결과. [pinned]면 좁은 화면 아래에 붙는 띠로, 아니면 격자 아래
/// 오른쪽에 둔다
class MeetingFinishAction extends StatelessWidget {
  const MeetingFinishAction({
    super.key,
    required this.phase,
    required this.onPressed,
    required this.pinned,
  });

  final MeetingFinishPhase phase;
  final VoidCallback onPressed;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final content = switch (phase) {
      MeetingFinishPhase.ready => _Button(
        label: '저장하기',
        onPressed: onPressed,
        pinned: pinned,
      ),
      MeetingFinishPhase.saving => _Button(
        label: '저장하는 중',
        onPressed: null,
        pinned: pinned,
      ),
      MeetingFinishPhase.done => const _Done(),
      MeetingFinishPhase.failed => _Failed(onRetry: onPressed, pinned: pinned),
    };
    if (!pinned) {
      return Align(alignment: AlignmentDirectional.centerEnd, child: content);
    }
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: content,
        ),
      ),
    );
  }
}

/// '저장하기'·'다시 저장하기' 단추. 기다리는 동안은 막고 진행 표시를 둔다
class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.onPressed,
    required this.pinned,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: pinned ? const Size.fromHeight(52) : const Size(160, 48),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onPressed == null) ...[
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: Text(label)),
        ],
      ),
    );
  }
}

/// 입력을 마쳤다는 조용한 알림
class _Done extends StatelessWidget {
  const _Done();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: AppColors.of(context).success),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '입력을 마쳤어요',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '언제든 다시 고칠 수 있어요',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 저장하지 못했다는 말과 '다시 저장하기'
class _Failed extends StatelessWidget {
  const _Failed({required this.onRetry, required this.pinned});

  final VoidCallback onRetry;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = Text(
      '저장하지 못했어요',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.error,
      ),
    );
    final retry = _Button(label: '다시 저장하기', onPressed: onRetry, pinned: pinned);
    return Semantics(
      liveRegion: true,
      child: pinned
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [error, const SizedBox(height: 8), retry],
            )
          : Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [error, retry],
            ),
    );
  }
}
