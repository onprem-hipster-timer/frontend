import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

/// '저장하기' 자리의 상태
enum MeetingFinishPhase {
  /// 바꾼 것을 저절로 저장하기를 기다리거나 저장하는 중이다
  autosaving,

  /// 바꾼 것을 저절로 저장했다
  autosaved,

  /// 누른 뒤 남은 저장을 기다리는 중
  saving,

  /// 모두 저장해 입력을 마쳤다(다음에 바꿀 때까지 조용하다)
  done,

  /// 저절로든 눌러서든 저장하지 못했다(다시 누를 수 있다)
  failed,
}

/// 내 시간을 바꾼 뒤의 저장 상태 한 줄과 '저장하기', 누른 뒤의 결과. 저장은 누르지 않아도 저절로 되므로 상태
/// 줄이 그것을 알리고, 이미 저장했으면 단추는 덜 눈에 띄는 '그래도 저장하기'다. [pinned]면 좁은 화면 아래에
/// 붙는 띠로, 아니면 격자 아래 오른쪽에 둔다
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
    final content = phase == MeetingFinishPhase.done
        ? const _Done()
        : _StatusAndButton(phase: phase, onPressed: onPressed, pinned: pinned);
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

/// 저장 상태 한 줄과 단추. 좁은 화면 아래 띠에서는 상태를 단추 위에, 넓으면 단추 앞에 두고 모자라면 단추를 다음
/// 줄로 내린다. 누른 뒤 기다리는 동안은 상태 없이 막힌 단추만 둔다
class _StatusAndButton extends StatelessWidget {
  const _StatusAndButton({
    required this.phase,
    required this.onPressed,
    required this.pinned,
  });

  final MeetingFinishPhase phase;
  final VoidCallback onPressed;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = switch (phase) {
      MeetingFinishPhase.autosaving => _Status(
        icon: Icons.sync,
        text: '자동 저장 중',
        color: scheme.onSurfaceVariant,
      ),
      MeetingFinishPhase.autosaved => _Status(
        icon: Icons.check_circle_outline,
        text: '자동 저장됐어요',
        color: AppColors.of(context).success,
      ),
      MeetingFinishPhase.failed => _Status(
        icon: Icons.error_outline,
        text: '저장하지 못했어요',
        color: scheme.error,
      ),
      MeetingFinishPhase.saving || MeetingFinishPhase.done => null,
    };
    final button = _Button(
      label: switch (phase) {
        MeetingFinishPhase.autosaved => '그래도 저장하기',
        MeetingFinishPhase.saving => '저장하는 중',
        MeetingFinishPhase.failed => '다시 저장하기',
        MeetingFinishPhase.autosaving || MeetingFinishPhase.done => '저장하기',
      },
      onPressed: phase == MeetingFinishPhase.saving ? null : onPressed,
      pinned: pinned,
      // 이미 저장했으니 누르지 않아도 된다
      tonal: phase == MeetingFinishPhase.autosaved,
    );
    if (pinned) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status != null) ...[status, const SizedBox(height: 8)],
          button,
        ],
      );
    }
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [?status, button],
    );
  }
}

/// 저장 상태 한 줄. 바뀌면 스크린 리더가 읽는다
class _Status extends StatelessWidget {
  const _Status({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// '저장하기'·'그래도 저장하기'·'다시 저장하기' 단추. 기다리는 동안은 막고 진행 표시를 둔다. [tonal]이면 덜
/// 눈에 띄는 색이다
class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.onPressed,
    required this.pinned,
    this.tonal = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool pinned;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: pinned ? const Size.fromHeight(52) : const Size(160, 48),
    );
    final child = Row(
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
    );
    return tonal
        ? FilledButton.tonal(onPressed: onPressed, style: style, child: child)
        : FilledButton(onPressed: onPressed, style: style, child: child);
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
