import 'package:material_ui/material_ui.dart';

/// 로그인할 까닭과 '로그인'·'Guest' 고르기. 게스트를 받으면 게스트는 이름과 비밀번호만 있으면 되지만 로그인만큼 안전하지는 않다고 적는다
class MeetingLoginChoice extends StatelessWidget {
  const MeetingLoginChoice({super.key, required this.onLogin, this.onGuest});

  final VoidCallback onLogin;

  /// 없으면 'Guest'가 없다
  final VoidCallback? onGuest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onGuest = this.onGuest;
    final note = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final buttonStyle = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('로그인하면 내 시간을 칠할 수 있어요', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: FilledButton(
                onPressed: onLogin,
                style: buttonStyle,
                child: const Text('로그인'),
              ),
            ),
            if (onGuest != null)
              Expanded(
                child: FilledButton.tonal(
                  onPressed: onGuest,
                  style: buttonStyle,
                  child: const Text('Guest'),
                ),
              ),
          ],
        ),
        if (onGuest != null) ...[
          const SizedBox(height: 8),
          Text(
            '게스트는 가입 없이 닉네임과 비밀번호만 있으면 돼요, 하지만 로그인만큼 강력한 보안을 보장하지 못해요!',
            style: note,
          ),
        ],
      ],
    );
  }
}
