// 첫 화면이 랜딩인지 정하고 landing/script.js와 함께 쓰는 상태를 둔다.
(function() {
  function hasSession() {
    return localStorage.getItem('flutter.momeet.session_token') !== null;
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
