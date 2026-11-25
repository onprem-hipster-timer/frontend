/// 따로 둔 게스트 세션의 시간을 회원 계정으로 옮기는 단계
enum MeetingGuestImportPhase {
  /// 옮길 게스트 세션이 없다
  none,

  /// 옮기는 중
  importing,

  /// 옮겼다
  moved,

  /// 처음 시도에서 게스트를 찾지 못했다(따로 둔 세션은 지웠다)
  notFound,

  /// 연결 문제로 옮기지 못했다(따로 둔 세션은 두고 다시 시도할 수 있다)
  failed,
}
