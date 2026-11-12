// 첫 화면이 랜딩인지 정하고 landing/script.js와 함께 쓰는 상태를 둔다.
(function() {
  // 세션 토큰은 암호화돼 있어 읽지 않고, 앱이 함께 두는 표시(hasSessionKey)를 본다.
  // flutter.momeet.session_token은 이전 버전의 평문 토큰으로, 앱이 첫 실행에 옮기고 지운다.
  function hasSession() {
    return localStorage.getItem('flutter.momeet.has_session') !== null
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
    isLanding: isLandingHash(window.location.hash),
    isLandingHash: isLandingHash,
    flutterReady: false
  };
})();
