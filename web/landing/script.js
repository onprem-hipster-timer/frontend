// momeet Landing & Loading Script

(function () {
  'use strict';

  var m = window.__momeet;
  var landing = document.getElementById('landing');
  var loading = document.getElementById('loading');

  // Route-based display
  if (m.isLanding) {
    if (landing) landing.style.display = '';
    if (loading) loading.style.display = 'none';
    document.body.classList.add('landing-active');
    initScrollAnimations();
    initFlutterReady();
  } else {
    if (landing) landing.style.display = 'none';
    if (loading) loading.style.display = '';
  }

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

  // Enable CTA buttons when Flutter is ready (CSS pointer-events handles blocking)
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
