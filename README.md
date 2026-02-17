<div align="center">

<a id="top"></a>

# 📅 Momeet Frontend

**Plan your day efficiently — calendar, timers, todos, and friends in one app**

[![Flutter](https://img.shields.io/badge/Flutter-3.41.1-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11.0-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![FVM](https://img.shields.io/badge/FVM-Managed-5B4F9B?style=flat-square&logo=dart&logoColor=white)](https://fvm.app)
[![Riverpod](https://img.shields.io/badge/Riverpod-3.x-00B0FF?style=flat-square)](https://riverpod.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Auth-3ECF8E?style=flat-square&logo=supabase&logoColor=white)](https://supabase.com)
[![Retrofit](https://img.shields.io/badge/Retrofit-API_Client-FF6F00?style=flat-square)](https://pub.dev/packages/retrofit)
[![Freezed](https://img.shields.io/badge/Freezed-Codegen-blue?style=flat-square)](https://pub.dev/packages/freezed)
[![Android](https://img.shields.io/badge/Android-Supported-3DDC84?style=flat-square&logo=android&logoColor=white)](https://developer.android.com)
[![iOS](https://img.shields.io/badge/iOS-Supported-000000?style=flat-square&logo=apple&logoColor=white)](https://developer.apple.com)

[Features](#features) •
[Prerequisites](#prerequisites) •
[Quick Start](#quick-start) •
[Architecture](#architecture) •
[Code Generation](#code-generation) •
[IDE Setup](#ide-setup) •
[Development Workflow](#development-workflow) •
[Troubleshooting](#troubleshooting)

</div>

---

<!-- TOC -->

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
  - [FVM 설치](#fvm-설치)
  - [개발 환경 요구사항](#개발-환경-요구사항)
  - [SDK 경로 참조](#sdk-경로-참조)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
  - [프로젝트 구조](#프로젝트-구조)
  - [기술 스택](#기술-스택)
- [Code Generation](#code-generation)
  - [빌드 명령어](#빌드-명령어)
  - [Watch 모드](#watch-모드)
  - [생성 파일 규칙](#생성-파일-규칙)
- [IDE Setup](#ide-setup)
  - [Android Studio](#android-studio)
  - [VS Code](#vs-code)
- [Development Workflow](#development-workflow)
- [Troubleshooting](#troubleshooting)
  - [공통](#공통-이슈)
  - [Windows](#windows-이슈)
  - [macOS](#macos-이슈)
  - [Android 빌드](#android-빌드-이슈)

<!-- /TOC -->

---

<a id="overview"></a>

## 📖 Overview

**Momeet**은 캘린더 · 타이머 · 할 일 · 태그 · 친구 기능을 하나로 통합한 생산성 앱의 Flutter 프론트엔드입니다.
FVM으로 Flutter 버전을 관리하며, macOS와 Windows 양쪽에서 개발할 수 있습니다.

---

<a id="features"></a>

## ✨ Features

| 기능 | 설명 | 핵심 패키지 |
|------|------|-------------|
| 📅 **Calendar** | Syncfusion 기반 일정 관리, 공휴일 표시 | `syncfusion_flutter_calendar` |
| ⏱️ **Timer** | 일정 연동 시간 추적 (포모도로 스타일) | Retrofit API client |
| ✅ **Todo** | 계층형 할 일 관리, 상태 추적 | Freezed models |
| 🏷️ **Tags** | 태그 그룹으로 일정 · 타이머 · 할 일 연결 | Tag group CRUD |
| 👥 **Friends** | 친구 요청 · 수락 · 공유 워크플로 | Supabase + REST |
| 🔐 **Auth** | Supabase 인증 (로그인 · 회원가입) | `supabase_flutter` |
| 🎨 **UI/UX** | Material Design + 애니메이션 | `flutter_animate` |

---

<a id="prerequisites"></a>

## 📋 Prerequisites

<a id="fvm-설치"></a>

### FVM 설치

이 프로젝트는 [FVM (Flutter Version Management)](https://fvm.app)으로 Flutter SDK 버전을 관리합니다.

> 📘 공식 설치 가이드: <https://fvm.app/documentation/getting-started/installation>

<details>
<summary><b>macOS</b></summary>

**Homebrew (권장):**

```bash
brew tap leoafarias/fvm
brew install fvm
```

**Install Script:**

```bash
curl -fsSL https://fvm.app/install.sh | bash
```

설치 후 PATH 설정이 필요할 수 있습니다. 사용 중인 셸에 맞게 추가하세요:

```bash
# ~/.zshrc 또는 ~/.bashrc에 추가
export PATH="$HOME/fvm/bin:$PATH"
```

```bash
source ~/.zshrc
```

</details>

<details>
<summary><b>Windows</b></summary>

**Chocolatey:**

```powershell
choco install fvm
```

**Standalone:**

[GitHub Releases](https://github.com/leoafarias/fvm/releases)에서 Windows 패키지를 다운로드하여 설치합니다.

**Dart pub (글로벌 Flutter가 이미 있는 경우):**

```powershell
dart pub global activate fvm
```

</details>

설치 확인:

```bash
fvm --version
```

FVM 설치 후, 프로젝트에서 사용할 Flutter SDK를 설치합니다:

```bash
fvm install stable
```

<a id="개발-환경-요구사항"></a>

### 개발 환경 요구사항

| 항목 | 버전 | 비고 |
|------|------|------|
| Flutter | `3.41.1 (stable)` | FVM으로 관리 |
| Dart | `3.11.0` | Flutter에 포함 |
| Android SDK | `36.1.0` | Android Studio에서 설치 |
| Java | OpenJDK 21 | Android Studio bundled JBR 권장 |
| Xcode | 최신 stable | macOS 전용, iOS 빌드 시 필요 |

환경 점검:

```bash
fvm flutter doctor -v
```

정상 기준: `No issues found!`

<a id="sdk-경로-참조"></a>

### SDK 경로 참조

프로젝트 SDK는 `.fvm/flutter_sdk` 심볼릭 링크를 통해 참조됩니다.

<details>
<summary><b>macOS 기본 경로</b></summary>

| 항목 | 경로 |
|------|------|
| FVM Flutter SDK | `~/fvm/versions/stable` |
| Flutter 실행 파일 | `~/fvm/versions/stable/bin/flutter` |
| Dart 실행 파일 | `~/fvm/versions/stable/bin/cache/dart-sdk/bin/dart` |
| Android SDK | `~/Library/Android/sdk` |

</details>

<details>
<summary><b>Windows 기본 경로</b></summary>

| 항목 | 경로 |
|------|------|
| FVM Flutter SDK | `C:\Users\<user>\fvm\versions\stable` |
| Flutter 실행 파일 | `C:\Users\<user>\fvm\versions\stable\bin\flutter.bat` |
| Dart 실행 파일 | `C:\Users\<user>\fvm\versions\stable\bin\cache\dart-sdk\bin\dart.exe` |
| Android SDK | `C:\Users\<user>\AppData\Local\Android\sdk` |

</details>

---

<a id="quick-start"></a>

## 🚀 Quick Start

```bash
# 1. Flutter stable 채널 설치 (최초 1회)
fvm install stable

# 2. 프로젝트에 Flutter SDK 연결
fvm use stable

# 3. 의존성 설치
fvm flutter pub get

# 4. 코드 생성 (Freezed / Retrofit / Riverpod)
fvm dart run build_runner build --delete-conflicting-outputs

# 5. 앱 실행
fvm flutter run
```

> 모든 `flutter` / `dart` 명령어 앞에 `fvm`을 붙여야 프로젝트에 지정된 Flutter 버전이 사용됩니다.

---

<a id="architecture"></a>

## 🏗️ Architecture

<a id="프로젝트-구조"></a>

### 프로젝트 구조

Feature-first + Shared layer 아키텍처를 따릅니다.

```
lib/
├── main.dart                       # 앱 진입점
├── app.dart                        # MaterialApp 설정
├── router.dart                     # GoRouter 라우팅
│
├── core/                           # 공통 인프라
│   ├── config/                     #   앱 설정 (환경변수 등)
│   ├── exceptions/                 #   커스텀 예외
│   ├── network/                    #   네트워크 설정
│   ├── providers/                  #   인증 등 핵심 provider
│   ├── templates/                  #   공통 템플릿
│   └── utils/                      #   유틸리티
│
├── features/                       # 기능별 모듈 (feature-first)
│   ├── auth/                       #   로그인 · 회원가입
│   ├── calendar/                   #   캘린더 · 일정
│   ├── home/                       #   홈 화면
│   ├── tag/                        #   태그 관리
│   ├── timer/                      #   타이머
│   └── todo/                       #   할 일
│
├── shared/                         # 공유 레이어
│   ├── api/                        #   Retrofit API 클라이언트 + 모델
│   │   ├── models/                 #     Freezed 데이터 모델
│   │   ├── schedules/              #     일정 API
│   │   ├── todos/                  #     할 일 API
│   │   ├── timers/                 #     타이머 API
│   │   ├── tags/                   #     태그 API
│   │   ├── friends/                #     친구 API
│   │   ├── holidays/               #     공휴일 API
│   │   ├── health/                 #     헬스체크 API
│   │   └── graph_ql/               #     GraphQL 클라이언트
│   ├── providers/                  #   공유 provider
│   └── widgets/                    #   공용 위젯
│
└── openapi/                        # OpenAPI 관련
```

<a id="기술-스택"></a>

### 기술 스택

| 영역 | 기술 |
|------|------|
| **상태 관리** | Riverpod 3.x + riverpod_generator |
| **라우팅** | GoRouter |
| **HTTP 클라이언트** | Dio + Retrofit |
| **인증** | Supabase Flutter |
| **코드 생성** | Freezed, json_serializable, retrofit_generator, riverpod_generator |
| **로컬 저장소** | Hive, SharedPreferences |
| **캘린더** | Syncfusion Flutter Calendar |
| **UI 애니메이션** | flutter_animate |
| **국제화** | intl |

---

<a id="code-generation"></a>

## ⚙️ Code Generation

이 프로젝트는 **Freezed**, **JsonSerializable**, **Retrofit**, **Riverpod** 코드 생성을 사용합니다.

<a id="빌드-명령어"></a>

### 빌드 명령어

**1회 빌드:**

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

> ⚠️ `fvm flutter pub run ...`은 deprecated입니다. 항상 `fvm dart run ...`을 사용하세요.

<a id="watch-모드"></a>

### Watch 모드

파일 저장 시 자동으로 코드를 재생성합니다:

```bash
fvm dart run build_runner watch --delete-conflicting-outputs
```

종료: `Ctrl + C`

<a id="생성-파일-규칙"></a>

### 생성 파일 규칙

| 패턴 | 생성 도구 | 용도 |
|------|-----------|------|
| `*.freezed.dart` | Freezed | 불변 모델, union type, copyWith |
| `*.g.dart` | json_serializable / Retrofit / Riverpod | fromJson, toJson, API client, provider |

**예시:** `schedule_read.dart` 기준

```
lib/shared/api/models/
├── schedule_read.dart              # 소스 (직접 편집)
├── schedule_read.freezed.dart      # Freezed 자동 생성 (편집 금지)
└── schedule_read.g.dart            # JSON 직렬화 자동 생성 (편집 금지)
```

> `*.freezed.dart`, `*.g.dart` 파일은 **절대 직접 수정하지 마세요.** 소스 파일을 수정한 뒤 `build_runner`가 재생성합니다.

---

<a id="ide-setup"></a>

## 🖥️ IDE Setup

<a id="android-studio"></a>

### Android Studio

1. `File > Settings > Languages & Frameworks > Flutter` (macOS: `Preferences > ...`)
2. Flutter SDK path를 프로젝트 로컬 심볼릭 링크로 지정:

```
<project_root>/.fvm/flutter_sdk
```

3. Dart SDK는 자동 인식됨 (필요 시 수동: `.fvm/flutter_sdk/bin/cache/dart-sdk`)

<a id="vs-code"></a>

### VS Code

프로젝트 루트에 `.vscode/settings.json`이 없다면 생성:

```json
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk"
}
```

> FVM이 자동으로 설정해주는 경우도 있습니다. 이미 있다면 별도 설정 불필요.

---

<a id="development-workflow"></a>

## 🔄 Development Workflow

### 일일 개발 루틴

두 개의 터미널을 열어 병렬로 운영합니다:

**터미널 1** — 코드 생성 (Watch):

```bash
fvm dart run build_runner watch --delete-conflicting-outputs
```

**터미널 2** — 앱 실행:

```bash
fvm flutter run
```

### 클린 빌드 (문제 발생 시)

```bash
fvm flutter clean
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter run
```

---

<a id="troubleshooting"></a>

## 🔧 Troubleshooting

<a id="공통-이슈"></a>

### 공통

#### Build Runner 경고

| 경고 메시지 | 의미 | 권장 조치 |
|-------------|------|-----------|
| `XxxRequest must provide a toJson()` | Retrofit request body에 toJson 필요 | 모델에 `@JsonSerializable()` 추가 |
| `language version (3.0.0) ... required ^3.8.0` | Dart SDK constraint 낮음 | `pubspec.yaml`의 `sdk` 최소 `^3.8.0`으로 상향 |
| `json_annotation ... before 4.10.0 not allowed` | json_annotation 버전 제약 | `json_annotation` 버전 점검 |

#### Android 라이선스 미수락

```bash
fvm flutter doctor --android-licenses
# 모든 라이선스를 y로 수락

fvm flutter doctor -v
```

---

<a id="windows-이슈"></a>

### Windows

#### FVM symlink 생성 실패 (`errno = 1314`)

**에러:**

```
Failed to create version symlink
클라이언트가 필요한 권한을 가지고 있지 않습니다 (errno = 1314)
```

**원인:** Windows에서 일반 사용자에게 심볼릭 링크 생성 권한이 없음 ([mklink 참고](https://learn.microsoft.com/ko-kr/windows-server/administration/windows-commands/mklink))

**solution:**

| 방법 | 설명 |
|------|------|
| **A. 관리자 권한으로 실행** | 터미널 또는 IDE를 우클릭 → "관리자 권한으로 실행" |
| **B. Developer Mode 활성화** | `Settings > For developers > Developer Mode` ON — 이후 일반 권한에서도 symlink 생성 가능 |

이후 기존 깨진 링크가 남아 있다면 정리 후 재실행:

```powershell
Remove-Item -Recurse -Force .\.fvm\versions\stable -ErrorAction SilentlyContinue
Remove-Item -Force .\.fvm\flutter_sdk -ErrorAction SilentlyContinue
fvm use stable
```

#### `adb` 명령어 인식 안 됨

**에러:**

```
adb : The term 'adb' is not recognized ...
```

**원인:** `platform-tools`가 시스템 PATH에 없음

**즉시 실행 (절대경로):**

```powershell
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" devices
```

**영구 해결 — PATH에 추가:**

```
C:\Users\<user>\AppData\Local\Android\sdk\platform-tools
C:\Users\<user>\AppData\Local\Android\sdk\emulator
```

#### 동일 AVD 중복 실행

**에러:**

```
Running multiple emulators with the same AVD ...
```

**해결:** 기존 동일 AVD 종료 후 1개만 실행

```powershell
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" devices
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" -s emulator-5554 emu kill
```

---

<a id="macos-이슈"></a>

### macOS

#### CocoaPods 관련 에러

**에러:**

```
Error running pod install
CocoaPods not installed or not in PATH
```

**해결:**

```bash
sudo gem install cocoapods
# 또는 Homebrew 사용
brew install cocoapods

cd ios && pod install && cd ..
```

#### Xcode Command Line Tools 누락

**에러:**

```
Xcode installation is incomplete
```

**해결:**

```bash
xcode-select --install
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

#### iOS Simulator 실행

```bash
open -a Simulator
fvm flutter run
```

---

<a id="license"></a>

## 📄 License

This project is licensed under the [Mozilla Public License 2.0](https://www.mozilla.org/en-US/MPL/2.0/).

- 소스 코드를 자유롭게 사용, 수정, 배포할 수 있습니다.
- 수정한 MPL 적용 파일의 소스 코드를 공개해야 합니다.
- MPL 파일과 결합된 독자적 코드는 별도 라이선스를 적용할 수 있습니다.

자세한 내용은 [LICENSE](LICENSE) 파일을 참고하세요.

<div align="center">

[⬆️ Back to top](#top)

</div>
