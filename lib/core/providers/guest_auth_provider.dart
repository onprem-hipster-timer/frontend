part of 'auth_provider.dart';

/// 게스트 세션: 회원과 같은 Kratos 세션·JWT지만 모임 하나에 속하고 이메일이 없다.
///
/// 세션 토큰 저장소는 회원과 한 칸을 같이 쓴다. 게스트가 회원으로 로그인하면 게스트 세션은 끝낸다.
extension GuestAuth on AuthNotifier {
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
    return AuthStatus.guest(
      guest: guest.withMeeting(_guestMeetingOf(guest.id)),
      accessToken: session.accessToken,
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
