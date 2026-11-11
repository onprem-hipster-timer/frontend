# 프로덕션 배포 가이드

프론트엔드 웹 애플리케이션의 프로덕션 배포 파이프라인에 대한 가이드입니다.

---

## 📋 목차

- [개요](#개요)
- [배포 구조를 선택한 이유](#배포-구조를-선택한-이유)
- [배포 흐름](#배포-흐름)
- [환경변수 관리](#환경변수-관리)
- [Vercel 설정](#vercel-설정)
- [GitHub 설정](#github-설정)
- [관련 파일](#관련-파일)

---

## 개요

GitHub Actions에서 Flutter 웹 빌드를 수행한 뒤, Vercel CLI로 정적 파일만 배포하는 구조입니다.
Vercel의 원격 빌드 시스템을 사용하지 않습니다.

| 항목 | 설명 |
|------|------|
| 빌드 환경 | GitHub Actions (ubuntu-latest) |
| 빌드 도구 | Flutter SDK (stable) |
| 호스팅 | Vercel (정적 배포) |
| 배포 트리거 | `main` 브랜치 push, 수동 실행 (`workflow_dispatch`) |

---

## 배포 구조를 선택한 이유

Vercel Hobby 플랜에서 GitHub Organization 레포를 사용할 때 다음 제한이 있습니다:

| 제한 | 설명 |
|------|------|
| Git 연동 차단 | Org 레포를 Vercel 대시보드에서 연결 불가 |
| 커밋 작성자 체크 | 계정 소유자 외의 커밋 작성자가 push하면 배포 차단 |
| 빌드 환경 | Vercel 빌드 서버에 Flutter SDK 미설치 |

이를 우회하기 위해 **GitHub Actions + Vercel CLI(`--prebuilt`)** 조합을 사용합니다:

- **CLI 배포**는 Git 연동 제한에 걸리지 않음
- **토큰 인증**이라 커밋 작성자 체크 무관
- **GitHub Actions**에서 Flutter SDK를 직접 설치하여 빌드

---

## 배포 흐름

```
checkout
  → flutter pub get
  → .env 생성 (GitHub vars)
  → build_runner (코드 생성)
  → flutter build web --wasm --release
  → vercel pull (프로젝트 설정)
  → vercel build --prod (build/web → .vercel/output/static/)
  → vercel deploy --prebuilt --prod (결과물만 업로드)
```

!!! note "vercel build의 역할"
    `vercel.json`에서 `buildCommand: null`로 설정되어 있으므로, `vercel build`는 빌드를 실행하지 않습니다.
    `outputDirectory`에 지정된 `build/web`을 `.vercel/output/static/`으로 복사하는 역할만 합니다.

---

## 환경변수 관리

### 현재 구조

`assets/.env`는 CI 빌드 시 GitHub vars로부터 생성됩니다.

| 변수 | 용도 | 공개 여부 |
|------|------|-----------|
| `API_BASE_URL` | 백엔드 API 서버 URL. 인증(Ory Kratos)도 `API_BASE_URL/auth`로 부른다 | 클라이언트 공개 값 |
| `REALTIME_BACKEND` | 타이머 실시간 소켓 모드. backend의 `REALTIME_BACKEND`와 같은 값을 넣는다. `inprocess`(기본): `/v1/ws/timers`, `cloudflare`: `/realtime/ws` | 클라이언트 공개 값 |

### 레포에 커밋하지 않는 이유

현재 `.env`에는 공개 값만 있지만, 레포에 커밋하지 않습니다.
향후 네이티브(Android/iOS) 빌드 파이프라인이 추가될 때 시크릿 주입이 필요할 수 있으며,
동일한 패턴(CI에서 주입)을 유지하기 위함입니다.

| 구분 | 값 유형 | GitHub 저장 위치 |
|------|---------|------------------|
| 웹 빌드 | 공개 값 | `vars` (Variables) |
| 네이티브 빌드 (향후) | 비밀 값 | `secrets` (Secrets) |

---

## Vercel 설정

### vercel.json

```json
{
  "buildCommand": null,
  "outputDirectory": "build/web",
  "framework": null,
  "installCommand": null
}
```

| 필드 | 값 | 설명 |
|------|----|------|
| `buildCommand` | `null` | Vercel 원격 빌드 비활성화 |
| `outputDirectory` | `build/web` | Flutter 웹 빌드 출력 경로 |
| `framework` | `null` | 프레임워크 자동 감지 비활성화 |
| `installCommand` | `null` | 패키지 설치 비활성화 |

### 라우팅

SPA(Single Page Application) 라우팅을 위해 모든 경로를 `index.html`로 폴백합니다.
`flutter_service_worker.js`는 캐시 무효화를 위해 `Cache-Control: no-cache`로 설정합니다.

### 보안 헤더

`routes`의 첫 항목(`"src": "/(.*)"`, `"continue": true`)이 모든 응답에 다음 헤더를 붙입니다.

| 헤더 | 값 |
|------|----|
| `Content-Security-Policy-Report-Only` | 앱이 쓰는 출처만 허용하는 정책. 위반은 막지 않고 브라우저 콘솔에만 남는다. 강제하려면 헤더 이름만 `Content-Security-Policy`로 바꾼다 |
| `X-Content-Type-Options` | `nosniff` |
| `Referrer-Policy` | `strict-origin-when-cross-origin`. 다른 출처로는 origin만 보내므로 경로·쿼리(일회용 코드 등)가 나가지 않는다 |
| `X-Frame-Options` | `DENY`. CSP의 `frame-ancestors 'none'`은 Report-Only에서는 적용되지 않는다 |

정책의 출처와 근거:

| 지시어 | 출처 | 쓰는 곳 |
|--------|------|---------|
| `script-src` | `'wasm-unsafe-eval'` | `flutter build web --wasm`의 `main.dart.wasm`, skwasm·CanvasKit |
| `script-src`, `connect-src` | `https://www.gstatic.com/flutter-canvaskit/` | Flutter 엔진 렌더러(`flutter.js`가 엔진 리비전 경로에서 받는다) |
| `connect-src` | `https://fonts.gstatic.com/s/` | Flutter 엔진의 대체 글꼴(Noto 등) |
| `connect-src` | `https://api.momeet.date`, `wss://api.momeet.date` | `API_BASE_URL`(REST, Kratos `/auth`), 타이머 실시간 소켓 |
| `script-src`, `connect-src`, `img-src` | `https://*.clarity.ms`, `https://c.bing.com`(img) | 사용성 분석 동의 뒤 `web/landing/analytics.js`가 불러오는 Clarity |
| `style-src`, `font-src` | `https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/` | `index.html`, `privacy.html`, `terms.html`의 Pretendard |
| `script-src` | `https://cdn.jsdelivr.net/npm/marked@…`, `…/dompurify@…` | `privacy.html`, `terms.html`의 마크다운 렌더링 |
| `connect-src` | `https://api.github.com/gists/` | `web/legal/legal.js`가 읽는 약관·방침 Gist |
| `style-src` | `'unsafe-inline'` | Flutter 엔진이 넣는 `<style>`, `index.html`의 `style` 속성 |
| `img-src` | `blob:` | Flutter 엔진의 이미지 디코딩 |

`API_BASE_URL`, Pretendard·marked·DOMPurify 버전, Clarity 같은 외부 출처를 바꾸면 이 정책도 함께 바꿉니다.
`web/index.html`에는 인라인 `<script>`와 `on*` 속성을 두지 않고 `web/` 아래 파일로 둡니다(`script-src`에 `'unsafe-inline'`이 없다). Flutter 로더는 `web/flutter_bootstrap.js` 템플릿에 있습니다.

---

## GitHub 설정

### 필요한 Secrets

| Secret | 용도 |
|--------|------|
| `VERCEL_TOKEN` | Vercel CLI 인증 토큰 |
| `VERCEL_ORG_ID` | Vercel Organization ID |
| `VERCEL_PROJECT_ID` | Vercel Project ID |

### 필요한 Variables

| Variable | 용도 |
|----------|------|
| `API_BASE_URL` | 백엔드 API 서버 URL (인증은 `API_BASE_URL/auth`) |
| `REALTIME_BACKEND` | 타이머 실시간 소켓 모드 (`inprocess` 또는 `cloudflare`, 비우면 `inprocess`) |

!!! tip "환경변수 변경 시 재배포"
    GitHub vars를 변경해도 자동으로 재배포되지 않습니다.
    vars 변경 후 Actions 탭에서 **Deploy Production** 워크플로우를 수동 실행(`workflow_dispatch`)하세요.

---

## 관련 파일

| 파일 | 설명 |
|------|------|
| `.github/workflows/deploy-production.yml` | 프로덕션 배포 워크플로우 |
| `vercel.json` | Vercel 프로젝트 설정 |
| `.github/workflows/test.yml` | CI (린트, 테스트) 워크플로우 |
