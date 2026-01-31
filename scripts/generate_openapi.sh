#!/bin/bash
# OpenAPI 클라이언트 생성 스크립트 (Unix/Linux/macOS)
# 사용법: ./scripts/generate_openapi.sh

set -e  # 에러 발생 시 중단

echo ""
echo "========================================"
echo "OpenAPI 클라이언트 생성"
echo "========================================"
echo ""

# 프로젝트 루트로 이동
cd "$(dirname "$0")/.."

echo "[1/2] OpenAPI 생성기 실행 중..."
echo "입력 파일: lib/openapi/openapi.json"
echo "출력 디렉토리: lib/shared/api/generated"
echo ""

openapi-generator generate \
  -i lib/openapi/openapi.json \
  -g dart-dio \
  -o lib/shared/api/generated \
  --additional-properties="useFreezed=true,useNullSafety=true,enumUnknownDefaultCase=true,pubName=openapi_client"

echo ""
echo "[2/2] Flutter 의존성 업데이트 중..."
flutter pub get

echo ""
echo "========================================"
echo "✓ OpenAPI 클라이언트 생성 완료!"
echo "========================================"
echo ""
echo "생성된 파일 위치:"
echo "  - lib/shared/api/generated/"
echo ""
echo "사용 가이드:"
echo "  - OPENAPI_CLIENT_GUIDE.md"
echo "  - OPENAPI_GENERATION_REPORT.md"
echo ""
