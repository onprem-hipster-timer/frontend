// 사용성 분석(Clarity) 동의를 읽고 쓰며, 허용했을 때만 Clarity를 불러온다.
(function() {
  var KEY = 'momeet.analytics_consent';
  var loaded = false;

  function read() {
    try {
      var v = localStorage.getItem(KEY);
      return v === 'granted' || v === 'denied' ? v : null;
    } catch (e) {
      return null;
    }
  }

  function load() {
    if (loaded) return;
    loaded = true;
    (function(c,l,a,r,i,t,y){
      c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};
      t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;
      y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);
    })(window, document, "clarity", "script", "zblwwssbeu");
    window.clarity('consentv2', { ad_Storage: 'denied', analytics_Storage: 'granted' });
  }

  function set(value) {
    if (value !== 'granted' && value !== 'denied') return;
    try { localStorage.setItem(KEY, value); } catch (e) {}
    if (value === 'granted') {
      load();
    } else if (loaded) {
      window.clarity('consent', false);
    }
    document.dispatchEvent(new CustomEvent('analytics-consent', { detail: value }));
  }

  window.__momeetAnalytics = { get: read, set: set };
  if (read() === 'granted') load();
})();
