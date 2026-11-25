import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/exceptions/exceptions.dart';
import 'package:momeet/core/providers/my_profile_provider.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/features/mypage/presentation/widgets/account_deletion_dialog_view.dart';

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
    return AccountDeletionDialogView(
      submitting: _submitting,
      onSubmit: _submit,
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}
