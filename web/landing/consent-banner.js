// 사용성 분석 동의를 아직 고르지 않았으면 배너를 보인다.
(function() {
  var banner = document.getElementById('consent-banner');
  var analytics = window.__momeetAnalytics;
  if (analytics.get() !== null) return;
  banner.hidden = false;
  banner.addEventListener('click', function(e) {
    var value = e.target.getAttribute && e.target.getAttribute('data-consent');
    if (!value) return;
    analytics.set(value);
  });
  document.addEventListener('analytics-consent', function() {
    banner.hidden = true;
  });
})();
