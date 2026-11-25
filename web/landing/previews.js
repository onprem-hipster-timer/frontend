// 랜딩·모임 소개의 앱 화면 미리보기(data-preview). 그림은 배포 때 찍으므로(tool/landing_previews/capture.mjs),
// 없거나 받지 못하면 그 그림을 담은 figure째 숨긴다. 미리보기보다 뒤에 불러온다.
(function () {
  'use strict';

  document.querySelectorAll('img[data-preview]').forEach(function (img) {
    function hide() { img.closest('figure').hidden = true; }
    if (img.complete && img.naturalWidth === 0) {
      hide();
    } else {
      img.addEventListener('error', hide);
    }
  });
})();
