// Kratos가 돌려보내는 경로(/login 등)를 해시 라우트(/#/login)로 바꾼다.
(function() {
  var kratosUiPaths = ['/login', '/signup', '/verification', '/forgot-password', '/mypage', '/auth-error'];
  if (!window.location.hash && kratosUiPaths.indexOf(window.location.pathname) >= 0) {
    history.replaceState(null, '', '/#' + window.location.pathname + window.location.search);
  }
})();
