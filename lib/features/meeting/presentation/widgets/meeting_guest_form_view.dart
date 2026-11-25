import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/guest_name.dart';
import 'package:momeet/features/meeting/domain/meeting_names.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_consent.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_password_field.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 게스트로 들어가는 폼: 닉네임, 비밀번호, (처음 쓰는 닉네임이면([isNew])) 약관 동의, 사람 확인 상자([turnstile]),
/// 거절 안내([message]), 들어가기(처음 쓰는 닉네임이면 '참여하기'이고 약관에 모두 동의해야 누를 수 있다).
///
/// [known]이면 이미 참여한 닉네임이라고 안내하고, [checking]이면 닉네임 칸 끝에 작게 돈다. [busy]면 들어가기를
/// 누를 수 없고 돈다.
class MeetingGuestFormView extends StatelessWidget {
  const MeetingGuestFormView({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.nameFocusNode,
    required this.passwordController,
    required this.passwordFocusNode,
    required this.known,
    required this.checking,
    required this.isNew,
    required this.consent,
    required this.onConsentChanged,
    required this.turnstile,
    required this.message,
    required this.passwordError,
    required this.busy,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final FocusNode nameFocusNode;
  final TextEditingController passwordController;
  final FocusNode passwordFocusNode;

  /// 이미 참여한 닉네임
  final bool known;

  /// 닉네임을 찾는 중
  final bool checking;

  /// 처음 쓰는 닉네임
  final bool isNew;
  final GuestConsentChecks consent;
  final ValueChanged<GuestConsentChecks> onConsentChanged;

  /// 사람 확인 상자
  final Widget turnstile;

  /// 폼 아래의 거절 안내. 없으면 null
  final String? message;

  /// 비밀번호 칸 아래의 거절 안내. 없으면 null
  final String? passwordError;

  /// 보내는 중
  final bool busy;
  final VoidCallback onSubmit;

  bool get _agreed => consent.age && consent.terms && consent.privacy;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NameField(
            controller: nameController,
            focusNode: nameFocusNode,
            known: known,
            checking: checking,
            onSubmitted: passwordFocusNode.requestFocus,
          ),
          const SizedBox(height: 12),
          MeetingGuestPasswordField(
            controller: passwordController,
            focusNode: passwordFocusNode,
            helper: isNew ? _newGuestPasswordHelper : null,
            errorText: passwordError,
            onSubmitted: onSubmit,
          ),
          if (isNew) ...[
            const SizedBox(height: 8),
            MeetingGuestConsent(value: consent, onChanged: onConsentChanged),
          ],
          const SizedBox(height: 12),
          turnstile,
          if (message case final message?) _Message(message),
          const SizedBox(height: 12),
          _SubmitButton(
            label: isNew ? '참여하기' : '들어가기',
            busy: busy,
            onPressed: isNew && !_agreed ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

/// 처음 쓰는 이름의 비밀번호 칸 아래 안내
const _newGuestPasswordHelper =
    '게스트는 비밀번호를 바꾸거나 찾을 수 없습니다. 잊으면 이 닉네임으로 다시 들어올 수 없습니다. '
    '분실이 우려되면 로그인을 이용해 주세요!';

/// 이름 칸. 이미 참여한 이름이면 로그인하라고 안내하고, 찾는 중이면 끝에 작게 돈다
class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.focusNode,
    required this.known,
    required this.checking,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool known;
  final bool checking;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: '닉네임',
        prefixIcon: const Icon(Icons.badge_outlined),
        helperText: known
            ? '이미 참여한 닉네임입니다. 본인이면 비밀번호를 입력하세요'
            : '이 ${Terms.meeting}에서 보일 닉네임',
        helperMaxLines: 6,
        suffixIcon: checking ? const _Checking() : null,
      ),
      validator: (value) => meetingNameError(guestName(value ?? '')),
      onFieldSubmitted: (_) => onSubmitted(),
    );
  }
}

/// 들어가기 단추. 보내는 중이면 누를 수 없고 돌아간다
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      child: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

/// 닉네임을 찾는 중인 작은 표시
class _Checking extends StatelessWidget {
  const _Checking();

  @override
  Widget build(BuildContext context) => Semantics(
    label: '닉네임을 찾는 중',
    child: const Padding(
      padding: EdgeInsets.all(14),
      child: SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

/// 폼 아래의 거절 안내 한 줄
class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        liveRegion: true,
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}
