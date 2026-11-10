# layout_audit

위젯 테스트의 렌더 트리를 훑어 **글자·이미지가 서로 겹치는 곳**, **RenderFlex 넘침**, **잘려 나간 글자**, **화면 밖으로 나간 글자**, **말줄임 처리된 글자**를 찾아 보고하는 테스트 라이브러리. `flutter_test`만 의존한다.

기본은 **경고 전용**이다. 발견이 있어도 테스트는 통과하고, 보고서만 남긴다.

## 붙이는 법

### 1. 자동 모드 — 모든 위젯 테스트에 한 번에

`test/flutter_test_config.dart`:

```dart
import 'dart:async';

import 'package:layout_audit/layout_audit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LayoutAuditBinding.ensureInitialized(config: const LayoutAuditConfig());
  await testMain();
}
```

이후 모든 `testWidgets`는 본문이 끝난 시점의 화면을 감사받는다. 기존 테스트의 성패는 바뀌지 않는다.

- 끄기: `LAYOUT_AUDIT=off fvm flutter test`
- 특정 테스트 제외: `LayoutAuditConfig(skipTests: RegExp('…'))`
- 의도된 겹침 무시: `LayoutAuditConfig(options: LayoutAuditOptions(ignore: (f) => f.insideStack))`
- 스위트 전체를 다른 화면·배율로: `LAYOUT_AUDIT_VIEWPORT=320x568@2 LAYOUT_AUDIT_TEXT_SCALE=2.0 fvm flutter test` (기존 단언이 깨질 수 있다)

### 2. 명시 모드 — 위험한 위젯을 화면 크기 × 글자 배율 × 긴 텍스트로

```dart
testLayoutAudit(
  'todo_tree_tile',                      // 보고서 파일 이름
  subject: '제목',                        // 테스트 이름·보고서 라벨에 쓰인다
  within: find.byType(TodoTreeTile),
  build: (text) => wrapWithApp()(TodoTreeTile(/* text.value를 제목으로 */)),
  verify: (tester) => expect(find.byType(TodoTreeTile), findsOneWidget),
);
```

스트레스 텍스트마다 `testWidgets`를 하나씩 등록하고, 각각 `LayoutAuditVariants.all`의 조합 전부를 돈다. `build`는 앱 껍데기까지 포함한 위젯을 돌려준다. 명시 모드로 점검한 테스트는 자동 모드가 다시 보고하지 않는다. 한 화면만 직접 다루려면 `tester.pumpAndAuditLayout(...)`을 쓴다.

- `LayoutAuditVariants.phones`(폰 7종 × 배율 1.0·1.3·2.0 = 21), `large`(폴더블·태블릿·데스크톱 9종 × 1.0·1.3 = 18), `all`(39)
- `StressTexts`: 한국어 긴 문장, 띄어쓰기 없는 영문, 이모지, 숫자
- 두 프레임(100ms 간격)을 비교해 움직이는 글자(마퀴)를 구분하고, 한 프레임에만 보인 발견은 `info`로 낮춘다

## 보고서 읽는 법

```
레이아웃 점검: todo_tree_tile / phone-small 360x800 @3.0x, 글자 2.0배 — warning 2, notice 1, info 0 → build/layout_audit/todo_tree_tile.md (todo_tree_tile.html)
[겹침] '수정'(lib/features/todo/presentation/widgets/todo_tree_tile.dart:315)이 '팀 주간 회의 자료 준비와 분기별…'(…:245)을 38% 가립니다 (가리는 위젯: …:300, Stack 안) | ∩=(194.0,14.0,212.0,36.0)
```

- `lib/…:N`은 그 글자를 만든 위젯의 소스 줄이다. 가리는 위젯은 두 글자의 공통 조상 바로 아래에서 위쪽 글자를 품은 위젯이다.
- 마크다운 보고서는 `build/layout_audit/<이름>.md`에 쌓인다(테스트 파일 단위로 하나).
- HTML 보고서(`build/layout_audit/<이름>.html`)는 브라우저로 열어 심각도·종류로 거르고, 발견 위치를 화면 축소판에서 본다.
- GitHub Actions에서는 해당 소스 줄에 어노테이션(스텝당 10개까지)을 달고, 잡 요약에 전체 표를 쓴다.

| 종류 | 뜻 | 기본 심각도 |
|---|---|---|
| 겹침 | 두 글자·이미지 상자가 양 축 2px 넘게 겹침 | 작은 쪽이 25% 이상 가려지면 warning, 아니면 notice |
| 넘침 | RenderFlex 넘침, ListTile 폭 단언 | warning |
| 잘라냄 | 글자가 상자나 조상 클립 밖으로 2px 넘게 잘림 (`TextOverflow.clip`, `softWrap: false`) | warning |
| 이탈 | 클립 없이 화면 밖으로 2px 넘게 나감 | warning |
| 말줄임 | `maxLines`·`ellipsis`로 줄어듦 (의도된 처리) | notice |
| 이동 | 두 프레임 사이에 움직임 (마퀴로 추정) | notice |

## 엄격 모드

`fvm flutter test --dart-define=LAYOUT_AUDIT_STRICT=true` — warning이 있는 보고서는 테스트를 실패시킨다. notice·info는 실패시키지 않는다. 자동 모드는 항상 경고 전용이다.

## 한계

- 테스트 기본 글꼴(Ahem)은 모든 글자가 1em 정사각형이다. 한글 폭은 실제와 비슷하지만 라틴·숫자는 약 2배 넓게 잡힌다.
- `TextField`(`RenderEditable`)는 검사하지 않는다. 힌트·라벨이 입력 상자 위에 겹치는 것이 설계이기 때문이다.
- 자동 모드는 한 프레임만 보므로 마퀴는 말줄임·잘라냄으로 나올 수 있다.
- 캔버스에 직접 그린 글자(`CustomPaint`, 일부 서드파티 달력)는 리프가 아니라 검사 대상이 아니다.
- 다이얼로그·시트가 뒤 화면을 덮는 것은 겹침으로 보지 않는다.
- 떠 있는 버튼(FloatingActionButton)과 서랍(Drawer)이 그 아래 내용을 덮는 것도 겹침으로 보지 않는다. 목록 끝에 버튼 높이만큼 여백을 두었는지는 따로 확인한다.
- 위아래는 그리는 순서로 정한다. 공통 조상이 자식을 목록 순서대로 그리는 위젯(Stack, Row·Column, Wrap, Overlay)일 때만 알 수 있고, ListTile·Chip처럼 칸으로 자식을 두는 위젯이나 스크롤 뷰포트, Flow 안의 겹침은 "순서 불명"으로 보고한다.

## 패키지 테스트

```bash
cd packages/layout_audit && fvm flutter test
```
