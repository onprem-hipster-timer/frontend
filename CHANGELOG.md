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

#### Timer WebSocket
- 소켓을 수신 전용으로 바꿈. 클라이언트는 45초마다 `ping`만 보낸다
- 소켓 주소를 `REALTIME_BACKEND`(`inprocess`: `/v1/ws/timers`, `cloudflare`: `/realtime/ws`)로 고른다
- 서버 메시지를 이벤트 봉투(`id`·`type`·`from_user`·`timestamp`·`payload`)로 받는다
  - 같은 `id`는 한 번만 반영하고, `updated_at`이 가진 값보다 이전인 타이머는 버린다 (REST 응답에도 같은 규칙)
  - `timer.deleted`를 받은 타이머는 이후 이벤트로 되살리지 않는다
  - (재)연결마다 REST로 활성 타이머를 다시 맞춘다
- 닫힘 코드별 재연결: `1008`은 JWT를 한 번 새로 받아 다시 연결하고 또 거부되면 멈춘다, `4000`은 바로,
  그 외는 지수 백오프(1s부터 두 배, 상한 30s)와 지터로 횟수 제한 없이 다시 연결한다
- 앱이 포그라운드로 돌아오면 끊긴 소켓을 바로 다시 연결한다
- 친구 알림은 `from_user`가 내가 아닌 이벤트의 `actor_name`·`action`으로 띄운다

#### API
- OpenAPI 스펙 v2026.11.06-039b759 반영 및 API 클라이언트 재생성

### Added

#### Config
- `REALTIME_BACKEND` 환경변수 (배포 시 GitHub vars에서 `.env`로 전달)

### Removed

#### Timer WebSocket
- WebSocket 명령(`timer.create`·`pause`·`resume`·`stop`·`sync`)과 `timer.sync_result`·`timer.friend_activity` 처리
- 소켓 연결의 `timezone` 쿼리

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
