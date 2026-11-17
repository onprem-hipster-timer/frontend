import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/auth/guest_user.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/core/turnstile/turnstile_field.dart';
import 'package:momeet/features/meeting/domain/meeting_names.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_guest_steps.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_guest_errors.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_guest_leave.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_password_field.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 게스트의 '편집' 시트를 연다: 이름 바꾸기와 게스트 계정 지우기. 지우기를 고르면 [leaveMeetingAsGuest]로 간다
Future<void> showMeetingGuestSheet(
  BuildContext context,
  WidgetRef ref, {
  required String meetingId,
  required GuestUser guest,
}) async {
  final token = await showAppSheet<String>(
    context,
    builder: (context) => MeetingGuestSheet(meetingId: meetingId, guest: guest),
  );
  if (token != null && context.mounted) {
    await leaveMeetingAsGuest(context, ref, token);
  }
}

/// 게스트의 이름 바꾸기와 게스트 계정 지우기. 둘 다 확인 상자의 새 토큰을 쓴다.
///
/// 이름은 Kratos 설정 플로우로 바꾼다. 들어온 지 오래된 세션이라 거절되면(session_refresh_required) 이
/// 시트에서 비밀번호를 받아 게스트 로그인을 다시 하고(새 세션이 지금 세션을 대신한다) 입력한 이름으로 다시
/// 바꾼다. 지우기는 토큰을 받아 시트를 닫으며 돌려준다(보내기는 되돌리기를 기다린 뒤다).
class MeetingGuestSheet extends ConsumerStatefulWidget {
  const MeetingGuestSheet({
    super.key,
    required this.meetingId,
    required this.guest,
  });

  final String meetingId;
  final GuestUser guest;

  @override
  ConsumerState<MeetingGuestSheet> createState() => _MeetingGuestSheetState();
}

class _MeetingGuestSheetState extends ConsumerState<MeetingGuestSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.guest.name);
  late final TurnstileController _turnstile = ref.read(
    turnstileFactoryProvider,
  )!();
  late final _steps = MeetingGuestSteps(
    meetingId: widget.meetingId,
    turnstile: _turnstile,
    guests: ref.read(guestsApiProvider),
    auth: ref.read(authProvider.notifier),
  );

  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  var _busy = false;

  /// 바꾸기 전에 비밀번호로 다시 로그인해야 하면 그 까닭. 비밀번호 칸 아래에 보인다
  String? _reauth;
  String? _nameError;
  String? _passwordError;
  String? _message;

  @override
  void initState() {
    super.initState();
    _password.addListener(() {
      if (_passwordError != null) setState(() => _passwordError = null);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    _turnstile.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final name = guestName(_name.text);
    if (name == widget.guest.name) return navigator.pop();
    final messenger = ScaffoldMessenger.of(context);
    final board = ref.read(meetingBoardProvider(widget.meetingId).notifier);
    setState(() {
      _busy = true;
      _nameError = null;
      _passwordError = null;
      _message = null;
    });
    try {
      if (_reauth != null) {
        await _steps.signIn(
          handle: widget.guest.handle,
          password: _password.text,
        );
        if (mounted) setState(() => _reauth = null);
      }
      await _steps.rename(widget.guest, name);
      await board.reload();
      navigator.pop();
      messenger.showAppSnackBar('닉네임을 바꿨습니다', kind: AppNoticeKind.success);
    } catch (error) {
      if (mounted) _refused(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _refused(Object error) {
    final text = guestRefusalText(error);
    setState(() {
      switch (GuestRefusal.of(error)) {
        case GuestRefusal.nameTaken:
          _nameError = text;
        case GuestRefusal.wrongPassword:
          _passwordError = text;
        case GuestRefusal.reauthRequired:
          _reauth = text;
          _password.clear();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _passwordFocus.requestFocus();
          });
        case _:
          _message = text;
      }
    });
  }

  /// 지우기에 쓸 토큰을 받아 시트를 닫으며 돌려준다
  Future<void> _delete() async {
    if (_busy) return;
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      navigator.pop(await _turnstile.nextToken());
    } catch (error) {
      if (mounted) setState(() => _message = guestRefusalText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = _message;
    return AppFormSheet(
      title: '내 닉네임',
      formKey: _formKey,
      actions: AppFormActionBar(
        submitLabel: '저장',
        onSubmit: _save,
        busy: _busy,
      ),
      children: [
        TextFormField(
          controller: _name,
          autofocus: true,
          decoration: InputDecoration(
            // 큰 글자에서는 칸 이름을 자르지 않고 두 줄까지 보인다
            label: Text('이 ${Terms.meeting}에서 보일 닉네임', maxLines: 2),
            prefixIcon: const Icon(Icons.badge_outlined),
            errorText: _nameError,
            errorMaxLines: 3,
          ),
          validator: (value) => meetingNameError(guestName(value ?? '')),
          textInputAction: _reauth == null
              ? TextInputAction.done
              : TextInputAction.next,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
          onFieldSubmitted: (_) =>
              _reauth == null ? _save() : _passwordFocus.requestFocus(),
        ),
        if (_reauth case final reason?)
          MeetingGuestPasswordField(
            controller: _password,
            focusNode: _passwordFocus,
            helper: reason,
            errorText: _passwordError,
            onSubmitted: _save,
          ),
        TurnstileField(controller: _turnstile),
        if (message != null)
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        _DeleteGuest(onPressed: _busy ? null : _delete),
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
