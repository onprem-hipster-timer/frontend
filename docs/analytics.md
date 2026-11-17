# 사용성 분석 이벤트와 태그 (Microsoft Clarity)

앱은 사용성 분석에 동의한 브라우저에서만 Clarity에 이벤트와 세션 태그를 보낸다. Clarity는 동의한 뒤에만
`web/landing/analytics.js`가 불러오고, 앱(`lib/core/analytics/usage_analytics.dart`)은 `window.clarity`가 있을 때만
부른다. 동의 전, 웹이 아닌 환경, 테스트에서는 아무것도 보내지 않는다.

이름과 값은 `UsageEvent`·`MeetingAccountTag`의 고정 문자열뿐이다. 닉네임, handle, 계정·게스트·모임 id, 모임
번호·제목처럼 사람이 넣은 글자나 식별자는 보내지 않는다. 이름을 더하거나 바꾸면 enum과 이 표를 함께 고친다.

## 동의

동의는 이 브라우저(`localStorage`의 `momeet.analytics_consent`, `web/landing/analytics.js`)와 회원 계정(지금 약관
버전의 동의 기록의 `analytics`, 프로필의 `analytics_consent`)에 둔다. Clarity는 브라우저 값이 허용일 때만 불러온다.

- 회원으로 로그인한 동안은 계정 값이 기준이다(`lib/core/analytics/analytics_account_sync.dart`).
  - 계정에 값이 있으면 브라우저에 맞춘다(허용이면 Clarity를 불러오고, 거부면 멈춘다).
  - 계정에 값이 없고 브라우저에 고른 값이 있으면 그 값을 계정에 한 번 보낸다.
  - 둘 다 없으면 모으지 않는다. 회원에게는 처음 방문 배너를 보이지 않는다.
  - 바뀐 약관에 아직 동의하지 않았으면 계정 값을 읽지도 보내지도 않는다.
- 약관 동의 화면의 선택 항목과 마이페이지의 '사용성 분석 허용'은 `PUT /v1/users/me/consent`(지금 약관 버전)에
  `analytics`를 담아 보내고, 저장되면 브라우저에도 그 값을 둔다. 같은 버전에 다시 보내면 서버는 `analytics`만 바꾼다.
- 게스트와 로그인하지 않은 방문자는 브라우저 값만 쓴다. 게스트를 만들거나 다시 동의할 때 브라우저 값을 게스트 동의
  본문의 `analytics`에 담지만 앱은 읽지 않는다.
- 로그아웃해도 마지막으로 맞춘 값은 브라우저에 둔다.
- 처음 방문 배너(`web/landing/consent-banner.js`)는 브라우저 값이 없을 때 보인다. 저장된 로그인 세션이 있으면 앱이
  정한다(회원은 숨기고, 게스트는 값이 없으면 보인다).

## 이벤트 (`clarity("event", 이름)`)

| 이름 | 보내는 때 |
| --- | --- |
| `meeting_login_request_shown` | 방문자에게 로그인·Guest 요청을 띄울 때. 좁은 화면은 '내 시간 입력하기'를 누르거나 격자를 칠하려 해 요청 시트가 뜰 때마다, 넓은 화면은 격자를 칠하려 해 옆의 로그인 상자를 떨 때마다 |
| `meeting_login_chosen` | 요청(시트나 넓은 화면의 로그인 상자)에서 '로그인'을 누를 때 |
| `meeting_guest_chosen` | 요청에서 'Guest'를 누를 때 |
| `meeting_member_arrived` | 로그인한 회원에게 모임 화면이 열릴 때(화면 하나에 한 번. 로그인을 다녀온 경우와 이미 로그인한 경우 모두) |
| `meeting_guest_entered_new` | 처음 쓰는 닉네임으로 게스트를 만들고 들어갔을 때 |
| `meeting_guest_entered_returning` | 이미 있는 게스트 닉네임으로 들어갔을 때 |
| `meeting_guest_converted` | '안전한 정규 유저로 바꾸기'로 로그인한 회원에게 게스트로 넣은 시간을 옮겼을 때(응답을 잃은 뒤 다시 읽어 옮긴 것을 확인한 경우 포함) |

## 세션 태그 (`clarity("set", 키, 값)`)

| 키 | 값 | 다는 때 |
| --- | --- | --- |
| `meeting_account` | `visitor`, `member`, `guest` | 모임 화면이 열리거나 그 화면의 계정 종류가 바뀔 때. 한 세션에서 바뀌면(예: 방문자 → 게스트) 값이 더해진다 |

## Clarity에서 보기

- 새 태그는 처음 받은 뒤 30분~2시간이 지나야 필터에 나온다. 그 전에도 녹화의 이벤트 목록에서는 보인다.
- 로그인으로 들어온 세션과 게스트로 들어온 세션: Dashboard에서 필터의 Smart events에 `meeting_member_arrived`를 고른
  세션 수와, `meeting_guest_entered_new`·`meeting_guest_entered_returning`을 고른 세션 수를 비교한다.
- 요청을 본 방문자가 무엇을 골랐는지: Smart events `meeting_login_request_shown`으로 거른 뒤 `meeting_login_chosen`과
  `meeting_guest_chosen`의 수를 비교한다.
- 계정 종류로 나눠 보기: 필터의 Custom tags에서 `meeting_account`를 고른다. 방문자로 시작해 게스트가 된 세션은
  `visitor`와 `guest`를 함께 가진다.
- Clarity는 동의한 사람만 센다. 동의하지 않은 사람의 선택은 어느 쪽에도 들어가지 않으므로 비율은 동의한 사람 안의
  비율이다.
