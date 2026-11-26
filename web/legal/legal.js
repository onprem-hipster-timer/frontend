// 돌아가기: 이 사이트에서 같은 탭으로 왔으면 뒤로, 새 탭으로 열렸으면 탭을 닫고, 둘 다 안 되면 링크대로 홈으로 간다.
(function () {
  var back = document.getElementById('legal-back');
  if (!back) return;
  back.addEventListener('click', function (event) {
    var fromSite = false;
    try {
      fromSite = new URL(document.referrer).origin === location.origin;
    } catch (_) {
      // 리퍼러가 없다
    }
    if (fromSite && history.length > 1) {
      event.preventDefault();
      history.back();
      return;
    }
    if (window.opener || history.length === 1) {
      window.close();
      // 브라우저가 닫기를 막으면 링크대로 간다
      if (window.closed) event.preventDefault();
    }
  });
})();

// /privacy, /terms, /trust: body[data-gist]의 Gist에서 마크다운을 읽어 그린다. Gist 개정 이력이 문서의 변경 이력이다.
(function () {
  var GIST_OWNER = 'jjh4450';
  var id = document.body.getAttribute('data-gist');
  var gistUrl = 'https://gist.github.com/' + GIST_OWNER + '/' + id;
  var content = document.getElementById('legal-content');
  var meta = document.getElementById('legal-meta');

  function showFallback() {
    content.innerHTML = '';
    var p = document.createElement('p');
    p.textContent = '문서를 불러오지 못했습니다. ';
    var a = document.createElement('a');
    a.href = gistUrl;
    a.textContent = '원문 보기';
    p.appendChild(a);
    content.appendChild(p);
  }

  fetch('https://api.github.com/gists/' + id, {
    headers: { Accept: 'application/vnd.github+json' }
  })
    .then(function (r) {
      if (!r.ok) throw new Error(String(r.status));
      return r.json();
    })
    .then(function (gist) {
      var files = Object.keys(gist.files || {}).map(function (k) { return gist.files[k]; });
      var md = files.filter(function (f) { return /\.md$/.test(f.filename); })[0];
      if (!md || !md.content) throw new Error('no markdown');
      // 외부에서 읽은 내용이므로 정리한 HTML만 넣는다
      content.innerHTML = DOMPurify.sanitize(marked.parse(md.content));
      var updated = new Date(gist.updated_at);
      meta.textContent = '';
      if (!isNaN(updated)) {
        meta.appendChild(document.createTextNode('최종 갱신: ' + updated.toLocaleDateString('ko-KR') + ' · '));
      }
      var a = document.createElement('a');
      a.href = gistUrl + '/revisions';
      a.target = '_blank';
      a.rel = 'noopener';
      a.textContent = '개정 이력(변경 전후 비교)';
      meta.appendChild(a);
    })
    .catch(showFallback);
})();
