// 앱 밖에서 들어오는 경로를 해시 라우트로 바꾼다: Kratos가 돌려보내는 경로(/login → /#/login 등),
// 모임 만들기(/meetings → /#/meetings)와 모임 공유 링크(/meetings/<모임 번호> → /#/meetings/<모임 번호>,
// lib/features/meeting/presentation/utils/meeting_link.dart).
// 해시 라우트로 쓴 모임 소개(/#/meet, /#/meet/, 쿼리 포함)는 앱 대신 정적 페이지 /meet(쿼리 그대로)로 보낸다.
// 앱이 뜨기 전에, 그리고 뜬 뒤 주소의 해시가 그렇게 바뀌면(앱이 받기 전에) 보낸다. /#/meetings… 는 그대로다.
(function() {
  var meetHash = /^#\/meet\/?(\?.*)?$/;

  function leaveForMeet() {
    var match = meetHash.exec(window.location.hash);
    if (!match) return false;
    window.location.replace('/meet' + (match[1] || window.location.search));
    return true;
  }

  if (leaveForMeet()) return;

  // 앱(Flutter)보다 먼저 등록해 앱이 없는 화면을 그리기 전에 보낸다
  window.addEventListener('popstate', function(event) {
    if (leaveForMeet()) event.stopImmediatePropagation();
  });
  window.addEventListener('hashchange', leaveForMeet);

  var appPaths = ['/login', '/signup', '/verification', '/forgot-password', '/mypage', '/auth-error', '/meetings'];
  var path = window.location.pathname;
  var sharedMeeting = /^\/meetings\/[^/]+$/.test(path);
  if (!window.location.hash && (appPaths.indexOf(path) >= 0 || sharedMeeting)) {
    history.replaceState(null, '', '/#' + path + window.location.search);
  }
})();
