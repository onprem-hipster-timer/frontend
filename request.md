# Flutter 앱 개발 의뢰서

> 작성일: 2026-01-28  
> 프로젝트: momomeet (일정 관리 서비스)  
> 현재 스택: React 19 + TypeScript + Vite + Zustand

---

## 📋 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [현재 시스템 분석](#2-현재-시스템-분석)
3. [Flutter 전환 목표](#3-flutter-전환-목표)
4. [기술 스택 요구사항](#4-기술-스택-요구사항)
5. [아키텍처 설계](#5-아키텍처-설계)
6. [기능별 요구사항](#6-기능별-요구사항)
7. [API 연동](#7-api-연동)
8. [마일스톤 및 일정](#8-마일스톤-및-일정)
9. [참고 자료](#9-참고-자료)

---

## 1. 프로젝트 개요

### 1.1 서비스 소개

**momomeet**은 일정 관리, 할 일 관리, 타이머 기능을 제공하는 생산성 서비스입니다.

### 1.2 전환 배경

| 항목 | 현재 | 목표 |
|------|------|------|
| 플랫폼 | 웹 전용 | iOS, Android, 웹 |
| 기술 | React (SPA) | Flutter (크로스 플랫폼) |
| 배포 | Vercel | App Store, Play Store, 웹 |

### 1.3 프로젝트 범위

- **Phase 1**: 핵심 기능 (인증, 일정, 할 일)
- **Phase 2**: 부가 기능 (타이머, 태그 관리)
- **Phase 3**: 고급 기능 (알림, 위젯, 오프라인 지원)

---

## 2. 현재 시스템 분석

### 2.1 코드베이스 규모

| 항목 | 수량 |
|------|------|
| TSX 파일 | 242개 |
| TS 파일 | 115개 |
| 컴포넌트 (shadcn/ui) | 82개 |
| 페이지 | 15개 |
| 상태 스토어 (Zustand) | 9개 |

### 2.2 핵심 기능

```
momomeet
├── 🔐 인증 (Supabase Auth)
│   ├── 이메일/비밀번호 로그인
│   ├── 소셜 로그인 (계획)
│   └── 비밀번호 재설정
│
├── 📅 일정 관리 (Calendar)
│   ├── 4가지 뷰 (일/주/월/연)
│   ├── 아젠다 뷰
│   ├── 드래그 앤 드롭 (날짜/시간 변경)
│   ├── 리사이즈 (이벤트 시간 조절)
│   ├── 반복 일정 (RRule)
│   ├── 다중일 이벤트
│   ├── 공휴일 표시
│   └── 태그 기반 필터링
│
├── ✅ 할 일 관리 (Todo)
│   ├── 계층형 트리 구조 (parent_id)
│   ├── 드래그 앤 드롭 (부모 변경)
│   ├── 상태 관리 (미예정/예정/완료/취소)
│   ├── 태그 연동
│   └── 검색/필터링
│
├── ⏱️ 타이머
│   ├── 일정 연동 타이머
│   ├── 시작/일시정지/종료
│   └── 히스토리 조회
│
├── 🏷️ 태그 관리
│   ├── 태그 그룹
│   ├── 태그 CRUD
│   └── 색상 커스터마이징
│
└── 👤 마이페이지
    ├── 프로필 설정
    ├── 타임존 설정
    └── 통계 조회
```

### 2.3 현재 상태관리 구조

```
현재 Zustand 스토어:
├── calendarStore.ts (776줄) - 일정 + 필터 + 뷰 설정
├── todoStore.ts (328줄) - Todo CRUD
├── tagStore.ts (356줄) - 태그 CRUD
├── timerStore.ts (~300줄) - 타이머 관리
├── holidayStore.ts (~150줄) - 공휴일 캐시
├── userSettingsStore.ts (~50줄) - 사용자 설정
├── authModalStore.ts (~20줄) - 모달 상태
├── demoAdapterStore.ts (~25줄) - 데모용
└── enterpriseStore.ts (~20줄) - 기업 폼
```

### 2.4 API 구조

- **백엔드**: FastAPI (Python)
- **문서**: OpenAPI 3.0 스펙 제공 (`openapi/openapi.json`)
- **인증**: Supabase JWT

```
API 엔드포인트:
├── /v1/schedules - 일정 CRUD
├── /v1/todos - 할 일 CRUD
├── /v1/tags - 태그 CRUD
├── /v1/tag-groups - 태그 그룹 CRUD
├── /v1/timers - 타이머 CRUD
└── /v1/holidays - 공휴일 조회
```

---

## 3. Flutter 전환 목표

### 3.1 필수 요구사항

| 요구사항 | 우선순위 | 설명 |
|----------|---------|------|
| 크로스 플랫폼 | 🔴 필수 | iOS, Android 동시 지원 |
| 기존 API 호환 | 🔴 필수 | 백엔드 변경 없이 연동 |
| 오프라인 지원 | 🟡 권장 | 로컬 캐시 + 동기화 |
| 네이티브 UX | 🔴 필수 | 플랫폼별 가이드라인 준수 |
| 푸시 알림 | 🟡 권장 | 일정 리마인더 |

### 3.2 성능 목표

| 지표 | 목표값 |
|------|--------|
| 앱 시작 시간 (Cold) | < 2초 |
| 화면 전환 | < 300ms |
| 캘린더 렌더링 (100개 이벤트) | < 500ms |
| 메모리 사용량 (피크) | < 150MB |

---

## 4. 기술 스택 요구사항

### 4.1 필수 패키지

```yaml
# pubspec.yaml

dependencies:
  flutter:
    sdk: flutter

  # 상태 관리 (Riverpod + 코드젠)
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # HTTP 클라이언트 (OpenAPI 생성 코드에서 사용)
  dio: ^5.4.0

  # 라우팅
  go_router: ^14.0.0

  # 로컬 저장소
  shared_preferences: ^2.2.0
  hive: ^2.2.0
  hive_flutter: ^1.1.0

  # 인증
  supabase_flutter: ^2.5.0

  # UI 유틸리티
  flutter_animate: ^4.5.0
  intl: ^0.19.0

  # 캘린더
  syncfusion_flutter_calendar: ^25.1.0  # 또는 table_calendar

dev_dependencies:
  flutter_test:
    sdk: flutter

  # 코드젠 (Riverpod)
  build_runner: ^2.4.0
  riverpod_generator: ^2.4.0

  # OpenAPI 코드 자동 생성 (API 모델 + API 클라이언트)
  openapi_generator_cli: ^5.0.0

  # UI 로컬 상태용 Freezed (CalendarSettingsState 등)
  freezed: ^2.4.0
  freezed_annotation: ^2.4.0

  # 테스트
  mocktail: ^1.0.0
```

> 💡 **패키지 역할 정리**:  
> - `openapi_generator_cli`: API 모델 (ScheduleRead 등) + API 클라이언트 자동 생성
> - `freezed`: UI 로컬 상태 모델 (CalendarSettingsState 등) 수동 작성용
> - `riverpod_generator`: Provider 코드젠

### 4.2 Flutter 버전

```bash
# fvm 사용 권장
fvm use stable  # 또는 특정 버전 (예: 3.22.x)
```

> 📎 FVM 설정 가이드: [docs/fvm-guide.md](https://jeje.work/flutter----fvm)

---

## 5. 아키텍처 설계

### 5.1 폴더 구조

```
lib/
├── main.dart
├── app.dart
│
├── core/                          # 공통 레이어
│   ├── config/
│   │   ├── app_config.dart
│   │   └── env.dart
│   ├── constants/
│   │   └── colors.dart
│   ├── error/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/
│   │   ├── dio_client.dart        # Dio 인스턴스 + 인터셉터
│   │   └── api_providers.dart     # API Provider 정의
│   ├── router/
│   │   └── app_router.dart
│   └── utils/
│       ├── date_utils.dart
│       └── extensions.dart
│
├── shared/                        # 공유 레이어
│   │
│   ├── api/                       # ⚠️ OpenAPI 자동 생성 영역
│   │   └── generated/             # 🔄 `dart run openapi_generator_cli`로 생성
│   │       ├── lib/
│   │       │   ├── api.dart       # 진입점
│   │       │   ├── api/           # API 클라이언트 (SchedulesApi, TodosApi 등)
│   │       │   └── model/         # 모델 클래스 (ScheduleRead, TodoRead 등)
│   │       └── pubspec.yaml
│   │
│   ├── widgets/                   # 공유 위젯
│   │   ├── app_button.dart
│   │   ├── app_text_field.dart
│   │   └── loading_overlay.dart
│   │
│   └── providers/                 # 공유 Provider
│       ├── dio_provider.dart      # Dio 인스턴스
│       └── api_providers.dart     # API 클라이언트 Provider
│
├── features/                      # 기능별 모듈
│   │
│   ├── auth/
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── login_page.dart
│   │   │   │   └── signup_page.dart
│   │   │   ├── widgets/
│   │   │   └── providers/
│   │   │       └── auth_provider.dart
│   │   └── auth.dart              # barrel export
│   │
│   ├── calendar/
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── calendar_page.dart
│   │   │   │   └── schedule_detail_page.dart
│   │   │   ├── widgets/
│   │   │   │   ├── calendar_body.dart
│   │   │   │   ├── calendar_month_view.dart
│   │   │   │   ├── calendar_week_view.dart
│   │   │   │   ├── draggable_event.dart
│   │   │   │   └── resizable_event.dart
│   │   │   ├── providers/
│   │   │   │   ├── calendar_provider.dart      # 일정 데이터 Provider
│   │   │   │   ├── calendar_settings.dart      # UI 설정 상태
│   │   │   │   └── calendar_filter.dart        # 필터 상태
│   │   │   └── state/
│   │   │       └── calendar_state.dart         # Freezed UI 상태 모델
│   │   └── calendar.dart
│   │
│   ├── todo/
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   └── todo_list_page.dart
│   │   │   ├── widgets/
│   │   │   │   ├── todo_tree.dart
│   │   │   │   └── todo_tree_item.dart
│   │   │   ├── providers/
│   │   │   │   ├── todo_provider.dart
│   │   │   │   └── todo_filter.dart
│   │   │   └── utils/
│   │   │       └── todo_tree_builder.dart      # 트리 구조 유틸 (TS에서 포팅)
│   │   └── todo.dart
│   │
│   ├── timer/
│   ├── tag/
│   └── settings/
│
└── openapi/                       # OpenAPI 스펙 (원본)
    └── openapi.json               # 백엔드에서 복사
```

> 💡 **폴더 구조 특징**:
> - `shared/api/generated/`: OpenAPI 자동 생성 → **직접 수정 금지**
> - `features/*/presentation/state/`: UI 로컬 상태 → Freezed로 수동 작성
> - `features/*/presentation/providers/`: Riverpod Provider

### 5.2 상태 관리 (Riverpod)

#### 5.2.1 Provider 구조

> ⚠️ **OpenAPI 자동 생성 사용 시**: 모델 클래스와 API 클라이언트는 자동 생성됩니다.  
> Provider에서는 **생성된 API 클라이언트**를 사용합니다.

```dart
// ============================================================
// 1. API 클라이언트 Provider (OpenAPI 생성 코드 사용)
// ============================================================

// OpenAPI 생성된 API 인스턴스를 제공
@riverpod
SchedulesApi schedulesApi(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return SchedulesApi(dio);  // OpenAPI 생성된 클래스
}

@riverpod
TodosApi todosApi(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return TodosApi(dio);  // OpenAPI 생성된 클래스
}

// ============================================================
// 2. Data Provider (비동기 데이터 조회)
// ============================================================

@riverpod
Future<List<ScheduleRead>> schedules(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final api = ref.watch(schedulesApiProvider);
  // OpenAPI 생성된 메서드 호출
  final response = await api.readSchedulesV1SchedulesGet(
    startDate: startDate.toIso8601String(),
    endDate: endDate.toIso8601String(),
  );
  return response.data ?? [];
}

@riverpod
Future<List<TodoRead>> todos(Ref ref, {String? groupId}) async {
  final api = ref.watch(todosApiProvider);
  final response = await api.readTodosV1TodosGet(groupId: groupId);
  return response.data ?? [];
}

// ============================================================
// 3. State Provider (로컬 UI 상태)
// ============================================================

@riverpod
class CalendarSettings extends _$CalendarSettings {
  @override
  CalendarSettingsState build() => CalendarSettingsState.initial();
  
  void setView(CalendarView view) {
    state = state.copyWith(view: view);
  }
  
  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }
}

// ============================================================
// 4. Computed Provider (파생 상태 - 필터링)
// ============================================================

@riverpod
List<ScheduleRead> filteredSchedules(Ref ref) {
  // ScheduleRead는 OpenAPI 자동 생성된 모델
  final schedules = ref.watch(schedulesProvider).valueOrNull ?? [];
  final filter = ref.watch(calendarFilterProvider);
  
  return schedules.where((s) {
    if (filter.tagIds.isEmpty) return true;
    return s.tags?.any((t) => filter.tagIds.contains(t.id)) ?? false;
  }).toList();
}

// ============================================================
// 5. Mutation Provider (생성/수정/삭제)
// ============================================================

@riverpod
class ScheduleMutations extends _$ScheduleMutations {
  @override
  FutureOr<void> build() {}
  
  Future<ScheduleRead> create(ScheduleCreate data) async {
    final api = ref.read(schedulesApiProvider);
    final response = await api.createScheduleV1SchedulesPost(scheduleCreate: data);
    ref.invalidate(schedulesProvider);  // 목록 자동 리페치
    return response.data!;
  }
  
  Future<ScheduleRead> update(String id, ScheduleUpdate data) async {
    final api = ref.read(schedulesApiProvider);
    final response = await api.updateScheduleV1SchedulesScheduleIdPut(
      scheduleId: id,
      scheduleUpdate: data,
    );
    ref.invalidate(schedulesProvider);
    return response.data!;
  }
  
  Future<void> delete(String id) async {
    final api = ref.read(schedulesApiProvider);
    await api.deleteScheduleV1SchedulesScheduleIdDelete(scheduleId: id);
    ref.invalidate(schedulesProvider);
  }
}
```

#### 5.2.2 현재 스토어 → Riverpod 매핑

| Zustand Store | Riverpod Providers |
|---------------|-------------------|
| `calendarStore` | `schedulesProvider` + `calendarSettingsProvider` + `calendarFilterProvider` |
| `todoStore` | `todosProvider` + `todoMutationsProvider` |
| `tagStore` | `tagGroupsProvider` + `tagMutationsProvider` |
| `timerStore` | `timersProvider` + `activeTimerProvider` + `timerMutationsProvider` |
| `holidayStore` | `holidaysProvider(year)` (Family Provider) |
| `userSettingsStore` | `userSettingsProvider` |
| `authModalStore` | `authModalProvider` (StateProvider) |

### 5.3 데이터 모델

> ✅ **OpenAPI 자동 생성**: 모델 클래스는 수동으로 작성하지 않습니다.  
> `openapi/openapi.json`에서 자동 생성됩니다.

#### 5.3.1 자동 생성되는 모델 (OpenAPI → Dart)

```bash
# 코드 생성 명령
fvm dart run swagger_parser
```

생성 결과:

```
lib/shared/api/rest/generated/
├── lib/
│   ├── api.dart                      # 진입점
│   │
│   ├── api/                          # API 클라이언트 클래스
│   │   ├── schedules_api.dart        # SchedulesApi
│   │   ├── todos_api.dart            # TodosApi
│   │   ├── tags_api.dart             # TagsApi
│   │   ├── tag_groups_api.dart       # TagGroupsApi
│   │   ├── timers_api.dart           # TimersApi
│   │   └── holidays_api.dart         # HolidaysApi
│   │
│   └── model/                        # 모델 클래스 (자동 생성)
│       ├── schedule_read.dart        # ScheduleRead
│       ├── schedule_create.dart      # ScheduleCreate
│       ├── schedule_update.dart      # ScheduleUpdate
│       ├── todo_read.dart            # TodoRead
│       ├── todo_create.dart          # TodoCreate
│       ├── todo_update.dart          # TodoUpdate
│       ├── todo_status.dart          # TodoStatus (enum)
│       ├── tag_read.dart             # TagRead
│       ├── tag_group_read.dart       # TagGroupRead
│       ├── timer_read.dart           # TimerRead
│       ├── holiday_item.dart         # HolidayItem
│       └── ...
```

#### 5.3.2 자동 생성 모델 예시

```dart
// ⚠️ 이 코드는 참고용입니다. 직접 작성하지 마세요!
// OpenAPI 생성기가 자동으로 만들어줍니다.

// lib/shared/api/rest/generated/lib/model/schedule_read.dart (자동 생성)
class ScheduleRead {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? recurrenceRule;
  final DateTime? recurrenceEnd;
  final String? parentId;
  final String? tagGroupId;
  final List<TagRead>? tags;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // fromJson, toJson, copyWith 등 자동 생성
}
```

#### 5.3.3 자동 생성되는 모델 목록

| OpenAPI 스키마 | 생성되는 Dart 클래스 | 용도 |
|---------------|---------------------|------|
| `ScheduleRead` | `ScheduleRead` | 일정 조회 응답 |
| `ScheduleCreate` | `ScheduleCreate` | 일정 생성 요청 |
| `ScheduleUpdate` | `ScheduleUpdate` | 일정 수정 요청 |
| `TodoRead` | `TodoRead` | 할일 조회 응답 |
| `TodoCreate` | `TodoCreate` | 할일 생성 요청 |
| `TodoStatus` | `TodoStatus` (enum) | 상태값 (UNSCHEDULED, SCHEDULED, DONE, CANCELLED) |
| `TagRead` | `TagRead` | 태그 조회 |
| `TagGroupReadWithTags` | `TagGroupReadWithTags` | 태그 그룹 + 하위 태그 |
| `TimerRead` | `TimerRead` | 타이머 조회 |
| `HolidayItem` | `HolidayItem` | 공휴일 정보 |

#### 5.3.4 로컬 UI 상태 모델 (수동 작성 필요)

> API 모델은 자동 생성되지만, **UI 전용 상태**는 직접 작성합니다.

```dart
// lib/features/calendar/presentation/providers/calendar_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_state.freezed.dart';

/// 캘린더 뷰 타입
enum CalendarView { day, week, month, year, agenda }

/// 캘린더 UI 설정 상태 (로컬)
@freezed
class CalendarSettingsState with _$CalendarSettingsState {
  const factory CalendarSettingsState({
    @Default(CalendarView.month) CalendarView view,
    required DateTime selectedDate,
    @Default(true) bool use24HourFormat,
    @Default('colored') String badgeVariant,
  }) = _CalendarSettingsState;
  
  factory CalendarSettingsState.initial() => CalendarSettingsState(
    selectedDate: DateTime.now(),
  );
}

/// 캘린더 필터 상태 (로컬)
@freezed
class CalendarFilterState with _$CalendarFilterState {
  const factory CalendarFilterState({
    @Default([]) List<String> tagIds,
    @Default('all') String selectedUserId,
  }) = _CalendarFilterState;
}
```

> 💡 **정리**:  
> - **API 모델** (ScheduleRead, TodoRead 등): OpenAPI 자동 생성 ✅  
> - **UI 상태 모델** (CalendarSettingsState 등): Freezed로 수동 작성 ✅

---

## 6. 기능별 요구사항

### 6.1 인증 (Auth)

#### 화면
- [ ] 로그인 페이지 (`/login`)
- [ ] 회원가입 페이지 (`/signup`)
- [ ] 비밀번호 재설정 페이지 (`/forgot-password`)
- [ ] 비밀번호 변경 페이지 (`/update-password`)

#### 기능
- [ ] Supabase Auth 연동
- [ ] JWT 토큰 저장 (secure_storage)
- [ ] 자동 로그인 (토큰 갱신)
- [ ] 로그아웃 시 상태 초기화

#### 참고 코드
```
React 파일:
- src/components/SupabaseAuthProvider.tsx
- src/components/login-form.tsx
- src/components/sign-up-form.tsx
- src/lib/authEvents.ts
```

---

### 6.2 캘린더 (Calendar)

#### 화면
- [ ] 캘린더 메인 (`/` 또는 `/calendar`)
- [ ] 일정 상세 (`/schedule/detail?id=xxx`)
- [ ] 일정 생성/수정 다이얼로그

#### 뷰 모드
- [ ] 일간 뷰 (Day View)
- [ ] 주간 뷰 (Week View)
- [ ] 월간 뷰 (Month View)
- [ ] 연간 뷰 (Year View)
- [ ] 아젠다 뷰 (Agenda View)

#### 핵심 기능
- [ ] 드래그 앤 드롭 (일정 날짜/시간 변경)
- [ ] 리사이즈 (일정 시간 조절)
- [ ] 다중일 이벤트 표시
- [ ] 반복 일정 (RRule) 지원
- [ ] 가상 인스턴스 처리 (반복 일정의 개별 인스턴스)
- [ ] 공휴일 표시
- [ ] 태그 기반 필터링

#### 복잡도 높은 구현
```
React 파일 (참고):
- src/components/NewScheduleCalendar/calendar-week-view.tsx (235줄)
- src/components/NewScheduleCalendar/dnd-context.tsx (243줄)
- src/components/NewScheduleCalendar/resizable-event.tsx (152줄)
- src/components/NewScheduleCalendar/interfaces.ts (변환 유틸)
- src/stores/calendarStore.ts (776줄)
```

#### 드래그 앤 드롭 로직
```dart
// Flutter 구현 가이드

class DraggableEvent extends StatelessWidget {
  final Schedule event;
  
  @override
  Widget build(BuildContext context) {
    return Draggable<Schedule>(
      data: event,
      feedback: EventCard(event: event, isDragging: true),
      childWhenDragging: EventCard(event: event, opacity: 0.5),
      child: EventCard(event: event),
    );
  }
}

class DroppableTimeSlot extends ConsumerWidget {
  final DateTime date;
  final int hour;
  final int minute;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<Schedule>(
      onAcceptWithDetails: (details) {
        final event = details.data;
        final newStart = DateTime(date.year, date.month, date.day, hour, minute);
        ref.read(scheduleMutationsProvider.notifier).moveEvent(event, newStart);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          color: candidateData.isNotEmpty ? Colors.blue.withOpacity(0.2) : null,
          // ...
        );
      },
    );
  }
}
```

---

### 6.3 할 일 (Todo)

#### 화면
- [ ] 할 일 목록 (`/todo`)
- [ ] 할 일 상세/수정 다이얼로그

#### 핵심 기능
- [ ] 계층형 트리 구조 렌더링
- [ ] 드래그 앤 드롭 (부모 변경)
- [ ] 상태 변경 (미예정 → 예정 → 완료 → 취소)
- [ ] 확장/축소 상태 관리
- [ ] 검색/필터링
- [ ] 태그 연동
- [ ] 일정 연결 (데드라인)

#### 트리 구조 로직
```dart
// 기존 TypeScript 로직을 Dart로 포팅

class TodoTreeNode {
  final String id;
  final Todo todo;
  final int depth;
  final List<String> childrenIds;
  final List<String> pathIds;
  
  bool get hasChildren => childrenIds.isNotEmpty;
}

class TodoTree {
  final List<String> rootIds;
  final Map<String, TodoTreeNode> nodes;
  final List<String> flatOrder;
}

TodoTree buildTodoTree(List<Todo> todos) {
  // cycle/orphan 감지 로직 포함
  // src/shared/utils/todoTree.ts 참고
}
```

#### 참고 코드
```
React 파일:
- src/pages/TodoList/components/TodoTree.tsx (583줄)
- src/pages/TodoList/components/TodoTreeItem/index.tsx
- src/shared/utils/todoTree.ts (329줄)
- src/stores/todoStore.ts (328줄)
```

---

### 6.4 타이머 (Timer)

#### 화면
- [ ] 타이머 목록 (`/timer`)
- [ ] 타이머 상세 (`/timer/detail?id=xxx`)
- [ ] 활성 타이머 인디케이터 (캘린더 위)

#### 기능
- [ ] 타이머 생성 (일정/할일 연동)
- [ ] 시작/일시정지/종료
- [ ] 실시간 경과 시간 표시
- [ ] 히스토리 조회

#### 참고 코드
```
React 파일:
- src/components/Timer/
- src/stores/timerStore.ts
```

---

### 6.5 태그 관리 (Tag)

#### 화면
- [ ] 태그 관리 페이지 (`/tag`)
- [ ] 태그 생성/수정 다이얼로그

#### 기능
- [ ] 태그 그룹 CRUD
- [ ] 태그 CRUD
- [ ] 색상 선택

#### 참고 코드
```
React 파일:
- src/pages/TagManagement/index.tsx
- src/components/Tag/
- src/stores/tagStore.ts
```

---

### 6.6 마이페이지 (Settings)

#### 화면
- [ ] 마이페이지 (`/mypage`)

#### 기능
- [ ] 프로필 조회
- [ ] 타임존 설정
- [ ] 통계 조회 (태그별, 활동별)

---

## 7. API 연동

### 7.1 OpenAPI 코드 자동 생성

현재 프로젝트에 `openapi/openapi.json` 스펙이 있으므로, Dart 클라이언트 코드를 자동 생성할 수 있습니다.

#### 추천 도구: `openapi_generator_cli`

```yaml
# pubspec.yaml

dev_dependencies:
  openapi_generator_cli: ^5.0.0
  openapi_generator_annotations: ^5.0.0
```

```bash
# 설치 후 코드 생성
dart run openapi_generator_cli generate \
  -i openapi/openapi.json \
  -g dart-dio \
  -o lib/shared/api/rest/generated
```

#### 사용 가능한 OpenAPI 생성 도구

| 도구 | 특징 | 추천도 |
|------|------|--------|
| **openapi_generator_cli** | 공식 openapi-generator의 Dart 래퍼, 안정적 | ⭐⭐⭐⭐⭐ |
| **openapi_freezed_dio_builder** | Freezed + Dio 조합, 타입 안전 | ⭐⭐⭐⭐⭐ |
| **swagger_dart_code_generator** | 간단한 설정, 빠른 시작 | ⭐⭐⭐⭐ |
| **swagger_parser** | REST 클라이언트 + 데이터클래스 생성 | ⭐⭐⭐⭐ |

#### 권장: `openapi_freezed_dio_builder`

Riverpod + Freezed 조합을 사용하므로 이 도구가 가장 적합합니다:

```yaml
# pubspec.yaml

dependencies:
  dio: ^5.4.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0

dev_dependencies:
  build_runner: ^2.4.0
  openapi_freezed_dio_builder: ^3.0.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
```

```yaml
# openapi_generator.yaml (프로젝트 루트에 생성)

openapi_generator:
  input_spec: openapi/openapi.json
  output_directory: lib/shared/api/rest/generated
  generator_name: dart-dio
  additional_properties:
    pubName: momomeet_api
    pubAuthor: momomeet
    useEnumExtension: true
```

```bash
# 코드 생성
dart run build_runner build --delete-conflicting-outputs
```

#### 생성되는 코드 구조

```
lib/shared/api/rest/generated/
├── lib/
│   ├── api.dart                    # 진입점
│   ├── api/
│   │   ├── schedules_api.dart      # 일정 API
│   │   ├── todos_api.dart          # 할일 API
│   │   ├── tags_api.dart           # 태그 API
│   │   ├── timers_api.dart         # 타이머 API
│   │   └── holidays_api.dart       # 공휴일 API
│   └── model/
│       ├── schedule_read.dart      # 모델 클래스
│       ├── schedule_create.dart
│       ├── todo_read.dart
│       └── ...
└── pubspec.yaml
```

#### 장점

- ✅ OpenAPI 스펙에서 **타입 안전한 Dart 코드** 자동 생성
- ✅ API 변경 시 **재생성만 하면 됨**
- ✅ 현재 React 프로젝트의 `pnpm generate-api`와 동일한 워크플로우
- ✅ Freezed와 호환되어 **불변 객체** 자동 생성

### 7.2 API 엔드포인트

| 메서드 | 경로 | 설명 |
|--------|------|------|
| GET | `/v1/schedules` | 일정 목록 조회 |
| POST | `/v1/schedules` | 일정 생성 |
| PUT | `/v1/schedules/{id}` | 일정 수정 |
| DELETE | `/v1/schedules/{id}` | 일정 삭제 |
| GET | `/v1/todos` | 할 일 목록 조회 |
| POST | `/v1/todos` | 할 일 생성 |
| PUT | `/v1/todos/{id}` | 할 일 수정 |
| DELETE | `/v1/todos/{id}` | 할 일 삭제 |
| GET | `/v1/tag-groups` | 태그 그룹 목록 조회 |
| POST | `/v1/tag-groups` | 태그 그룹 생성 |
| GET | `/v1/timers` | 타이머 목록 조회 |
| GET | `/v1/timers/active` | 활성 타이머 조회 |
| GET | `/v1/holidays/{year}` | 공휴일 조회 |

### 7.3 인증 헤더

```dart
// Dio Interceptor

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = ref.read(authTokenProvider);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }
}
```

### 7.4 에러 처리

```dart
// 공통 에러 핸들링

sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = '네트워크 연결을 확인해주세요']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = '로그인이 필요합니다']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = '서버 오류가 발생했습니다']);
}
```

---

## 8. 마일스톤 및 일정

### 8.1 예상 일정 (1인 풀타임 기준)

| Phase | 기간 | 내용 |
|-------|------|------|
| **0. 환경 구축** | 1주 | Flutter 세팅, 아키텍처, CI/CD |
| **1. 핵심 기반** | 2주 | 인증, 라우팅, API 레이어, 공통 위젯 |
| **2. 캘린더** | 3~4주 | 5가지 뷰, 드래그앤드롭, 리사이즈, 반복일정 |
| **3. 할 일** | 2~3주 | 트리 구조, 드래그앤드롭, 필터 |
| **4. 타이머** | 1~2주 | CRUD, 실시간 표시 |
| **5. 태그/설정** | 1주 | 태그 관리, 마이페이지 |
| **6. 폴리싱** | 2주 | UI 개선, 테스트, 버그 수정 |
| **총계** | **12~15주** | |

### 8.2 마일스톤

```
[M1] 환경 구축 완료
├── Flutter 프로젝트 생성
├── 폴더 구조 설정
├── 핵심 패키지 설치
└── CI/CD 파이프라인 구축

[M2] 인증 기능 완료
├── Supabase 연동
├── 로그인/회원가입 UI
├── 토큰 관리
└── 자동 로그인

[M3] 캘린더 MVP
├── 월간 뷰 구현
├── 일정 조회/생성
├── 기본 스타일링

[M4] 캘린더 완성
├── 모든 뷰 구현
├── 드래그앤드롭
├── 리사이즈
├── 반복 일정

[M5] 할 일 완성
├── 트리 구조 렌더링
├── 드래그앤드롭
├── 상태 관리
├── 필터/검색

[M6] 전체 기능 완성
├── 타이머
├── 태그 관리
├── 마이페이지

[M7] 릴리스 준비
├── 테스트 완료
├── 성능 최적화
├── 스토어 등록 준비
```

---

## 9. 참고 자료

### 9.1 현재 코드베이스

| 경로 | 설명 |
|------|------|
| `src/components/NewScheduleCalendar/` | 캘린더 컴포넌트 (53개 파일) |
| `src/pages/TodoList/` | 할 일 페이지 (27개 파일) |
| `src/stores/` | Zustand 스토어 (9개) |
| `src/shared/api/rest/` | API 클라이언트 (자동 생성) |
| `src/shared/utils/` | 유틸리티 함수 |
| `openapi/openapi.json` | OpenAPI 스펙 |

### 9.2 문서

- [FVM 설정 가이드](./fvm-guide.md)
- [기술 부채 분석](./technical-debt/README.md)

### 9.3 외부 링크

- [Riverpod 공식 문서](https://riverpod.dev)
- [Go Router 문서](https://pub.dev/packages/go_router)
- [Freezed 문서](https://pub.dev/packages/freezed)
- [Supabase Flutter 문서](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)

---

## 📝 추가 협의 사항

- [ ] 디자인 시스템 (Figma 공유 필요)
- [ ] 오프라인 지원 범위 결정
- [ ] 푸시 알림 구현 범위
- [ ] 앱 아이콘 및 스플래시 화면
- [ ] 다국어 지원 여부
- [ ] 테스트 커버리지 목표

---

*문의: [프로젝트 담당자 이메일]*
