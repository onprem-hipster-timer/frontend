# Security Policy

**[한국어 버전은 아래에 있습니다](#보안-정책)**

## Reporting a Vulnerability

**Do NOT report security vulnerabilities through public GitHub issues.**

If you discover a security vulnerability, please report it privately:

### How to Report

1. **Email**: Send details to jjh4450git@gmail.com
2. **GitHub Security Advisory**: Use the [Security Advisory](https://github.com/onprem-hipster-timer/frontend/security/advisories/new) feature (preferred)

### What to Include

- Type of vulnerability (e.g., insecure storage, authentication bypass, data leakage)
- Affected component (file path, screen, function)
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response Timeline

| Stage | Timeline |
|-------|----------|
| Initial Response | Within 48 hours |
| Triage & Assessment | Within 1 week |
| Fix Development | Depends on severity |
| Disclosure | After fix is released |

### What to Expect

1. **Acknowledgment**: We'll confirm receipt of your report
2. **Communication**: We'll keep you informed of our progress
3. **Credit**: We'll credit you in the security advisory (unless you prefer anonymity)
4. **No Retaliation**: We will not take legal action against good-faith security researchers

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest release | Yes |
| Previous release | Security fixes only |
| Older versions | No |

## Security Best Practices

When building and deploying Momeet Frontend:

### Development Checklist

- [ ] Never commit `.env` files or API keys to version control
- [ ] Use `assets/.env` for environment configuration (listed in `.gitignore`)
- [ ] Keep Supabase credentials out of source code
- [ ] Run `fvm flutter pub get` only from trusted sources
- [ ] Review third-party package updates before upgrading

### Authentication

- Supabase auth tokens are managed by `supabase_flutter`
- Never store raw tokens in `SharedPreferences` — use secure storage
- Ensure token refresh logic handles expiration gracefully

### Data Storage

- Sensitive data should use encrypted storage (e.g., `flutter_secure_storage`)
- Hive boxes containing user data should not be exported or logged
- Do not log authentication tokens or personal information

### Build & Release

- [ ] Verify `proguard-rules.pro` strips debug info in release builds (Android)
- [ ] Ensure no debug logging in production builds
- [ ] Review app permissions in `AndroidManifest.xml` and `Info.plist`
- [ ] Keep dependencies updated (`fvm flutter pub upgrade`)

---

# 보안 정책

## 취약점 신고

**보안 취약점을 공개 GitHub 이슈로 신고하지 마세요.**

보안 취약점을 발견하면, 비공개로 신고해 주세요:

### 신고 방법

1. **이메일**: jjh4450git@gmail.com으로 세부 사항 전송
2. **GitHub Security Advisory**: [Security Advisory](https://github.com/onprem-hipster-timer/frontend/security/advisories/new) 기능 사용 (권장)

### 포함할 내용

- 취약점 유형 (예: 안전하지 않은 저장소, 인증 우회, 데이터 유출)
- 영향받는 컴포넌트 (파일 경로, 화면, 함수)
- 재현 단계
- 잠재적 영향
- 제안하는 수정 방법 (있다면)

### 응답 타임라인

| 단계 | 타임라인 |
|------|----------|
| 초기 응답 | 48시간 이내 |
| 분류 및 평가 | 1주일 이내 |
| 수정 개발 | 심각도에 따라 |
| 공개 | 수정 릴리스 후 |

### 기대할 수 있는 것

1. **확인**: 신고 접수 확인
2. **소통**: 진행 상황 공유
3. **크레딧**: 보안 공지에 기여자로 표시 (익명 희망 시 제외)
4. **보복 없음**: 선의의 보안 연구자에 대해 법적 조치를 취하지 않습니다

## 지원 버전

| 버전 | 지원 |
|------|------|
| 최신 릴리스 | 예 |
| 이전 릴리스 | 보안 수정만 |
| 더 오래된 버전 | 아니오 |

## 보안 모범 사례

Momeet Frontend 빌드 및 배포 시:

### 개발 체크리스트

- [ ] `.env` 파일이나 API 키를 버전 관리에 커밋하지 않기
- [ ] 환경 설정은 `assets/.env` 사용 (`.gitignore`에 등록)
- [ ] Supabase 자격 증명을 소스 코드에 포함하지 않기
- [ ] 신뢰할 수 있는 소스에서만 `fvm flutter pub get` 실행
- [ ] 서드파티 패키지 업데이트 시 변경 사항 검토

### 인증

- Supabase 인증 토큰은 `supabase_flutter`가 관리
- `SharedPreferences`에 원시 토큰 저장 금지 — 보안 저장소 사용
- 토큰 갱신 로직에서 만료를 적절히 처리

### 데이터 저장

- 민감한 데이터는 암호화된 저장소 사용 (예: `flutter_secure_storage`)
- 사용자 데이터가 포함된 Hive 박스를 내보내거나 로깅하지 않기
- 인증 토큰이나 개인정보를 로그에 기록하지 않기

### 빌드 및 릴리스

- [ ] 릴리스 빌드에서 `proguard-rules.pro`가 디버그 정보를 제거하는지 확인 (Android)
- [ ] 프로덕션 빌드에 디버그 로깅이 없는지 확인
- [ ] `AndroidManifest.xml` 및 `Info.plist`의 앱 권한 검토
- [ ] 의존성 최신 상태 유지 (`fvm flutter pub upgrade`)

---

*Thank you for helping keep Momeet secure.*
