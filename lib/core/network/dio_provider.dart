// Dio HTTP 클라이언트 프로바이더 with AuthInterceptor, TimezoneInterceptor
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/config/app_config.dart';
import 'package:momeet/core/network/timezone_interceptor.dart';
import 'package:momeet/core/providers/auth_provider.dart';

/// JWT 토큰 추가 및 401 시 세션 갱신 후 재시도하는 Interceptor
///
/// QueuedInterceptorsWrapper를 사용하여 동시 401 응답이 여러 건 발생해도
/// 세션 갱신은 한 번만 수행되고 나머지 요청은 큐에서 대기합니다.
class AuthInterceptor extends QueuedInterceptorsWrapper {
  final Ref ref;

  AuthInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = ref.read(accessTokenProvider);

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    if (AppConfig.enableDebugLogging) {
      debugPrint('🚀 [HTTP] ${options.method} ${options.path}');
      if (token != null) {
        debugPrint('   ✓ Authorization Header Added');
      }
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (AppConfig.enableDebugLogging) {
      debugPrint(
        '✅ [HTTP] ${response.statusCode} ${response.requestOptions.path}',
      );
    }
    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (AppConfig.enableDebugLogging) {
      debugPrint('❌ [HTTP] Error: ${err.message}');
      debugPrint('   Status: ${err.response?.statusCode}');
    }

    if (err.response?.statusCode == 401) {
      debugPrint('⚠️ [AUTH] 401 received - signing out');
      ref.read(authProvider.notifier).signOut();
    }

    return handler.next(err);
  }
}

/// Dio 클라이언트 프로바이더
///
/// 사용 예:
/// ```dart
/// final dio = ref.watch(dioClientProvider);
/// ```
final dioClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      contentType: 'application/json',
      headers: {'Accept': 'application/json'},
      // AuthInterceptor 추가 (JWT 토큰 자동 추가)
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref));
  dio.interceptors.add(TimezoneInterceptor());

  return dio;
});
