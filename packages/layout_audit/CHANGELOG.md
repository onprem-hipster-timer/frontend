# Changelog

## Unreleased

- 배율 사라짐: 같은 글자가 큰 배율에서도 보이면 사본 하나가 접힌 것으로 보고 보고하지 않는다
- 다시 그려 같은 렌더 객체에 다른 위젯이 붙으면 소스 위치를 다시 구한다
- 배율 비교: 1.0배 장면과 큰 배율 장면을 비교해 배율 말줄임·사라짐·밀려남·위계 역전을 별도 보고서(`<이름>_scale`)로 내고 `LAYOUT_AUDIT_SCALE_STRICT`로 따로 실패시킨다
- 떠 있는 버튼(FloatingActionButton)·서랍(Drawer)이 아래 내용을 덮는 것은 겹침으로 보고하지 않는다
- 스크롤 영역 안의 글자가 그 바깥 조상(시트 등)의 잘라내기에 걸린 것도 잘라냄으로 보고하지 않는다

## 0.1.0

- 겹침·넘침·잘라냄·이탈·말줄임·이동 감지, 자동 모드(`LayoutAuditBinding`)와 명시 모드(`pumpAndAuditLayout`), 마크다운·GitHub Actions 보고
