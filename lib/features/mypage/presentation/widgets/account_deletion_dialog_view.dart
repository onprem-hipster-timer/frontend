import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 회원 탈퇴 확인 창. 탈퇴하면 무엇이 언제 지워지는지 알리고, 확인했다고 체크해야 '탈퇴 신청'을 누를 수 있다.
///
/// [submitting]인 동안은 체크·취소·신청을 막고 신청 버튼에 진행 표시를 둔다.
class AccountDeletionDialogView extends StatefulWidget {
  const AccountDeletionDialogView({
    super.key,
    required this.submitting,
    required this.onSubmit,
    required this.onCancel,
  });

  final bool submitting;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  State<AccountDeletionDialogView> createState() =>
      _AccountDeletionDialogViewState();
}

class _AccountDeletionDialogViewState extends State<AccountDeletionDialogView> {
  bool _acknowledged = false;

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
              onChanged: widget.submitting
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
          onPressed: widget.submitting ? null : widget.onCancel,
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _acknowledged && !widget.submitting
              ? widget.onSubmit
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: widget.submitting
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
