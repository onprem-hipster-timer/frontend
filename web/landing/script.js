// momeet Landing Page Script

(function () {
  'use strict';

  // Intersection Observer for scroll animations
  function initScrollAnimations() {
    var targets = document.querySelectorAll('.feature-card, .flow-step');
    if (!targets.length) return;

    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry, index) {
          if (entry.isIntersecting) {
            // Staggered delay based on element position among siblings
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

    targets.forEach(function (el) {
      observer.observe(el);
    });
  }

  // Smooth transition: landing -> Flutter app
  function initFlutterTransition() {
    var landing = document.getElementById('landing');
    if (!landing) return;

    // Watch for Flutter engine readiness
    // Flutter replaces the body content, but we can detect when it starts
    var checkInterval = setInterval(function () {
      var flutterView = document.querySelector('flutter-view, flt-glass-pane');
      if (flutterView) {
        clearInterval(checkInterval);
        landing.classList.add('fade-out');
        document.body.classList.remove('landing-active');
        setTimeout(function () {
          landing.remove();
        }, 500);
      }
    }, 200);
  }

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () {
      initScrollAnimations();
      initFlutterTransition();
    });
  } else {
    initScrollAnimations();
    initFlutterTransition();
  }
})();
