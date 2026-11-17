// 첫 화면이 랜딩인지 정하고 landing/script.js와 함께 쓰는 상태를 둔다.
(function() {
  // 세션 토큰은 암호화돼 있어 값은 읽지 않고 키가 있는지만 본다(lib/core/providers/session_token_store.dart의 sessionTokenKey).
  // flutter.momeet.session_token은 이전 버전의 평문 토큰으로, 앱이 첫 실행에 옮기고 지운다.
  function hasSession() {
    return localStorage.getItem('FlutterSecureStorage.momeet.session_token') !== null
        || localStorage.getItem('flutter.momeet.session_token') !== null;
  }
  function isExplicitLandingHash(hash) {
    return hash === '#/landing' || hash === '#/landing/';
  }
  function isRootHash(hash) {
    return hash === '' || hash === '#/';
  }
  function isLandingHash(hash) {
    return isExplicitLandingHash(hash)
        || (isRootHash(hash) && !hasSession());
  }
  window.__momeet = {
    // 저장된 로그인 세션(회원·게스트)이 있는지. 있으면 동의 배너는 앱이 정한다(landing/consent-banner.js)
    hasSession: hasSession(),
    isLanding: isLandingHash(window.location.hash),
    isLandingHash: isLandingHash,
    flutterReady: false
  };
})();
