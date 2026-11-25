import 'package:material_ui/material_ui.dart';

/// 방문자의 모임 화면 위: 이 기기에 이 모임의 게스트 세션을 따로 두었을 때 '게스트로 계속하기'를 두는 한 줄.
/// [busy]면 누를 수 없다
class MeetingKeptGuestNoticeView extends StatelessWidget {
  const MeetingKeptGuestNoticeView({
    super.key,
    required this.busy,
    required this.onContinue,
  });

  /// 게스트로 돌아가는 중
  final bool busy;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Icon(Icons.person_outline, size: 18, color: color),
          Text(
            '이 기기에 게스트로 넣던 시간이 있어요',
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
          TextButton(
            onPressed: busy ? null : onContinue,
            child: const Text('게스트로 계속하기'),
          ),
        ],
      ),
    );
  }
}
