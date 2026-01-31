/// 공유 Riverpod 프로바이더
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/api.dart';

// OpenAPI 클라이언트 프로바이더
// API 기본 URL은 환경에 따라 설정해야 합니다
final openApiClientProvider = Provider<OpenApiClientWrapper>((ref) {
  // TODO: 환경에 맞게 API 기본 URL 설정
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  return OpenApiClientWrapper(baseUrl: baseUrl);
});
