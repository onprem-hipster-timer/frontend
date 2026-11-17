/// 게스트 세션의 사람. 모임 하나에 속한 Kratos 계정이라 이메일이 없다.
///
/// 값으로 비교한다. JWT만 새로 받으면 같은 값이 와서 `currentGuestProvider`를 보는 provider가 다시 계산되지 않는다.
class GuestUser {
  const GuestUser({
    required this.id,
    required this.handle,
    required this.name,
    this.meetingId,
  });

  /// Kratos identity ID (백엔드 JWT의 sub)
  final String id;

  /// 로그인 식별자(`<guest_id>@guest.invalid`). 이름을 바꿀 때 그대로 보낸다
  final String handle;

  /// 모임에서 보이는 게스트 이름
  final String name;

  /// 게스트로 들어온 모임. Kratos 세션에는 없어 들어올 때 이 기기에 적어 둔 값이고, 모르면 null이다
  final String? meetingId;

  GuestUser withMeeting(String? meetingId) =>
      GuestUser(id: id, handle: handle, name: name, meetingId: meetingId);

  @override
  bool operator ==(Object other) =>
      other is GuestUser &&
      other.id == id &&
      other.handle == handle &&
      other.name == name &&
      other.meetingId == meetingId;

  @override
  int get hashCode => Object.hash(id, handle, name, meetingId);
}
