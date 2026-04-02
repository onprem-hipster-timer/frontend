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

  // ── CTA button enable on Flutter ready ──
  var flutterReadyListener = null;

  function enableButtons() {
    var btns = document.querySelectorAll('.btn-enter-app');
    btns.forEach(function (btn) {
      btn.classList.remove('disabled');
      btn.textContent = btn.dataset.readyText || '시작하기';
    });
    var strip = document.querySelector('.loading-strip');
    if (strip) strip.style.display = 'none';
  }

  function showLoadError() {
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
