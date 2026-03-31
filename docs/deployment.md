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
| `API_BASE_URL` | 백엔드 API 서버 URL | 클라이언트 공개 값 |
| `SUPABASE_URL` | Supabase 프로젝트 URL | 클라이언트 공개 값 |
| `SUPABASE_ANON_KEY` | Supabase 익명 접근 키 | 클라이언트 공개 값 |

!!! info "클라이언트 공개 값"
    위 값들은 Supabase가 클라이언트에 노출되도록 설계한 값입니다.
    보안은 Supabase RLS(Row Level Security)가 담당합니다.

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
| `API_BASE_URL` | 백엔드 API 서버 URL |
| `SUPABASE_URL` | Supabase 프로젝트 URL |
| `SUPABASE_ANON_KEY` | Supabase 익명 접근 키 |

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
