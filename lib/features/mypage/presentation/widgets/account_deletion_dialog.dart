import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/exceptions/exceptions.dart';
import 'package:momeet/core/providers/my_profile_provider.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 회원 탈퇴 확인 다이얼로그를 연다.
Future<void> showAccountDeletionDialog(BuildContext context) {
  return showAppDialog<void>(
    context,
    builder: (_) => const AccountDeletionDialog(),
  );
}

/// 탈퇴하면 무엇이 언제 지워지는지 알리고, 확인했다고 체크해야 탈퇴를 신청할 수 있다.
///
/// 신청하면 로그아웃되어 라우터가 로그인 화면으로 보낸다.
class AccountDeletionDialog extends ConsumerStatefulWidget {
  const AccountDeletionDialog({super.key});

  @override
  ConsumerState<AccountDeletionDialog> createState() =>
      _AccountDeletionDialogState();
}

class _AccountDeletionDialogState extends ConsumerState<AccountDeletionDialog> {
  bool _acknowledged = false;
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    // 로그아웃하면 라우터가 화면을 바꿔 이 다이얼로그가 사라지므로 미리 잡아 둔다
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(myProfileProvider.notifier).requestDeletion();
      messenger.showAppSnackBar('탈퇴를 신청했습니다. 3일 안에 다시 로그인하면 취소할 수 있습니다.');
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      // 신청은 됐다. 라우터가 탈퇴 대기 화면으로 보내고, 거기서 다시 로그아웃할 수 있다
      messenger.showAppSnackBar(
        '탈퇴를 신청했지만 로그아웃하지 못했습니다: ${e.message}',
        kind: AppNoticeKind.error,
      );
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showAppSnackBar(context, '탈퇴 신청에 실패했습니다: $e', kind: AppNoticeKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AlertDialog(
      title: const Text('회원 탈퇴'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Notice('신청하면 바로 로그아웃되고, 다른 사람에게 내 정보가 보이지 않습니다.'),
            const _Notice('3일 안에 다시 로그인하면 탈퇴를 취소할 수 있습니다.'),
            const _Notice(
              '3일이 지나면 계정과 모든 데이터(일정·${Terms.todo}·${Terms.timer}·태그·친구·약속)가 '
              '지워지며 되돌릴 수 없습니다.',
            ),
            const _Notice('지워진 데이터는 백업에 최대 70일 동안 남을 수 있습니다.'),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _acknowledged,
              onChanged: _submitting
                  ? null
                  : (checked) =>
                        setState(() => _acknowledged = checked ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text('위 내용을 확인했습니다'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _acknowledged && !_submitting ? _submit : null,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('탈퇴 신청'),
        ),
      ],
    );
  }
}

/// 탈퇴 안내 한 줄
class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
