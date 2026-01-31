# MoMeet 프로젝트 초기 설정 가이드

## 🚀 빠른 시작

이 가이드는 MoMeet 프로젝트의 초기 설정 및 개발 환경을 구성하는 방법을 설명합니다.

## ✅ 환경 요구사항

- **Flutter**: ^3.8.1
- **Dart**: ^3.8.1
- **Node.js**: ^18.0.0 (OpenAPI Generator CLI용)
- **Java**: ^11.0.0 (OpenAPI Generator CLI용)

## 📦 프로젝트 의존성 설치

### 1. Flutter 패키지 설치

```bash
# 프로젝트 디렉토리로 이동
cd momeet

# 의존성 설치
flutter pub get
```

### 2. Code Generation 실행

프로젝트에는 Riverpod, Freezed, OpenAPI Generator 등의 코드 생성 도구가 포함되어 있습니다.

```bash
# 모든 코드 생성 실행
dart run build_runner build

# 또는 watch 모드 (개발 중에 사용)
dart run build_runner watch
```

### 3. OpenAPI 코드 생성 (API 스펙이 준비되면)

API 스펙 파일(예: `api.yaml`)이 준비되면 다음 명령어로 코드를 생성합니다:

```bash
openapi-generator-cli generate \
  -i api.yaml \
  -g dart-dio \
  -o lib/shared/api/generated \
  --additional-properties=pubName=momeet_api,pubVersion=1.0.0
```

또는 `pubspec.yaml`의 `openapi_generator_cli` 섹션을 구성하여 자동화할 수 있습니다:

```yaml
openapi_generator_cli:
  project:
    name: momeet_api
    output-dir: lib/shared/api/generated
    input-spec: api.yaml
    generator-name: dart-dio
```

## 🏗️ 프로젝트 구조 이해

### Core 레이어
- **config**: 앱 전역 설정 (API URL, 타임아웃 등)
- **exceptions**: 사용자 정의 예외 클래스
- **network**: HTTP 클라이언트 설정
- **providers**: Core Riverpod 프로바이더

### Shared 레이어
- **api/generated**: OpenAPI Generator로 자동 생성된 API 클래스
- **widgets**: 전역 공통 위젯
- **providers**: 공유 Riverpod 프로바이더
- **models**: 공유 데이터 모델

### Features 레이어
각 기능(Feature)별로 다음과 같이 구성됩니다:

```
features/<feature_name>/
├── domain/           # 비즈니스 로직
│   ├── entities/
│   └── repositories/
├── data/             # 데이터 접근
│   ├── datasources/
│   ├── models/
│   └── repositories/
└── presentation/     # UI
    ├── pages/
    ├── widgets/
    └── providers/
```

## 🔑 주요 파일

| 파일 | 설명 |
|------|------|
| `lib/main.dart` | 앱 진입점 (ProviderScope 포함) |
| `lib/app.dart` | 앱 루트 위젯 (테마 설정) |
| `lib/router.dart` | GoRouter 라우팅 설정 |
| `lib/core/config/app_config.dart` | 앱 전역 설정 |
| `lib/shared/api/generated/` | OpenAPI 생성 코드 |

## 📝 새로운 Feature 추가하기

새로운 기능을 추가하려면 다음 단계를 따르세요:

### 1단계: Feature 폴더 생성

```
features/<new_feature>/
├── domain/
│   ├── entities/
│   │   └── <entity>.dart
│   └── repositories/
│       └── <repository>.dart
├── data/
│   ├── datasources/
│   │   ├── <feature>_remote_data_source.dart
│   │   └── <feature>_local_data_source.dart
│   ├── models/
│   │   └── <model>.dart
│   └── repositories/
│       └── <feature>_repository_impl.dart
└── presentation/
    ├── pages/
    │   └── <feature>_page.dart
    ├── widgets/
    │   └── <widget>.dart
    └── providers/
        └── <feature>_provider.dart
```

### 2단계: Domain Layer 작성

**entities/<entity>.dart**
```dart
class <Entity> {
  final String id;
  // ... properties
  
  <Entity>({
    required this.id,
    // ...
  });
}
```

**repositories/<repository>.dart**
```dart
abstract class <Repository> {
  Future<List<<Entity>>> getAll();
  // ... methods
}
```

### 3단계: Data Layer 작성

**models/<model>.dart** (Freezed 사용)
```dart
@freezed
class <Model> with _$<Model> {
  const factory <Model>({
    required String id,
    // ...
  }) = _<Model>;
  
  factory <Model>.fromJson(Map<String, dynamic> json) =>
      _$<Model>FromJson(json);
}
```

**repositories/<feature>_repository_impl.dart**
```dart
class <RepositoryImpl> implements <Repository> {
  final <RemoteDataSource> remoteDataSource;
  
  <RepositoryImpl>(this.remoteDataSource);
  
  @override
  Future<List<<Entity>>> getAll() async {
    // ... implementation
  }
}
```

### 4단계: Presentation Layer 작성

**providers/<feature>_provider.dart**
```dart
@riverpod
Future<List<<Entity>>> <feature>List(<Feature>ListRef ref) async {
  final repository = ref.watch(<repositoryProvider>);
  return repository.getAll();
}
```

**pages/<feature>_page.dart**
```dart
class <Feature>Page extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(<featureListProvider>);
    
    return itemsAsync.when(
      data: (items) => ListView(...),
      loading: () => LoadingWidget(),
      error: (error, stack) => ErrorWidget(error: error),
    );
  }
}
```

### 5단계: 라우팅 설정

**router.dart**에 새로운 라우트 추가:
```dart
GoRoute(
  path: '/<feature>',
  name: '<feature>',
  builder: (context, state) => const <Feature>Page(),
)
```

## 🔄 코드 생성 명령어

### Riverpod 프로바이더 생성
```bash
dart run build_runner build

# 또는 watch 모드
dart run build_runner watch
```

### Freezed 모델 생성
```bash
dart run build_runner build
```

### 모든 코드 생성 일괄 실행
```bash
dart run build_runner build --delete-conflicting-outputs
```

## 🧪 개발 팁

### 1. Hot Reload 활용
```bash
flutter run
```
앱이 실행된 후 파일을 저장하면 자동으로 hot reload됩니다.

### 2. 디버그 로깅 활성화
`lib/core/config/app_config.dart`에서 `enableDebugLogging`을 `true`로 설정합니다:
```dart
static const bool enableDebugLogging = true;
```

### 3. Riverpod 상태 검사 (DevTools)
Flutter DevTools에서 Riverpod 탭을 사용하여 상태를 실시간으로 확인할 수 있습니다:
```bash
flutter pub global activate devtools
devtools
```

## 📚 주요 참고 자료

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Guide](https://riverpod.dev)
- [Freezed Package](https://pub.dev/packages/freezed)
- [GoRouter Guide](https://pub.dev/packages/go_router)
- [Clean Architecture](https://resocoder.com/flutter-clean-architecture)

## 🐛 문제 해결

### "Build runner stuck" 문제
```bash
dart run build_runner clean
dart run build_runner build
```

### Gradle 빌드 오류
```bash
cd android
./gradlew clean build
cd ..
flutter clean
flutter pub get
```

### iOS 빌드 오류
```bash
cd ios
rm -rf Pods
pod install
cd ..
flutter clean
flutter pub get
```

## ✨ 다음 단계

1. **의뢰서 문서 확인** - 프로젝트 요구사항 파악
2. **API 스펙 설정** - OpenAPI/Swagger 정의
3. **OpenAPI 코드 생성** - API 클라이언트 자동 생성
4. **Feature 구현 시작** - Domain → Data → Presentation 순서로 작성

---

**질문이나 문제가 있으면 ARCHITECTURE.md를 참고하세요!**
