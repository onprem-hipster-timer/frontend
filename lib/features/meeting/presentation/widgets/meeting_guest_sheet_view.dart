import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/guest_name.dart';
import 'package:momeet/features/meeting/domain/meeting_names.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_password_field.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 게스트의 '내 닉네임' 시트: 닉네임 칸, (비밀번호로 다시 로그인해야 하면([reauth])) 비밀번호 칸, 사람 확인 상자
/// ([turnstile]), 거절 안내([message]), 게스트 계정 지우기. [busy]면 저장과 지우기를 누를 수 없다
class MeetingGuestSheetView extends StatelessWidget {
  const MeetingGuestSheetView({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.passwordController,
    required this.passwordFocusNode,
    required this.reauth,
    required this.nameError,
    required this.passwordError,
    required this.message,
    required this.busy,
    required this.turnstile,
    required this.onNameChanged,
    required this.onSave,
    required this.onDelete,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController passwordController;
  final FocusNode passwordFocusNode;

  /// 바꾸기 전에 비밀번호로 다시 로그인해야 하면 그 까닭. 비밀번호 칸 아래에 보인다
  final String? reauth;

  /// 닉네임 칸 아래의 거절 안내. 없으면 null
  final String? nameError;

  /// 비밀번호 칸 아래의 거절 안내. 없으면 null
  final String? passwordError;

  /// 지우기 위의 거절 안내. 없으면 null
  final String? message;

  /// 보내는 중
  final bool busy;

  /// 사람 확인 상자
  final Widget turnstile;

  /// 닉네임 칸을 고쳤다
  final VoidCallback onNameChanged;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = this.message;
    final reauth = this.reauth;
    return AppFormSheet(
      title: '내 닉네임',
      formKey: formKey,
      actions: AppFormActionBar(
        submitLabel: '저장',
        onSubmit: onSave,
        busy: busy,
      ),
      children: [
        TextFormField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            // 큰 글자에서는 칸 이름을 자르지 않고 두 줄까지 보인다
            label: Text('이 ${Terms.meeting}에서 보일 닉네임', maxLines: 2),
            prefixIcon: const Icon(Icons.badge_outlined),
            errorText: nameError,
            errorMaxLines: 3,
          ),
          validator: (value) => meetingNameError(guestName(value ?? '')),
          textInputAction: reauth == null
              ? TextInputAction.done
              : TextInputAction.next,
          onChanged: (_) => onNameChanged(),
          onFieldSubmitted: (_) =>
              reauth == null ? onSave() : passwordFocusNode.requestFocus(),
        ),
        if (reauth case final reason?)
          MeetingGuestPasswordField(
            controller: passwordController,
            focusNode: passwordFocusNode,
            helper: reason,
            errorText: passwordError,
            onSubmitted: onSave,
          ),
        turnstile,
        if (message != null)
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        _DeleteGuest(onPressed: busy ? null : onDelete),
      ],
    );
  }
}

/// 게스트 계정 지우기. 지운 뒤 되돌리기 알림이 닫히면 되돌릴 수 없다고 미리 알린다
class _DeleteGuest extends StatelessWidget {
  const _DeleteGuest({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        TextButton.icon(
          onPressed: onPressed,
          style: TextButton.styleFrom(foregroundColor: error),
          icon: const Icon(Icons.delete_outline),
          label: const Text('게스트 계정 지우기'),
        ),
        Text(
          '내 시간과 닉네임이 이 ${Terms.meeting}에서 지워집니다. 되돌리기 알림이 닫히면 되돌릴 수 없습니다.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
