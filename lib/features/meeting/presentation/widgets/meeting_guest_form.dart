import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/analytics/usage_analytics.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/core/turnstile/turnstile_field.dart';
import 'package:momeet/features/meeting/domain/meeting_names.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_guest_steps.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_guest_errors.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_consent.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_password_field.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/providers/api_providers.dart';

/// 찾은 이름. [handle]이 없으면 처음 쓰는 이름이다. [consentVersion]은 지금 약관 버전이다
typedef _Found = ({String name, String? handle, String consentVersion});

/// 게스트로 들어가는 폼: 이름 → 비밀번호 → (처음 쓰는 이름이면) 약관 동의 → 들어가기. 처음 쓰는 이름의
/// 비밀번호는 [guestPasswordMinChars]글자 이상이어야 하고, 이미 있는 이름의 로그인에는 길이를 보지 않는다.
///
/// 이름 칸을 벗어나면(글자마다가 아니라) 그 이름을 찾는다. 이미 참여한 이름이면 로그인이 되고 약관은 묻지
/// 않는다. 처음 쓰는 이름이면 비밀번호를 바꾸거나 찾을 수 없다고 알리고 약관 동의를 받는다. 들어가면 인증
/// 상태가 게스트가 되어 모임 화면이 게스트 본문으로 바뀐다.
class MeetingGuestForm extends ConsumerStatefulWidget {
  const MeetingGuestForm({super.key, required this.meetingId});

  final String meetingId;

  @override
  ConsumerState<MeetingGuestForm> createState() => _MeetingGuestFormState();
}

class _MeetingGuestFormState extends ConsumerState<MeetingGuestForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _nameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  late final _turnstile = ref.read(turnstileFactoryProvider)!();
  late final _steps = MeetingGuestSteps(
    meetingId: widget.meetingId,
    turnstile: _turnstile,
    guests: ref.read(guestsApiProvider),
    auth: ref.read(authProvider.notifier),
  );

  _Found? _found;

  /// 찾는 중인 이름과 그 결과
  String? _lookingUp;
  Future<_Found?>? _lookup;

  var _busy = false;

  /// 이 폼에서 게스트를 새로 만들었다(들어가면 새 게스트로 센다)
  var _created = false;
  GuestConsentChecks _consent = (age: false, terms: false, privacy: false);
  String? _message;
  String? _passwordError;

  bool get _agreed => _consent.age && _consent.terms && _consent.privacy;

  String get _typedName => guestName(_name.text);

  /// 지금 이름을 찾은 결과. 이름을 고쳤으면 null이다
  _Found? get _current => _found?.name == _typedName ? _found : null;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() {
      if (mounted && !_nameFocus.hasFocus) unawaited(_find());
    });
    // 찾은 뒤 이름을 고치면 다시 찾을 때까지 처음인지 모른다
    _name.addListener(() => setState(() {}));
    _password.addListener(() {
      if (_passwordError != null) setState(() => _passwordError = null);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    _nameFocus.dispose();
    _passwordFocus.dispose();
    _turnstile.dispose();
    super.dispose();
  }

  /// 지금 이름을 찾는다. 같은 닉네임을 찾는 중이면 그 결과를 기다리고, 이미 찾았으면 다시 찾지 않는다.
  /// 찾는 사이 이름을 고쳤으면 그 결과는 버린다. 찾지 못하면 알리고 null이다
  Future<_Found?> _find() {
    final name = _typedName;
    if (meetingNameError(name) != null) return Future.value();
    if (_current case final found?) return Future.value(found);
    if (_lookingUp == name) return _lookup!;
    setState(() {
      _lookingUp = name;
      _message = null;
    });
    return _lookup = _steps
        .lookup(name)
        .then<_Found?>(
          (read) {
            final found = (
              name: name,
              handle: read.handle,
              consentVersion: read.consentVersion,
            );
            if (mounted && _typedName == name) setState(() => _found = found);
            return found;
          },
          onError: (Object error) {
            if (mounted && _typedName == name) {
              setState(() => _message = guestRefusalText(error));
            }
            return null;
          },
        )
        .whenComplete(() {
          if (_lookingUp != name) return;
          _lookingUp = null;
          _lookup = null;
          if (mounted) setState(() {});
        });
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
      _passwordError = null;
    });
    try {
      var found = await _find();
      if (!mounted || found == null || found.name != _typedName) return;
      if (found.handle == null) {
        // 처음 쓰는 이름이면 약관에 동의한 뒤에 만든다. 비밀번호가 짧으면 아무것도 보내지 않는다
        if (!_agreed) return;
        final created = await _steps.create(
          name: found.name,
          password: _password.text,
          consentVersion: found.consentVersion,
        );
        _created = true;
        // 다시 시도하면 만들지 않고 로그인만 한다
        found = (
          name: found.name,
          handle: created.handle,
          consentVersion: found.consentVersion,
        );
        if (mounted) setState(() => _found = found);
      }
      await _steps.signIn(handle: found.handle!, password: _password.text);
      _reportEntered(ref, created: _created);
    } catch (error) {
      if (mounted) await _refused(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refused(Object error) async {
    final refusal = GuestRefusal.of(error);
    if (refusal == GuestRefusal.wrongPassword ||
        refusal == GuestRefusal.passwordTooShort) {
      return setState(() => _passwordError = guestRefusalText(error));
    }
    if (refusal != GuestRefusal.nameTaken &&
        refusal != GuestRefusal.consentChanged) {
      return setState(() => _message = guestRefusalText(error));
    }
    // 그 사이 같은 이름이 생겼거나 약관이 바뀌었다: 다시 찾아 로그인이나 새 약관 동의로 간다
    setState(() {
      _found = null;
      if (refusal == GuestRefusal.consentChanged) {
        _consent = (age: false, terms: false, privacy: false);
      }
    });
    await _find();
    if (mounted && refusal == GuestRefusal.consentChanged) {
      setState(() => _message = guestRefusalText(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final found = _current;
    final isNew = found != null && found.handle == null;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NameField(
            controller: _name,
            focusNode: _nameFocus,
            known: found?.handle != null,
            checking: _lookingUp != null && _lookingUp == _typedName,
            onSubmitted: _passwordFocus.requestFocus,
          ),
          const SizedBox(height: 12),
          MeetingGuestPasswordField(
            controller: _password,
            focusNode: _passwordFocus,
            helper: isNew ? _newGuestPasswordHelper : null,
            errorText: _passwordError,
            onSubmitted: _submit,
          ),
          if (isNew) ...[
            const SizedBox(height: 8),
            MeetingGuestConsent(
              value: _consent,
              onChanged: (value) => setState(() => _consent = value),
            ),
          ],
          const SizedBox(height: 12),
          TurnstileField(controller: _turnstile),
          if (_message case final message?) _Message(message),
          const SizedBox(height: 12),
          _SubmitButton(
            label: isNew ? '참여하기' : '들어가기',
            busy: _busy,
            onPressed: isNew && !_agreed ? null : _submit,
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

/// 게스트로 들어간 것을 사용성 분석에 알린다. [created]면 이 폼에서 새로 만든 게스트다
void _reportEntered(WidgetRef ref, {required bool created}) => ref
    .read(usageAnalyticsProvider)
    .event(
      created
          ? UsageEvent.meetingGuestEnteredNew
          : UsageEvent.meetingGuestEnteredReturning,
    );

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
