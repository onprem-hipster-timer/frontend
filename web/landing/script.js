// momeet Landing & Loading Script
// Single owner of: route detection → visibility toggle → transition

(function () {
  'use strict';

  var m = window.__momeet;
  var landing = document.getElementById('landing');
  var loading = document.getElementById('loading');
  var flutterHost = document.getElementById('flutter-host');

  // ── Route helpers ──
  function isLandingHash(hash) {
    return hash === '#/landing' || hash === '#/landing/'
        || hash === ''         || hash === '#/';
  }

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
    if (isLandingHash(window.location.hash)) {
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
    var targets = document.querySelectorAll('.bento-card, .how-item');
    if (!targets.length) return;

    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            var siblings = entry.target.parentElement.children;
            var idx = Array.prototype.indexOf.call(siblings, entry.target);
            setTimeout(function () {
              entry.target.classList.add('visible');
            }, idx * 150);
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.15 }
    );

    targets.forEach(function (el) { observer.observe(el); });
  }

  // ── CTA button enable on Flutter ready ──
  function initFlutterReady() {
    var TIMEOUT_MS = 20000;

    function enableButtons() {
      var btns = document.querySelectorAll('.btn-enter-app');
      btns.forEach(function (btn) {
        btn.classList.remove('disabled');
        btn.textContent = btn.dataset.readyText || '시작하기';
      });
      var strip = document.querySelector('.loading-strip');
      if (strip) strip.style.display = 'none';
    }

    if (m.flutterReady) {
      enableButtons();
      return;
    }

    document.addEventListener('flutter-ready', enableButtons, { once: true });

    // Fallback: enable buttons after timeout even if Flutter fails
    setTimeout(function () {
      if (!m.flutterReady) enableButtons();
    }, TIMEOUT_MS);
  }
})();
