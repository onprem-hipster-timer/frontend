part of 'auth_provider.dart';

/// 게스트로 들어온 모임을 적어 두는 키. 값은 `<게스트 identity id> <모임 id>`다.
///
/// Kratos 세션에는 게스트의 모임이 없어서, 들어올 때 적어 두고 세션을 되살릴 때 같은 게스트면 읽는다.
const guestMeetingKey = 'momeet.guest_meeting';

/// 게스트 세션: 회원과 같은 Kratos 세션·JWT지만 모임 하나에 속하고 이메일이 없다.
///
/// 세션 토큰 저장소는 회원과 한 칸을 같이 쓴다. 게스트가 회원으로 로그인하면 게스트 세션은 끝낸다.
extension GuestAuth on AuthNotifier {
  /// 모임 [meetingId]의 게스트로 로그인한다. 회원과 같은 Kratos 로그인 플로우에 [handle]과 [password]를
  /// 내고, 받은 세션으로 JWT를 받는다. [turnstileToken]은 이 제출에만 쓴다.
  ///
  /// 실패하면 Kratos·`/auth` 프록시의 거절([KratosException])을 그대로 던진다. 화면이 게스트의 말로 바꾼다.
  Future<void> signInAsGuest({
    required String meetingId,
    required String handle,
    required String password,
    required String turnstileToken,
  }) async {
    final flow = await _kratos.createFlow(KratosFlowType.login);
    final result = await _kratos.submit(KratosFlowType.login, flow.id, {
      'method': 'password',
      'identifier': handle,
      'password': password,
    }, turnstileToken: turnstileToken);
    await _authenticateWith(result.sessionToken!, guestMeetingId: meetingId);
  }

  /// 게스트 이름을 [name]으로 바꾼다(Kratos 설정 플로우의 profile). [handle]은 지금 게스트의 것 그대로다.
  ///
  /// backend는 정규형인 이름만 받는다. 바꾸면 JWT를 다시 받아 새 이름이 인증 상태에 든다.
  /// 실패하면 [signInAsGuest]처럼 거절을 그대로 던진다.
  Future<void> renameGuest({
    required String handle,
    required String name,
    required String turnstileToken,
  }) async {
    final sessionToken = _sessionToken;
    if (sessionToken == null) throw StateError('게스트 세션이 없습니다');
    final flow = await _kratos.createFlow(
      KratosFlowType.settings,
      sessionToken: sessionToken,
    );
    await _kratos.submit(
      KratosFlowType.settings,
      flow.id,
      {
        'method': 'profile',
        'traits': {'handle': handle, 'name': name},
      },
      sessionToken: sessionToken,
      turnstileToken: turnstileToken,
    );
    await _authenticateWith(sessionToken);
  }

  /// 게스트 요청이 [status]로 거절됐다(요청 파이프라인이 부른다). 게스트 세션이 아니면 아무것도 하지 않는다.
  ///
  /// - 428: 약관에 다시 동의해야 한다([GuestDenial.consentRequired]). [guestDenialCleared]로 지운다.
  /// - 403: 세션을 한 번 확인한다(동시에 거절돼도 한 번). 세션이 끝났으면 미인증이 되고 그 까닭은
  ///   [AuthEndReason.guestRemoved]이다. 세션이 남았으면 모임이 지금 게스트를 받지 않는 것이다
  ///   ([GuestDenial.notAcceptingGuests]).
  ///
  /// 세션을 확인하지 못하면(네트워크 오류) 그 오류를 던지고 상태는 그대로 둔다.
  Future<void> guestRefused(int status) async {
    if (_status is! AuthGuest) return;
    switch (status) {
      case 428:
        _setGuestDenial(GuestDenial.consentRequired);
      case 403:
        await (_guestCheck ??= _checkDeniedGuest().whenComplete(
          () => _guestCheck = null,
        ));
    }
  }

  /// 게스트 거절을 지운다(약관에 동의했거나 다시 불러올 때)
  void guestDenialCleared() => _setGuestDenial(null);

  Future<void> _checkDeniedGuest() async {
    final token = await refreshAccessToken();
    if (token != null) {
      _setGuestDenial(GuestDenial.notAcceptingGuests);
    } else if (_status is AuthUnauthenticated) {
      _status = const AuthStatus.unauthenticated(
        reason: AuthEndReason.guestRemoved,
      );
    }
  }

  void _setGuestDenial(GuestDenial? denial) {
    final current = _status;
    if (current is AuthGuest && current.denial != denial) {
      _status = current.copyWith(denial: denial);
    }
  }

  /// whoami 결과로 될 인증 상태. 게스트면 들어온 모임을 이 기기에 적어 둔 값에서 찾는다.
  ///
  /// [guestMeetingId]는 게스트로 막 들어온 모임이다. 주면 적어 둔다. 회원이면 적어 둔 것을 지운다.
  Future<AuthStatus> _statusOf(
    KratosSession session, {
    String? guestMeetingId,
  }) async {
    final guest = session.guest;
    if (guest == null) {
      await _prefs.remove(guestMeetingKey);
      return AuthStatus.authenticated(
        user: session.user!,
        accessToken: session.accessToken,
      );
    }
    if (guestMeetingId != null) {
      await _prefs.setString(guestMeetingKey, '${guest.id} $guestMeetingId');
    }
    // JWT를 새로 받아도 같은 게스트의 거절 까닭은 그대로 둔다
    final current = _status;
    return AuthStatus.guest(
      guest: guest.withMeeting(_guestMeetingOf(guest.id)),
      accessToken: session.accessToken,
      denial: current is AuthGuest && current.guest.id == guest.id
          ? current.denial
          : null,
    );
  }

  /// 게스트 [guestId]가 들어온 모임. 이 기기에 적어 둔 것이 그 게스트의 것이 아니면 null
  String? _guestMeetingOf(String guestId) {
    if (_prefs.getString(guestMeetingKey)?.split(' ') case [
      final id,
      final meetingId,
    ] when id == guestId && meetingId.isNotEmpty) {
      return meetingId;
    }
    return null;
  }

  /// 지금의 게스트 세션을 끝낸다(기다리지 않는다). 세션 토큰 한 칸을 [next]로 바꾸기 직전에 부른다
  void _endGuestSessionReplacedBy(String next) {
    final current = _sessionToken;
    if (current == null || current == next) return;
    unawaited(
      Future.sync(
        () => _kratos.logout(current),
      ).then<void>((_) {}, onError: (_) {}),
    );
  }
}
