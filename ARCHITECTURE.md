# MoMeet - Feature-based Clean Architecture 구조

## 📁 프로젝트 구조

```
lib/
├── core/                          # 앱 전역 설정 및 기초 기능
│   ├── config/
│   │   └── app_config.dart       # 앱 전역 설정 (API URL, 타임아웃 등)
│   ├── exceptions/
│   │   └── app_exception.dart    # 사용자 정의 예외 클래스
│   ├── network/
│   │   ├── dio_provider.dart             # Dio HTTP 클라이언트 프로바이더
│   │   ├── explicit_null_interceptor.dart # PATCH 명시적 null 전송 인터셉터
│   │   └── timezone_interceptor.dart     # 타임존 헤더 인터셉터
│   └── providers/
│       └── core_providers.dart   # Core 레이어 Riverpod 프로바이더
│
├── shared/                        # 공유 자원
│   ├── api/
│   │   └── generated/            # OpenAPI Generator로 자동 생성된 API 클래스
│   ├── widgets/
│   │   └── app_scaffold.dart     # 공통 위젯
│   ├── providers/
│   │   └── shared_providers.dart # 공유 Riverpod 프로바이더
│   ├── models/                   # 공유 데이터 모델 (Freezed 사용)
│   └── shared.dart               # Shared 레이어 exports
│
├── features/                      # 기능별 모듈
│   ├── calendar/                 # 캘린더 기능
│   │   ├── domain/               # 비즈니스 로직
│   │   │   ├── entities/         # 도메인 엔티티
│   │   │   └── repositories/     # 추상 리포지토리
│   │   ├── data/                 # 데이터 접근 계층
│   │   │   ├── datasources/      # 로컬/원격 데이터 소스
│   │   │   ├── models/           # 데이터 모델 (Freezed)
│   │   │   └── repositories/     # 리포지토리 구현
│   │   └── presentation/         # UI 계층
│   │       ├── pages/            # 전체 페이지
│   │       ├── widgets/          # UI 컴포넌트
│   │       ├── providers/        # 화면 상태 관리 (Riverpod)
│   │       └── bloc/             # (선택) BLoC 패턴
│   │
│   ├── todo/                     # 할일 기능
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   └── home/                     # 홈 페이지
│       └── presentation/
│
├── app.dart                      # 앱 루트 위젯 및 테마 설정
├── router.dart                   # GoRouter 라우팅 설정
└── main.dart                     # 앱 진입점 (ProviderScope 포함)
```

## 🔧 기술 스택

| 영역 | 라이브러리 | 버전 |
|------|----------|------|
| State Management | `flutter_riverpod` | ^3.1.0 |
| Code Generation | `riverpod_generator` | ^4.0.0 |
| Model Generation | `freezed` | ^3.2.3 |
| Routing | `go_router` | ^17.0.1 |
| HTTP Client | `dio` | ^5.9.1 |
| API Generation | `openapi_generator_cli` | ^6.1.0 |
| Calendar UI | `syncfusion_flutter_calendar` | ^32.1.25 |
| Animations | `flutter_animate` | ^4.5.2 |
| Auth | `supabase_flutter` | ^2.12.0 |
| Storage | `hive`, `shared_preferences` | ^2.2.3, ^2.5.4 |

## 📋 아키텍처 원칙

### 1. Feature-based 구조
- 각 기능(Feature)은 독립적인 모듈로 구성
- Presentation → Domain → Data 계층 분리

### 2. Dependency Inversion
- 상위 계층은 하위 계층에 의존하지 않음
- 추상 인터페이스를 통한 느슨한 결합

### 3. Riverpod Code Generation 방식
```dart
@riverpod
Future<List<Schedule>> schedules(SchedulesRef ref) async {
  final repository = ref.watch(scheduleRepositoryProvider);
  return repository.getSchedules();
}
```

### 4. Freezed를 이용한 불변 모델
```dart
@freezed
class Schedule with _$Schedule {
  const factory Schedule({
    required String id,
    required String title,
    required DateTime startTime,
  }) = _Schedule;
}
```

### 5. GoRouter 라우팅
```dart
GoRoute(
  path: '/schedule/:id',
  builder: (context, state) => ScheduleDetailPage(id: state.params['id']),
)
```

## 🌐 네트워크 레이어

### PATCH 요청과 null/absent 구분

백엔드(FastAPI/Pydantic)는 `exclude_unset=True`로 JSON에 **존재하는** 필드만 "설정됨"으로 판단합니다.
Dart에는 JavaScript의 `undefined` 개념이 없어, Freezed 모델의 미설정 필드가 `null`로 직렬화되면
백엔드가 의도치 않게 해당 필드를 초기화합니다.

#### 해결 구조

```
일반 업데이트:  Retrofit + Update DTO + include_if_null: false (build.yaml)
명시적 null:   ExplicitNullInterceptor + explicitNulls() 헬퍼
```

#### `build.yaml` — null 필드 자동 제외

```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          include_if_null: false
```

`build_runner` 실행 시 `.g.dart`의 `toJson()`에서 null 필드가 자동 제외됩니다.
이 설정은 모든 Update DTO(`TodoUpdate`, `ScheduleUpdate`, `TagGroupUpdate` 등)에 적용됩니다.

#### `ExplicitNullInterceptor` — 명시적 null 전송

`include_if_null: false`로 인해 null 필드가 제외되지만, 백엔드에 명시적으로 null을 전송해야 하는 경우
(예: Todo의 부모 제거, description 비우기)에는 `ExplicitNullInterceptor`를 사용합니다.

```
lib/core/network/explicit_null_interceptor.dart
```

**동작 원리:**
1. Retrofit이 body 객체를 Dio에 전달 (아직 직렬화 전)
2. 인터셉터의 `onRequest()`에서 `toJson()`을 직접 호출 → null 필드 제외된 Map 생성
3. `RequestOptions.extra['explicit_nulls']`에 지정된 키를 null로 주입
4. `options.data`를 Map으로 교체 → Dio가 그대로 전송

**사용법:**

```dart
import 'package:momeet/core/network/explicit_null_interceptor.dart';

// 부모 제거 (parent_id를 명시적 null로 전송)
await api.updateTodoV1TodosTodoIdPatch(
  todoId: id,
  body: TodoUpdate(parentId: null),
  options: explicitNulls(['parent_id']),
);

// description 비우기
await mutations.update(
  todoId,
  TodoUpdate(title: '제목', description: null),
  options: descriptionEmpty ? explicitNulls(['description']) : null,
);
```

**적용 범위:**

| 도메인 | 사용처 | 명시적 null 필드 |
|--------|--------|-----------------|
| Todo | `changeParent()` | `parent_id` |
| Todo | 수정 폼 | `description` |
| Schedule | 수정 폼 | `description` |
| TagGroup | 수정 폼 | `description` |

#### 새로운 도메인에서의 적용

다른 뮤테이션 provider에서 동일 패턴 적용 시:

```dart
Future<void> updateEntity(
  String id,
  EntityUpdate data, {
  RequestOptions? options,
}) async {
  final api = ref.read(entityApiProvider);
  await api.updateEntityPatch(id: id, body: data, options: options);
}
```

## 🚀 사용 흐름

### 1. API 생성 (OpenAPI Generator)
```bash
fvm dart run swagger_parser
```

### 2. Feature 생성
```
features/<feature_name>/
├── domain/
│   ├── entities/
│   └── repositories/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
└── presentation/
    ├── pages/
    ├── widgets/
    └── providers/
```

### 3. 상태 관리 프로바이더 작성
```dart
// presentation/providers/schedule_provider.dart
@riverpod
Future<List<Schedule>> schedules(SchedulesRef ref) async {
  final repository = ref.watch(scheduleRepositoryProvider);
  return repository.getSchedules();
}
```

### 4. UI 페이지 작성
```dart
// presentation/pages/schedule_page.dart
class SchedulePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(schedulesProvider);
    return schedules.when(
      data: (data) => ScheduleList(schedules: data),
      loading: () => LoadingWidget(),
      error: (error, stack) => ErrorWidget(error: error),
    );
  }
}
```

## 📝 파일 작성 가이드

### Data Layer - Repository Implementation
```dart
// data/repositories/schedule_repository_impl.dart
class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleRemoteDataSource remoteDataSource;
  
  @override
  Future<List<Schedule>> getSchedules() async {
    try {
      final models = await remoteDataSource.getSchedules();
      return models.map((e) => e.toDomain()).toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
```

### Presentation Layer - Provider
```dart
// presentation/providers/schedule_provider.dart
@riverpod
class ScheduleNotifier extends _$ScheduleNotifier {
  @override
  Future<List<Schedule>> build() async {
    final repository = ref.watch(scheduleRepositoryProvider);
    return repository.getSchedules();
  }
  
  Future<void> addSchedule(Schedule schedule) async {
    // ...
  }
}
```

## ✅ 다음 단계

1. **의뢰서 문서 확인** - API 스펙 및 기능 요구사항 수신
2. **API 스펙 작성** - OpenAPI/Swagger 정의
3. **OpenAPI 코드 생성** - `openapi_generator_cli` 실행
4. **Feature 구현** - Domain → Data → Presentation 순서로 작성
5. **라우팅 설정** - `router.dart`에 새로운 경로 추가
6. **테스트 작성** - `test/` 디렉토리에 테스트 코드 추가

## 🔗 참고 자료

- [Clean Architecture](https://resocoder.com/flutter-clean-architecture)
- [Riverpod Documentation](https://riverpod.dev)
- [Freezed](https://pub.dev/packages/freezed)
- [GoRouter](https://pub.dev/packages/go_router)
