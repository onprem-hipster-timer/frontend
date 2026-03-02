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
│   │   └── http_client_config.dart # HTTP 클라이언트 설정
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
