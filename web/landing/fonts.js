// Flutter 에셋 폰트(FontManifest.json)를 페이지에도 등록한다.
fetch('assets/FontManifest.json')
  .then(function(r) { return r.json(); })
  .then(function(manifest) {
    manifest.forEach(function(entry) {
      entry.fonts.forEach(function(font) {
        var face = new FontFace(entry.family, 'url(assets/' + font.asset + ')');
        face.load().then(function(loaded) { document.fonts.add(loaded); });
      });
    });
  });
