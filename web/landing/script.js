// momeet Landing & Loading Script
// Single owner of: route detection → visibility toggle → transition

(function () {
  'use strict';

  var m = window.__momeet;
  var landing = document.getElementById('landing');
  var loading = document.getElementById('loading');
  var flutterHost = document.getElementById('flutter-host');

  // Cleanup state for re-entrant calls
  var scrollObserver = null;
  var flutterReadyTimeout = null;

  // ── Visibility (single source of truth) ──
  // flutter-host는 CSS(body.landing-active #flutter-host)가 제어 — JS에서 display 토글 금지
  function showLanding() {
    if (landing) landing.style.display = '';
    if (loading) loading.style.display = 'none';
    document.body.classList.add('landing-active');
    initScrollAnimations();
    initFlutterReady();
  }

  function showApp() {
    if (landing) landing.style.display = 'none';
    document.body.classList.remove('landing-active');

    // Flutter 이미 준비됨 → 로딩 스크린 불필요
    if (m.flutterReady) {
      if (loading) {
        loading.classList.add('fade-out');
        setTimeout(function () { loading.remove(); }, 400);
      }
    } else {
      if (loading) loading.style.display = '';
    }
  }

  // ── Initial route ──
  if (m.isLanding) {
    showLanding();
  } else {
    showApp();
  }

  // ── Hash change: landing ↔ app transition ──
  window.addEventListener('hashchange', function () {
    if (m.isLandingHash(window.location.hash)) {
      m.isLanding = true;
      showLanding();
    } else if (m.isLanding) {
      m.isLanding = false;
      if (landing) {
        landing.classList.add('fade-out');
        landing.addEventListener('animationend', function handler() {
          landing.classList.remove('fade-out');
          landing.removeEventListener('animationend', handler);
          showApp();
        });
      } else {
        showApp();
      }
    }
  });

  // ── Flutter ready: loading fade-out (non-landing) & CTA enable (landing) ──
  document.addEventListener('flutter-ready', function () {
    if (!m.isLanding) {
      // Non-landing: fade out loading screen
      if (loading) {
        loading.classList.add('fade-out');
        setTimeout(function () { loading.remove(); }, 400);
      }
    }
  }, { once: true });

  // ── Scroll animations ──
  function initScrollAnimations() {
    if (scrollObserver) scrollObserver.disconnect();

    var targets = document.querySelectorAll('.bento-card, .how-item');
    if (!targets.length) return;

    scrollObserver = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            var siblings = entry.target.parentElement.children;
            var idx = Array.prototype.indexOf.call(siblings, entry.target);
            setTimeout(function () {
              entry.target.classList.add('visible');
            }, idx * 150);
            scrollObserver.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.15 }
    );

    targets.forEach(function (el) { scrollObserver.observe(el); });
  }

  // ── Simulated progress ──
  var progressInterval = null;
  var currentProgress = 0;

  function updateProgress(pct) {
    currentProgress = pct;
    var rounded = Math.round(pct);
    var bar = document.querySelector('.loading-strip-bar');
    var pctEl = document.querySelector('.loading-pct');
    var btns = document.querySelectorAll('.btn-enter-app');

    if (bar) bar.style.width = rounded + '%';
    if (pctEl) pctEl.textContent = rounded + '%';
    btns.forEach(function (btn) {
      btn.style.setProperty('--load-pct', rounded + '%');
    });
  }

  function startProgress() {
    currentProgress = 0;
    var elapsed = 0;
    var DURATION = 18000; // 90%에 도달하는 예상 시간 (ms)
    var INTERVAL = 150;
    updateProgress(0);
    document.querySelectorAll('.btn-enter-app').forEach(function (btn) {
      btn.classList.add('loading');
    });
    if (progressInterval) clearInterval(progressInterval);
    progressInterval = setInterval(function () {
      elapsed += INTERVAL;
      // ease-out: 초반 빠르게 → 후반 감속, 90%에 수렴
      var t = Math.min(elapsed / DURATION, 1);
      var eased = 1 - Math.pow(1 - t, 3);
      currentProgress = eased * 90;
      updateProgress(currentProgress);
      if (t >= 1) clearInterval(progressInterval);
    }, INTERVAL);
  }

  function stopProgress() {
    if (progressInterval) clearInterval(progressInterval);
    updateProgress(100);
    document.querySelectorAll('.btn-enter-app').forEach(function (btn) {
      btn.classList.remove('loading');
    });
  }

  // ── CTA button enable on Flutter ready ──
  var flutterReadyListener = null;

  function enableButtons() {
    stopProgress();
    var btns = document.querySelectorAll('.btn-enter-app');
    btns.forEach(function (btn) {
      btn.classList.remove('disabled');
      btn.textContent = btn.dataset.readyText || '시작하기';
    });
    var strip = document.querySelector('.loading-strip');
    if (strip) {
      setTimeout(function () { strip.style.display = 'none'; }, 400);
    }
  }

  function showLoadError() {
    if (progressInterval) clearInterval(progressInterval);
    var strip = document.querySelector('.loading-strip');
    if (strip) {
      strip.classList.add('error');
      strip.innerHTML = '앱을 불러오지 못했습니다. 페이지를 새로고침해 주세요.';
    }
  }

  function initFlutterReady() {
    var TIMEOUT_MS = 20000;

    if (m.flutterReady) {
      enableButtons();
      return;
    }

    startProgress();

    // 이전 리스너/타임아웃 정리 (랜딩 재진입 시 누적 방지)
    if (flutterReadyListener) {
      document.removeEventListener('flutter-ready', flutterReadyListener);
    }
    if (flutterReadyTimeout) clearTimeout(flutterReadyTimeout);

    flutterReadyListener = enableButtons;
    document.addEventListener('flutter-ready', flutterReadyListener, { once: true });

    flutterReadyTimeout = setTimeout(function () {
      if (!m.flutterReady) showLoadError();
    }, TIMEOUT_MS);
  }
})();
