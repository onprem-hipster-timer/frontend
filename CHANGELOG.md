# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

#### Todo & Schedule Mutations
- Todo·Schedule CUD 흐름을 Riverpod `Mutation` API 기반 command 패턴으로 전환
  - 기존 mutation notifier의 `AsyncValue` 로딩/성공/실패 상태 관리를 제거하고, REST 호출 및 관련 provider invalidation 책임만 유지
  - `mutation.run(..., (tsx) => tsx.get(...notifier).xxx())` 호출 패턴으로 통일해 작업 중 provider 생존과 완료 후 캐시 갱신을 보장
  - Todo 생성/수정/삭제/상태변경/부모변경, Schedule 생성/수정/삭제/이동/리사이즈/TODO 변환 호출부를 새 패턴으로 전환
- Todo 삭제 실패 처리를 bool 반환 대신 원래 예외를 전파하는 방식으로 통일

### Added

#### Tests
- Todo·Schedule mutation 도메인별 테스트 추가
  - CUD REST API 호출 검증
  - provider invalidation 후 재조회 검증
  - `Mutation` 성공/실패 상태 및 원래 예외 전파 검증

### Removed

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

[Unreleased]: https://github.com/onprem-hipster-timer/frontend/compare/v2026.06.16-ad57845...HEAD
[v2026.06.16-ad57845]: https://github.com/onprem-hipster-timer/frontend/compare/v2026.04.04-bedf04d...v2026.06.16-ad57845
[v2026.04.04-bedf04d]: https://github.com/onprem-hipster-timer/frontend/compare/main...v2026.04.04-bedf04d
