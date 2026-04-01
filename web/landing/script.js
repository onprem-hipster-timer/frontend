// momeet Landing & Loading Script

(function () {
  'use strict';

  var path = window.location.pathname;
  var isLanding = path === '/landing' || path === '/landing/';

  var landing = document.getElementById('landing');
  var loading = document.getElementById('loading');

  // Route-based display
  if (isLanding) {
    if (landing) landing.style.display = '';
    if (loading) loading.style.display = 'none';
    document.body.classList.add('landing-active');
    initScrollAnimations();
    initFlutterReady();
  } else {
    if (landing) landing.style.display = 'none';
    if (loading) loading.style.display = '';
    document.body.classList.remove('landing-active');
  }

  // ===== Scroll animations for landing =====
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

  // ===== Landing: enable CTA when Flutter fires 'flutter-ready' =====
  function initFlutterReady() {
    var ctaButtons = document.querySelectorAll('.btn-enter-app');
    var loadingStrip = document.querySelector('.loading-strip');

    // Block clicks while disabled
    ctaButtons.forEach(function (btn) {
      btn.addEventListener('click', function (e) {
        if (btn.classList.contains('disabled')) {
          e.preventDefault();
        }
      });
    });

    function enableButtons() {
      ctaButtons.forEach(function (btn) {
        btn.classList.remove('disabled');
        btn.textContent = btn.dataset.readyText || '시작하기';
      });
      if (loadingStrip) loadingStrip.style.display = 'none';
    }

    // Already ready (e.g. cached/fast load)
    if (window.__momeetFlutterReady) {
      enableButtons();
      return;
    }

    // Wait for custom event from flutter bootstrap
    document.addEventListener('flutter-ready', enableButtons, { once: true });
  }
})();
