# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

#### Timer
- 타이머 시작·일시정지·재개·정지를 REST(`POST /v1/timers`, `PATCH /v1/timers/{id}/pause`·`resume`, `POST /v1/timers/{id}/stop`)로 보낸다
- 타이머 REST 요청에 `timezone=UTC`를 붙인다
- 경과 시간 표시를 `displayElapsed` 하나로 통일 (RUNNING: `elapsed_time + (now - started_at)`, 그 외: `elapsed_time`)
  - 타이머 화면, 일정 상세의 타이머 목록, Todo 목록이 같은 계산을 쓴다
  - `now`는 타이머 REST 응답의 `Date` 헤더로 보정한 서버 기준 시각이다
- 타이머 화면은 남은 시간(`allocated_duration - displayElapsed`, 0 아래로 내려가지 않음)을 센다
  - 0이 되면 `00:00:00`과 '시간 종료'로 표시한다
  - 타이머 목록의 진행 중·일시정지 항목도 남은 시간, 끝난 항목은 경과 시간을 보여 준다
- 새 타이머의 기본 집중 시간(`allocated_duration`)을 25분으로. 새 작업 시작에서 1~600분을 입력하거나 15·25·45·60분 칩으로 채운다
- 타이머 화면의 정지를 '완료'로 표시 (버튼, 확인 다이얼로그, 알림). 일시정지·재개는 확인 없이 바로 보낸다
- 일시정지·재개는 누르는 즉시 대시보드와 타이머 목록에 반영하고 REST는 뒤에서 보낸다
  - 일시정지는 서버 기준 시각의 경과 시간으로 멈추고, 재개는 지금부터 다시 센다. 응답이 오면 응답 값으로 바꾸고, 실패하면 되돌린 뒤 알린다
  - 명령 중에 대시보드·목록 버튼을 스피너로 바꾸지 않는다. 새 타이머 시작만 응답을 기다리며 시작 버튼 안에 진행 표시를 둔다
  - 응답을 기다리는 타이머에 겹친 명령은 보내지 않는다
- 타이머 화면 대시보드에 60분 다이얼을 두고 남은 시간을 12시부터 시계 방향으로 채운 원판으로 보여 준다
  - 활성 타이머가 없으면 다이얼을 끌어 새 작업의 집중 시간을 고르고, 새 작업 시작의 분 칸이 그 값으로 열린다
  - 집중 시간이 60분을 넘으면 다이얼 한 바퀴를 60분 단위로 늘린다. 진행 중인 타이머의 다이얼은 끌어도 바뀌지 않는다
  - 다이얼을 화면의 중심으로 두고, 그 아래에 작업 제목, 디지털 시계, 일시정지·시간 종료 캡션, 제어 버튼을 둔다. 상태 표시 칩과 시작 시각은 없앤다
  - 폭 600 미만은 다이얼만 두고 앱 바의 타이머 목록 버튼으로 목록을 바텀 시트로 연다. 600 이상은 다이얼 오른쪽에 타이머 목록을 둔다
- 시간이 끝난 타이머는 서버가 일시정지 상태로 돌려주며, 대시보드와 타이머 목록은 일시정지·재개 대신 완료와 5분 연장만 보여 준다
  - 연장은 `PATCH /v1/timers/{id}`로 `allocated_duration`을 늘린 뒤 재개한다. 늘리기에 실패하면 재개하지 않는다
  - PATCH 응답이 PAUSED가 아니면(서버가 아직 실행 중으로 둔 타이머) 재개를 보내지 않는다
- `displayElapsed`는 `allocated_duration`을 넘지 않는다
- 친구 알림에 `expire`(타이머 종료) 문구를 더한다

#### Timer WebSocket
- 소켓을 수신 전용으로 바꿈. 클라이언트는 45초마다 `ping`만 보낸다
- 소켓 주소를 `REALTIME_BACKEND`(`inprocess`: `/v1/ws/timers`, `cloudflare`: `/realtime/ws`)로 고른다
- 서버 메시지를 이벤트 봉투(`id`·`type`·`from_user`·`timestamp`·`payload`)로 받는다
  - 같은 `id`는 한 번만 반영하고, `updated_at`이 가진 값보다 이전인 타이머는 버린다 (REST 응답에도 같은 규칙)
  - `timer.deleted`를 받은 타이머는 이후 이벤트로 되살리지 않는다
  - 이벤트는 타이머 자체 필드만 갱신하고, 관계 필드(일정·Todo 등)는 REST로 채운다
    (처음 보는 타이머, 연결이 바뀐 타이머, `update` 이벤트는 `GET /v1/timers/{id}`로 다시 받는다)
  - (재)연결마다 REST로 활성 타이머를 다시 맞춘다
- 닫힘 코드별 재연결: `1008`은 JWT를 한 번 새로 받아 다시 연결하고 또 거부되면 멈춘다, `4000`은 바로,
  그 외는 지수 백오프(1s부터 두 배, 상한 30s)와 지터로 횟수 제한 없이 다시 연결한다
- 앱이 포그라운드로 돌아오면 끊긴 소켓을 바로 다시 연결한다
- 친구 알림은 `from_user`가 내가 아닌 이벤트의 `actor_name`·`action`으로 띄운다

#### Todo
- Todo 목록의 누적 집중 시간·태그·하위 Todo 개수를 제목 아래 줄로 옮긴다. 자리가 모자라면 줄을 바꿔 좁은 화면에서도 넘치지 않는다

#### API
- OpenAPI 스펙 v2026.11.09-76cce36 반영 및 API 클라이언트 재생성

### Added

#### Timer
- 타이머 화면의 작업 제목 옆에 연결된 Todo의 상태 아이콘. 일시정지 중에는 그 자리에서 상태를 바꾼다
  - `PATCH /v1/todos/{id}`만 보낸다. Todo가 완료·취소되면 서버가 타이머를 끝내고 `timer.updated`로 알린다
  - 바꾼 상태는 PATCH 응답으로 바로 보여 준다. 다른 기기에서 바뀐 Todo는 타이머를 다시 읽을 때 반영하고 Todo 목록도 다시 읽게 한다
- 타이머 화면의 휴식 카운트다운. 기기 안에서만 세고 서버에 보내지 않으므로 타이머 목록에 나오지 않고 친구에게도 알리지 않는다
  - 활성 타이머가 없으면 시작 버튼 위에서 작업·휴식을 고른다. 다이얼로 고른 시간은 작업(기본 25분)과 휴식(기본 5분)이 따로 기억한다
  - 휴식은 다이얼로그 없이 바로 시작한다. 세는 동안은 '휴식 끝내기', 0이 되면 '휴식 종료'와 '확인'으로 닫는다
  - 시간이 남은 일시정지 타이머에서도 휴식을 시작한다. 휴식을 닫으면 그 타이머를 다시 보여 준다
  - 활성 타이머가 실행되면(재개, 다른 기기, Todo 등) 타이머 화면이 보이지 않아도 휴식을 바로 끝낸다
- 새 작업 시작에서 할 일을 연결한다 (`POST /v1/timers`의 `todo_id`)
  - 완료·취소한 할 일과 공유받은 할 일을 뺀 내 할 일을 제목으로 찾아 고른다. '연결 안 함'으로 연결을 푼다
  - 작업명이 비었거나 앞서 고른 할 일의 제목 그대로면 고른 할 일의 제목으로 채운다. 작업명 없이 시작하면 할 일 제목, 할 일도 없으면 '새 작업'
  - 할 일 목록을 읽는 동안과 읽지 못했을 때는 할 일 칸을 막고, 연결 없이 시작한다

#### Todo
- Todo 목록에 하위 Todo를 포함한 누적 집중 시간
  - 끝난(COMPLETED) 타이머의 경과 시간에 진행 중·일시정지 타이머의 `displayElapsed`를 더해 1초마다 갱신한다
  - 취소한 타이머는 더하지 않는다. 활성 타이머가 끝나면 타이머 목록을 다시 읽는다
- Todo·일정 삭제 시 서버가 연결 타이머 처리(`linked_timer_policy`)를 요구하면 '연결만 해제'·'타이머 삭제' 중 골라 다시 삭제한다
- Todo 목록에서 바로 타이머를 시작한다. 완료·취소하지 않은 내 Todo에 타이머 시작 버튼을 두고, 그 Todo를 고른 새 작업 시작 다이얼로그를 연다
  - 시작하면 타이머 화면으로 간다. 실패하면 알리고 머문다
  - 진행 중·일시정지 타이머가 있으면 버튼 대신 남은 시간(mm:ss, 한 시간 이상은 h:mm:ss, 0이면 에러 색)을 1초마다 보여 주고, 누르면 타이머 화면으로 간다

#### Config
- `REALTIME_BACKEND` 환경변수 (배포 시 GitHub vars에서 `.env`로 전달)

### Removed

#### Timer WebSocket
- WebSocket 명령(`timer.create`·`pause`·`resume`·`stop`·`sync`)과 `timer.sync_result`·`timer.friend_activity` 처리
- 소켓 연결의 `timezone` 쿼리

### Fixed

#### Timer WebSocket
- 소켓이 다시 연결되면 연결 오류 배너를 지운다
- 관계 필드를 채우는 `GET /v1/timers/{id}`가 실패하면 2·4·8초 뒤 다시 받는다. 그 사이 다른 REST 응답으로 채워졌거나 지워진 타이머는 다시 받지 않는다

#### Todo
- 누적 집중 시간의 타이머 목록 조회(`GET /v1/timers`)도 타이머 REST 요청으로 보내 `timezone=UTC`를 붙이고 응답의 `Date` 헤더로 서버 시각을 맞춘다

#### Auth
- 기존 계정에 Google을 연결하는 로그인(`/login?flow=`)도 계정이 이메일 인증 전이면 서버가 다시 보낸 코드로 인증 화면을 연다. 인증 화면에는 연결할 계정 이메일을 넘긴다

---

## [v2026.06.24-079c3c0] - 2026-06-24

### Changed

#### Auth
- 인증을 Supabase에서 Ory Kratos로 이전 (backend `/auth` 프록시를 거친 API 플로우, 쿠키 없음)
  - Kratos 세션 토큰은 SharedPreferences(웹은 localStorage)에 두고, 앱 상태에는 백엔드용 JWT(10분)만 둔다
  - JWT는 요청 직전에 만료가 가까우면 새로 받고, 401이면 한 번 새로 받아 재시도한다
  - WebSocket은 (재)연결할 때마다 최신 JWT를 쓰고, JWT 갱신만으로는 다시 연결하지 않는다
  - 비밀번호 변경도 메일로 받은 코드로 한다(비밀번호 재설정 화면). 현재 비밀번호만으로는 바꿀 수 없어서,
    비밀번호가 새도 메일 확인 없이 비밀번호를 바꿔 계정을 차지하지 못한다
  - 이메일 인증 전에는 로그인할 수 없다. 가입하면 인증 화면으로, 인증을 마치면 로그인 화면으로 간다.
    인증 전 로그인 시도는 서버가 다시 보낸 코드로 인증 화면을 연다
  - 가입 비밀번호 최소 길이를 Kratos 정책인 8자로 맞춤

#### Todo & Schedule Mutations
- Todo·Schedule CUD 흐름을 Riverpod `Mutation` API 기반 command 패턴으로 전환
  - 기존 mutation notifier의 `AsyncValue` 로딩/성공/실패 상태 관리를 제거하고, REST 호출 및 관련 provider invalidation 책임만 유지
  - `mutation.run(..., (tsx) => tsx.get(...notifier).xxx())` 호출 패턴으로 통일해 작업 중 provider 생존과 완료 후 캐시 갱신을 보장
  - Todo 생성/수정/삭제/상태변경/부모변경, Schedule 생성/수정/삭제/이동/리사이즈/TODO 변환 호출부를 새 패턴으로 전환
- Todo 삭제 실패 처리를 bool 반환 대신 원래 예외를 전파하는 방식으로 통일

### Added

#### Auth
- 이메일 인증 화면(`/verification`)과 인증 오류 화면(`/auth-error`)
- 코드 기반 비밀번호 재설정 (이메일 → 6자리 코드 → 새 비밀번호)
- 웹 Google 로그인 ("Google로 계속하기", 로그인·회원가입 화면)
  - 서버(Kratos)가 Google을 켰을 때만 버튼이 보인다
  - Google을 다녀온 브라우저는 로그인 화면(`/login?code=`)으로 돌아오고, 로그인 화면이 세션 토큰 교환으로 로그인을 마친다
  - 로그인 뒤 원래 화면으로 가는 처리는 비밀번호 로그인과 같은 `redirect` 검사를 탄다
  - 이 브라우저에서 시작하지 않은 복귀 링크는 교환하지 않고 보안 경고 화면으로 보낸다
  - Google 이메일로 이미 가입된 계정이 있으면 로그인 화면(`/login?flow=`)이 그 계정 이메일을 고정해 비밀번호를 받고, 로그인하면서 Google을 계정에 연결한다
    (같은 이메일의 Google만 연결되므로 비밀번호가 새도 남의 Google을 붙일 수 없다)

#### Security
- 메일 인증 링크(`/verification?flow=`)와 Google 복귀 링크(`/login?code=`)의 값이 올바른 모양이 아니면 보안 경고 화면으로 보낸다

#### Tests
- Todo·Schedule mutation 도메인별 테스트 추가
  - CUD REST API 호출 검증
  - provider invalidation 후 재조회 검증
  - `Mutation` 성공/실패 상태 및 원래 예외 전파 검증

### Removed

#### Auth
- `supabase`, `supabase_flutter` 의존성과 `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` 설정

#### Tests
- ref.mounted 가드 기반 공용 dispose 안전성 테스트 제거
  - Mutation 기반 도메인 테스트로 검증 범위 대체

---

## [v2026.06.16-ad57845] - 2026-06-16

### Changed

#### Timer WebSocket
- 백엔드 Timer WebSocket 스펙 재검토 반영
  - `timer.friend_activity` payload에 `display_name`(nullable) 필드 추가
  - `timer.updated` payload의 `timer`를 nullable로 변경 — `timer.sync` 단건 조회 대상이 없으면 `null`이 올 수 있어, 수신 처리에 null guard 추가(활성 타이머 없음으로 처리)
  - 백엔드 공식 메시지 타입이 아닌 `timer.completed` / `timer.synced` fallback 처리 제거

---

## [v2026.04.04-bedf04d] - 2026-04-04

### Fixed

#### Core Infrastructure
- PATCH 요청에서 null 필드가 직렬화되어 백엔드가 의도치 않게 필드를 초기화하는 버그 수정 (#29, #32, #33, #34)
  - `build.yaml`에 `include_if_null: false` 설정 추가
  - `ExplicitNullInterceptor` 도입으로 명시적 null 전송 지원
  - `explicitNulls()` 헬퍼 함수로 호출부 간소화
- Todo 수정 시 `parent_id` 보존하여 트리 관계 유지
- Todo, Schedule, TagGroup 수정 폼에서 description 비우기 반영

#### Landing & Loading
- landing → 앱 전환 시 로딩 화면 탈출 불가 버그 수정
- 랜딩 페이지 앵커 클릭 시 경로 전환 버그 수정
- 모바일 가로 스크롤 및 배경 blob 잘림 수정
- Flutter 부트스트랩 `hostElement` 무시 및 아이콘 폰트 깨짐 수정
- 인증 유저 루트 진입 시 랜딩 대신 앱으로 직행하도록 수정

#### API
- API 모델에서 제거된 `isTodoGroup` 필드 참조 제거

### Added

#### Landing & Loading
- Flutter 로딩 중 표시할 정적 랜딩 페이지 추가 (`web/landing/`)
- 랜딩/로딩 페이지 분리 및 Flutter 부트스트랩 개선
- 생산성 아이콘 SVG 순환 애니메이션 로딩 화면
- 시뮬레이션 프로그레스 바 추가
- 앱 아이콘/프리뷰 이미지 및 noscript 대응
- 미인증 루트 접근 시 `/landing` 리다이렉트

#### API
- `openapi.json` 기반 REST 클라이언트 재생성
- `VisibilityLevel`, `VisibilityRead`, `VisibilityUpdate`, `ResourceType` 등 신규 모델 추가
- `MeetingCreate`, `MeetingUpdate` 등 미팅 관련 모델 추가

#### Core Infrastructure
- Flutter project setup with FVM (stable channel)
- Feature-first + Shared layer architecture
- GoRouter routing configuration
- Riverpod 3.x state management with code generation
- Dio + Retrofit HTTP client layer
- Supabase authentication integration
- Hive + SharedPreferences local storage

#### API Layer
- Retrofit API clients for all backend endpoints
  - Schedules, Todos, Timers, Tags, Friends, Holidays, Health, GraphQL
- Freezed data models with JSON serialization
  - ScheduleRead/Create/Update, TodoRead/Create/Update, TimerRead/Update
  - TagRead/Create/Update, TagGroupRead/Create/Update
  - FriendRead, FriendshipRead, PendingRequestRead
  - VisibilitySettings, HolidayItem, ValidationError

#### Features
- **Auth**: Supabase login/signup flow
- **Calendar**: Syncfusion-based calendar with schedule management
  - Calendar state management (Freezed)
  - Schedule mutations provider
  - Holiday provider integration
- **Todo**: Todo list with tag integration
  - Timer providers for todo-linked timers
  - Tag providers for todo tagging
- **Timer**: Timer management with schedule/todo linking
- **Tag**: Tag and tag group management
- **Home**: Home screen

#### Shared Components
- `AppScaffold` — common scaffold widget
- `ScaffoldWithNav` — navigation scaffold
- Shared API providers
- App configuration (`app_config.dart`)

---

## Version History Format

### Types of Changes

- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security vulnerability fixes

---

[Unreleased]: https://github.com/onprem-hipster-timer/frontend/compare/v2026.06.24-079c3c0...HEAD
[v2026.06.24-079c3c0]: https://github.com/onprem-hipster-timer/frontend/compare/v2026.06.16-ad57845...v2026.06.24-079c3c0
[v2026.06.16-ad57845]: https://github.com/onprem-hipster-timer/frontend/compare/v2026.04.04-bedf04d...v2026.06.16-ad57845
[v2026.04.04-bedf04d]: https://github.com/onprem-hipster-timer/frontend/compare/main...v2026.04.04-bedf04d
