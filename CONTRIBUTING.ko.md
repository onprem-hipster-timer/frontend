# Momeet Frontend 기여 가이드

**[English version](CONTRIBUTING.md)**

Momeet Frontend에 관심을 가져주셔서 감사합니다. 이 문서는 기여 절차와 가이드라인을 설명합니다.

## 목차

- [시작하기 전에](#시작하기-전에)
- [개발 환경](#개발-환경)
- [코딩 표준](#코딩-표준)
- [커밋 가이드라인](#커밋-가이드라인)
- [Pull Request 절차](#pull-request-절차)
- [리뷰 프로세스](#리뷰-프로세스)

---

## 시작하기 전에

### 기존 이슈 확인

작업을 시작하기 전에, 동일한 이슈나 PR이 있는지 확인하세요:

1. [기존 이슈](https://github.com/onprem-hipster-timer/frontend/issues) 검색
2. [기존 PR](https://github.com/onprem-hipster-timer/frontend/pulls) 검색

없다면, 먼저 이슈를 생성하여 변경 사항을 논의하세요.

### Issue First 정책

**사소하지 않은 모든 변경은 먼저 이슈가 필요합니다.**

- 버그 수정: 버그 리포트 이슈 생성
- 새 기능: 기능 요청 이슈 생성
- 문서: 작은 수정은 바로 PR 가능

이를 통해 프로젝트 방향과 일치하는 작업을 보장하고 중복 작업을 방지합니다.

---

## 개발 환경

### 필수 사항

- [FVM](https://fvm.app/documentation/getting-started/installation) (Flutter Version Management)
- Git
- Android Studio 또는 VS Code
- Android SDK (Android 빌드용)
- Xcode (macOS 전용, iOS 빌드용)

### 설정

```bash
# Fork 후 clone
git clone https://github.com/YOUR_USERNAME/frontend.git
cd frontend

# FVM으로 Flutter SDK 설치
fvm install stable
fvm use stable

# 의존성 설치
fvm flutter pub get

# 코드 생성
fvm dart run build_runner build --delete-conflicting-outputs
```

### 앱 실행

```bash
# 환경 확인
fvm flutter doctor -v

# 연결된 디바이스 또는 에뮬레이터에서 실행
fvm flutter run
```

### 테스트 실행

**모든 코드 변경은 테스트를 통과해야 합니다.**

```bash
# 전체 테스트 실행
fvm flutter test

# 특정 테스트 파일
fvm flutter test test/widget_test.dart

# 커버리지 포함
fvm flutter test --coverage
```

---

## 코딩 표준

### Dart 스타일

[Effective Dart](https://dart.dev/effective-dart) 가이드라인을 따르며, 다음 사항을 준수합니다:

- 줄 길이: 최대 80자 (Dart 기본)
- 공개 API에 타입 어노테이션 사용
- 모든 공개 클래스, 메서드, 프로퍼티에 `///` 문서 주석 작성
- `analysis_options.yaml` 린터 규칙 준수

### 아키텍처 원칙

1. **Feature-first**: 각 기능은 `lib/features/` 아래 독립 모듈
2. **Riverpod 상태 관리**: 모든 provider에 `@riverpod` 어노테이션 사용
3. **Freezed 모델**: `@freezed`로 불변 데이터 클래스 정의
4. **FVM 필수**: 모든 Flutter/Dart 명령어에 `fvm` 접두사 사용

### 파일 명명

| 유형 | 패턴 | 예시 |
|------|------|------|
| Page | `lib/features/{feature}/presentation/pages/{name}_page.dart` | `calendar_page.dart` |
| Widget | `lib/features/{feature}/presentation/widgets/{name}.dart` | `schedule_card.dart` |
| Provider | `lib/features/{feature}/presentation/providers/{name}_provider.dart` | `calendar_providers.dart` |
| Model | `lib/shared/api/models/{name}.dart` | `schedule_read.dart` |
| API Client | `lib/shared/api/{feature}/{feature}_client.dart` | `schedules_client.dart` |

### 생성 파일

- `*.freezed.dart`, `*.g.dart` 파일은 **절대 직접 수정하지 마세요**
- `build_runner`가 자동 재생성합니다

---

## 커밋 가이드라인

### 커밋 메시지 형식

Conventional Commit 형식을 따릅니다:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 타입

| 타입 | 설명 |
|------|------|
| `feat` | 새 기능 |
| `fix` | 버그 수정 |
| `docs` | 문서만 변경 |
| `style` | 코드 스타일 (포맷팅, 로직 변경 없음) |
| `refactor` | 버그 수정도 기능 추가도 아닌 코드 변경 |
| `test` | 테스트 추가 또는 수정 |
| `chore` | 빌드 프로세스, 의존성 등 |

### 예시

```
feat(calendar): 드래그 앤 드롭 일정 이동 구현

캘린더 주간 뷰에서 드래그 앤 드롭으로 일정 시간을 변경하는 기능 구현.

- DraggableEvent 위젯 추가
- DroppableTimeSlot 위젯 추가
- schedule_mutations provider 업데이트

Closes #42
```

### 커밋 원칙

1. **원자적 커밋**: 각 커밋은 하나의 논리적 변경
2. **빌드 가능**: 각 커밋에서 모든 테스트 통과
3. **설명적**: 제목은 무엇을, 본문은 왜를 설명
4. **이슈 참조**: Footer에 `Closes #N` 또는 `Fixes #N` 사용

---

## Pull Request 절차

### 제출 전 체크리스트

- [ ] 모든 테스트 통과 (`fvm flutter test`)
- [ ] 코드 분석 통과 (`fvm flutter analyze`)
- [ ] 새 코드에 적절한 테스트 작성
- [ ] 코드 생성 정상 동작 (`fvm dart run build_runner build --delete-conflicting-outputs`)
- [ ] 필요시 문서 업데이트
- [ ] 커밋 메시지 가이드라인 준수
- [ ] 최신 `dev`에 리베이스

### PR 제목 형식

커밋 메시지 제목과 동일:

```
feat(timer): 일시정지/재개 기능 추가
fix(auth): Supabase 토큰 갱신 실패 처리
docs: macOS 설정 가이드 업데이트
```

### PR 설명

PR 템플릿을 사용하세요. 다음을 포함합니다:

1. **요약**: 이 PR이 하는 일
2. **관련 이슈**: 이슈 링크 (`Closes #N`)
3. **변경 사항**: 변경 내용 목록
4. **테스트 계획**: 검증 방법
5. **스크린샷**: UI 변경이 있는 경우

### PR 크기

- PR은 집중적이고 적절한 크기로 유지
- 큰 변경은 논리적으로 리뷰 가능한 단위로 분리
- PR이 너무 커지면 분리를 논의

---

## 리뷰 프로세스

### 리뷰어가 확인하는 것

1. **정확성**: 코드가 의도한 대로 동작하는가?
2. **테스트**: 엣지 케이스가 커버되었는가?
3. **아키텍처**: 프로젝트 패턴을 따르는가? (Riverpod, Freezed, feature-first)
4. **성능**: 불필요한 리빌드나 비용이 큰 연산이 있는가?
5. **UI/UX**: Material Design 가이드라인을 따르는가?

### 리뷰 대응

- 재리뷰 요청 전에 모든 코멘트 처리
- 동의하지 않으면 이유를 설명
- 처리 후 대화를 resolved로 표시

### 리뷰 타임라인

- 메인테이너는 3-5 영업일 내 초기 리뷰 제공 목표
- 복잡한 PR은 더 걸릴 수 있음
- 1주일 후 응답 없으면 PR에서 핑

---

## 도움 받기

- **질문**: [Discussion](https://github.com/onprem-hipster-timer/frontend/discussions) 열기
- **버그**: [Issue](https://github.com/onprem-hipster-timer/frontend/issues) 생성
- **보안**: [SECURITY.md](SECURITY.md) 참조

---

*좋은 코드는 좋은 리뷰에서 나옵니다. 기여해 주셔서 감사합니다.*
