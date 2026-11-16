import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';

/// 로그인 상자 자리에 두는 지금 계정. 회원은 'OO 계정으로 진행 중입니다'이고, 게스트는 게스트 이름과
/// [onSignOut]('로그아웃')이다. 로그인한 사람에게는 게스트로 들어가는 길이 없다.
class MeetingAccountPanel extends StatelessWidget {
  const MeetingAccountPanel({
    super.key,
    required this.text,
    this.guest = false,
    this.onSignOut,
  });

  final String text;

  /// 게스트 세션이면 게스트 아이콘이다
  final bool guest;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSignOut = this.onSignOut;
    return MeetingPanel(
      title: '로그인',
      child: Row(
        children: [
          Icon(
            guest ? Icons.person_outline : Icons.account_circle_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
          if (onSignOut != null)
            TextButton(onPressed: onSignOut, child: const Text('로그아웃')),
        ],
      ),
    );
  }
}
