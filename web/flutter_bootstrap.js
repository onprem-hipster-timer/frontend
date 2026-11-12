{{flutter_js}}
{{flutter_build_config}}

(function() {
  var m = window.__momeet;
  var flutterHost = document.getElementById('flutter-host');

  _flutter.loader.load({
    config: { hostElement: flutterHost },
    onEntrypointLoaded: async function(engineInitializer) {
      var appRunner = await engineInitializer.initializeEngine({
        hostElement: flutterHost
      });
      await appRunner.runApp();

      m.flutterReady = true;
      document.dispatchEvent(new CustomEvent('flutter-ready'));
    }
  });
})();
