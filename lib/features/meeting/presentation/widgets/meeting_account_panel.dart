import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_quiet_panels.dart';

/// 로그인 상자 자리에 두는 지금 계정. 회원은 'OO 계정으로 진행 중입니다'이고, 게스트는 게스트 이름과
/// [onSignOut]('로그아웃'), 그 아래 [onUpgrade]('안전한 정규 유저로 바꾸기')다. 로그인한 사람에게는 게스트로 들어가는
/// 길이 없다.
///
/// [MeetingQuietPanels] 아래(좁은 화면)에서는 상자 없이 작은 한 줄이다.
class MeetingAccountPanel extends StatelessWidget {
  const MeetingAccountPanel({
    super.key,
    required this.text,
    this.guest = false,
    this.onSignOut,
    this.onUpgrade,
  });

  final String text;

  /// 게스트 세션이면 게스트 아이콘이다
  final bool guest;
  final VoidCallback? onSignOut;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSignOut = this.onSignOut;
    final onUpgrade = this.onUpgrade;
    final icon = guest ? Icons.person_outline : Icons.account_circle_outlined;
    if (MeetingQuietPanels.of(context)) {
      final caption = theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: caption?.color),
              const SizedBox(width: 6),
              Expanded(child: Text(text, style: caption)),
              if (onSignOut != null)
                TextButton(
                  onPressed: onSignOut,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: theme.textTheme.labelMedium,
                  ),
                  child: const Text('로그아웃'),
                ),
            ],
          ),
          if (onUpgrade != null)
            _UpgradeButton(onPressed: onUpgrade, compact: true),
        ],
      );
    }
    return MeetingPanel(
      title: '로그인',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
              if (onSignOut != null)
                TextButton(onPressed: onSignOut, child: const Text('로그아웃')),
            ],
          ),
          if (onUpgrade != null)
            _UpgradeButton(onPressed: onUpgrade, compact: false),
        ],
      ),
    );
  }
}

/// '안전한 정규 유저로 바꾸기'
class _UpgradeButton extends StatelessWidget {
  const _UpgradeButton({required this.onPressed, required this.compact});

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      visualDensity: compact ? VisualDensity.compact : null,
    ),
    icon: const Icon(Icons.verified_user_outlined, size: 18),
    label: const Text('안전한 정규 유저로 바꾸기'),
  );
}
