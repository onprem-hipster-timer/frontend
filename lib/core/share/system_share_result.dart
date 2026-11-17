/// 시스템 공유 창으로 보낸 결과
enum SystemShareResult {
  /// 공유했다
  shared,

  /// 공유 창을 닫았다
  dismissed,

  /// 공유 창이 없다(웹 공유를 지원하지 않는 브라우저, 앱)
  unavailable,

  /// 공유하지 못했다
  failed,
}
