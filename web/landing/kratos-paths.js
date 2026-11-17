// 앱 밖에서 들어오는 경로를 해시 라우트로 바꾼다: Kratos가 돌려보내는 경로(/login → /#/login 등),
// 모임 만들기(/meetings → /#/meetings)와 모임 공유 링크(/meetings/<모임 번호> → /#/meetings/<모임 번호>,
// lib/features/meeting/presentation/utils/meeting_link.dart).
(function() {
  var appPaths = ['/login', '/signup', '/verification', '/forgot-password', '/mypage', '/auth-error', '/meetings'];
  var path = window.location.pathname;
  var sharedMeeting = /^\/meetings\/[^/]+$/.test(path);
  if (!window.location.hash && (appPaths.indexOf(path) >= 0 || sharedMeeting)) {
    history.replaceState(null, '', '/#' + path + window.location.search);
  }
})();
