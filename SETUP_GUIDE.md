# Momeet 프로젝트 초기 설정 가이드

## 🚀 빠른 시작

이 가이드는 Momeet 프로젝트의 초기 설정 및 개발 환경을 구성하는 방법을 설명합니다.

> 더 자세한 내용은 [README.md](README.md)를 참고하세요.

## ✅ 환경 요구사항

- **FVM**: 최신 버전 ([설치 가이드](https://fvm.app/documentation/getting-started/installation))
- **Flutter**: `3.41.1 (stable)` — FVM으로 관리
- **Dart**: `3.11.0` — Flutter에 포함
- **Android Studio**: 최신 stable (Android SDK + 에뮬레이터)
- **Xcode**: 최신 stable (macOS 전용, iOS 빌드)
- **Java**: OpenJDK 21 (Android Studio bundled JBR 권장)

## 📦 프로젝트 설정

### 1. FVM 설치

<details>
<summary><b>macOS</b></summary>

```bash
brew tap leoafarias/fvm
brew install fvm
```

</details>

<details>
<summary><b>Windows</b></summary>

```powershell
choco install fvm
```

또는 [GitHub Releases](https://github.com/leoafarias/fvm/releases)에서 다운로드.

</details>

```bash
# 설치 확인
fvm --version
```

### 2. Flutter SDK 설치 및 프로젝트 연결

```bash
# Flutter stable 설치
fvm install stable

# 프로젝트에 SDK 연결
fvm use stable
```

### 3. 의존성 설치

```bash
fvm flutter pub get
```

### 4. Code Generation 실행

프로젝트에는 Riverpod, Freezed, Retrofit, json_serializable 코드 생성 도구가 포함되어 있습니다.

```bash
# 모든 코드 생성 실행
fvm dart run build_runner build --delete-conflicting-outputs

# 또는 watch 모드 (개발 중에 사용)
fvm dart run build_runner watch --delete-conflicting-outputs
```

> ⚠️ `fvm flutter pub run ...`은 deprecated입니다. 항상 `fvm dart run ...`을 사용하세요.

### 5. 환경 확인

```bash
fvm flutter doctor -v
```

정상 기준: `No issues found!`

### 6. 앱 실행

```bash
fvm flutter run
```

## 🏗️ 프로젝트 구조 이해

### Core 레이어
- **config**: 앱 전역 설정 (API URL, 환경변수 등)
- **exceptions**: 사용자 정의 예외 클래스
- **network**: HTTP 클라이언트 설정 (Dio + Interceptor)
- **providers**: Core Riverpod 프로바이더 (인증 등)
- **utils**: 유틸리티 함수

### Shared 레이어
- **api/models**: Freezed 데이터 모델 (ScheduleRead, TodoRead 등)
- **api/{feature}**: Retrofit API 클라이언트 (schedules, todos, timers 등)
- **widgets**: 전역 공통 위젯
- **providers**: 공유 Riverpod 프로바이더

### Features 레이어
각 기능(Feature)별로 다음과 같이 구성됩니다:

```
features/<feature_name>/
├── presentation/         # UI 계층
│   ├── pages/            #   전체 페이지
│   ├── widgets/          #   UI 컴포넌트
│   ├── providers/        #   화면 상태 관리 (Riverpod)
│   └── state/            #   Freezed UI 상태 모델
```

## 🔑 주요 파일

| 파일 | 설명 |
|------|------|
| `lib/main.dart` | 앱 진입점 (ProviderScope 포함) |
| `lib/app.dart` | 앱 루트 위젯 (테마 설정) |
| `lib/router.dart` | GoRouter 라우팅 설정 |
| `lib/core/config/app_config.dart` | 앱 전역 설정 |
| `assets/.env` | 환경변수 (API URL 등) |
| `.fvmrc` | FVM Flutter 버전 설정 |

## 📝 새로운 Feature 추가하기

### 1단계: Feature 폴더 생성

```
features/<new_feature>/
└── presentation/
    ├── pages/
    │   └── <feature>_page.dart
    ├── widgets/
    │   └── <widget>.dart
    ├── providers/
    │   └── <feature>_providers.dart
    └── state/
        └── <feature>_state.dart       # (필요 시) Freezed UI 상태
```

### 2단계: Freezed 모델 작성 (필요 시)

```dart
// presentation/state/<feature>_state.dart
@freezed
class FeatureState with _$FeatureState {
  const factory FeatureState({
    @Default(false) bool isLoading,
    // ...
  }) = _FeatureState;
}
```

### 3단계: Riverpod Provider 작성

```dart
// presentation/providers/<feature>_providers.dart
@riverpod
Future<List<SomeModel>> featureItems(Ref ref) async {
  final client = ref.watch(someClientProvider);
  return client.getItems();
}
```

### 4단계: UI 페이지 작성

```dart
// presentation/pages/<feature>_page.dart
class FeaturePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(featureItemsProvider);

    return itemsAsync.when(
      data: (items) => ListView(...),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### 5단계: 라우팅 설정

`router.dart`에 새로운 라우트 추가:

```dart
GoRoute(
  path: '/<feature>',
  name: '<feature>',
  builder: (context, state) => const FeaturePage(),
)
```

### 6단계: 코드 생성 실행

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

## 🔄 코드 생성 명령어

```bash
# 1회 빌드 (Freezed + Retrofit + Riverpod + json_serializable)
fvm dart run build_runner build --delete-conflicting-outputs

# Watch 모드 (파일 변경 시 자동 재생성)
fvm dart run build_runner watch --delete-conflicting-outputs

# 캐시 초기화 (빌드 문제 시)
fvm dart run build_runner clean
```

## 🧪 개발 팁

### 1. Hot Reload 활용

```bash
fvm flutter run
```

앱이 실행된 후 파일을 저장하면 자동으로 Hot Reload됩니다.

### 2. 터미널 2개 병렬 운영

```bash
# 터미널 1: 코드 생성 Watch
fvm dart run build_runner watch --delete-conflicting-outputs

# 터미널 2: 앱 실행
fvm flutter run
```

### 3. Riverpod 상태 검사 (DevTools)

Flutter DevTools에서 Riverpod 탭으로 상태를 실시간 확인:

```bash
fvm flutter pub global activate devtools
fvm flutter pub global run devtools
```

## 🐛 문제 해결

### Build Runner 캐시 문제

```bash
fvm dart run build_runner clean
fvm dart run build_runner build --delete-conflicting-outputs
```

### 클린 빌드

```bash
fvm flutter clean
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter run
```

### Android Gradle 빌드 오류

```bash
fvm flutter clean
fvm flutter pub get
fvm flutter run
```

### iOS 빌드 오류 (macOS)

```bash
cd ios
rm -rf Pods
pod install
cd ..
fvm flutter clean
fvm flutter pub get
fvm flutter run
```

## 📚 주요 참고 자료

- [Flutter Documentation](https://flutter.dev/docs)
- [FVM Documentation](https://fvm.app/documentation/getting-started/installation)
- [Riverpod Guide](https://riverpod.dev)
- [Freezed](https://pub.dev/packages/freezed)
- [Retrofit](https://pub.dev/packages/retrofit)
- [GoRouter](https://pub.dev/packages/go_router)

---

**더 자세한 아키텍처 정보는 [ARCHITECTURE.md](ARCHITECTURE.md)를 참고하세요.**
