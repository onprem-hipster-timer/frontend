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
/// 이름은 Kratos 설정 플로우로 바꾼다. 지우기는 토큰을 받아 시트를 닫으며 돌려준다(보내기는 되돌리기를
/// 기다린 뒤다).
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

  var _busy = false;
  String? _nameError;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
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
      _message = null;
    });
    try {
      await _steps.rename(widget.guest, name);
      await board.reload();
      navigator.pop();
      messenger.showAppSnackBar('이름을 바꿨습니다', kind: AppNoticeKind.success);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (GuestRefusal.of(error) == GuestRefusal.nameTaken) {
          _nameError = guestRefusalText(error);
        } else {
          _message = guestRefusalText(error);
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
      title: '내 이름',
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
            labelText: '이 ${Terms.meeting}에서 보일 이름',
            prefixIcon: const Icon(Icons.badge_outlined),
            errorText: _nameError,
            errorMaxLines: 3,
          ),
          validator: (value) => meetingNameError(guestName(value ?? '')),
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
          onFieldSubmitted: (_) => _save(),
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
          '내 시간과 이름이 이 ${Terms.meeting}에서 지워집니다. 되돌리기 알림이 닫히면 되돌릴 수 없습니다.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
