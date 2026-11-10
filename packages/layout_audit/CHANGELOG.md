# Changelog

## Unreleased

- 예외를 점검 코드에서 빼고 `LayoutAuditPolicy` 하나로 받는다. 떠 있는 위젯·덮는 층·배율을 따르지 않는 글자·버튼 아닌 영역·버릴 발견을 `LayoutAuditConfig.policy`에서 정하고, `LayoutAuditOptions.ignore`·`ScaleAuditOptions.ignore`는 없앤다. 정책이 비면 예외가 없다
- 배율 사라짐: 같은 글자가 큰 배율에서도 보이면 사본 하나가 접힌 것으로 보고 보고하지 않는다
- 다시 그려 같은 렌더 객체에 다른 위젯이 붙으면 소스 위치를 다시 구한다
- 배율 비교: 1.0배 장면과 큰 배율 장면을 비교해 배율 말줄임·사라짐·밀려남·위계 역전을 별도 보고서(`<이름>_scale`)로 내고 `LAYOUT_AUDIT_SCALE_STRICT`로 따로 실패시킨다
- 스크롤 영역 안의 글자가 그 바깥 조상(시트 등)의 잘라내기에 걸린 것도 잘라냄으로 보고하지 않는다

## 0.1.0

- 겹침·넘침·잘라냄·이탈·말줄임·이동 감지, 자동 모드(`LayoutAuditBinding`)와 명시 모드(`pumpAndAuditLayout`), 마크다운·GitHub Actions 보고
