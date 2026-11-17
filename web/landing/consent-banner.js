// 사용성 분석 동의를 아직 고르지 않았으면 배너를 보인다. 저장된 로그인 세션이 있으면 바로 보이지 않고 앱이 정한다
// (회원은 계정 값을 따르므로 숨기고, 게스트는 이 브라우저 값을 쓰므로 보인다. analytics.js의 banner()).
(function() {
  var banner = document.getElementById('consent-banner');
  var analytics = window.__momeetAnalytics;

  function show() {
    if (analytics.get() === null) banner.hidden = false;
  }

  banner.addEventListener('click', function(e) {
    var value = e.target.getAttribute && e.target.getAttribute('data-consent');
    if (!value) return;
    analytics.set(value);
  });
  document.addEventListener('analytics-consent', function() {
    banner.hidden = true;
  });
  document.addEventListener('analytics-banner', function(e) {
    if (e.detail) {
      show();
    } else {
      banner.hidden = true;
    }
  });

  if (!(window.__momeet && window.__momeet.hasSession)) show();
})();
