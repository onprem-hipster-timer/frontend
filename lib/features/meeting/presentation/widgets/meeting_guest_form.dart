import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/analytics/usage_analytics.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/core/turnstile/turnstile_field.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/features/meeting/domain/meeting_names.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_guest_steps.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_guest_errors.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_consent.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_form_view.dart';
import 'package:momeet/shared/providers/api_providers.dart';

/// 찾은 이름. [handle]이 없으면 처음 쓰는 이름이다. [consentVersion]은 지금 약관 버전이다
typedef _Found = ({String name, String? handle, String consentVersion});

/// 게스트로 들어가는 폼: 이름 → 비밀번호 → (처음 쓰는 이름이면) 약관 동의 → 들어가기. 처음 쓰는 이름의
/// 비밀번호는 공백뿐이 아니고 [guestPasswordMinChars]글자 이상이어야 하며, 이미 있는 이름의 로그인에는 이를 보지 않는다.
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
    analytics: () => ref.read(analyticsConsentProvider).asBool,
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
    if (refusal.onPassword) {
      final text = guestPasswordRefusalText(_password.text, error);
      return setState(() => _passwordError = text);
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
    return MeetingGuestFormView(
      formKey: _formKey,
      nameController: _name,
      nameFocusNode: _nameFocus,
      passwordController: _password,
      passwordFocusNode: _passwordFocus,
      known: found?.handle != null,
      checking: _lookingUp != null && _lookingUp == _typedName,
      isNew: found != null && found.handle == null,
      consent: _consent,
      onConsentChanged: (value) => setState(() => _consent = value),
      turnstile: TurnstileField(controller: _turnstile),
      message: _message,
      passwordError: _passwordError,
      busy: _busy,
      onSubmit: _submit,
    );
  }
}

/// 게스트로 들어간 것을 사용성 분석에 알린다. [created]면 이 폼에서 새로 만든 게스트다
void _reportEntered(WidgetRef ref, {required bool created}) => ref
    .read(usageAnalyticsProvider)
    .event(
      created
          ? UsageEvent.meetingGuestEnteredNew
          : UsageEvent.meetingGuestEnteredReturning,
    );
