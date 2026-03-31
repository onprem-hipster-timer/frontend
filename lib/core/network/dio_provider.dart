// Dio HTTP 클라이언트 프로바이더 with AuthInterceptor, TimezoneInterceptor
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/config/app_config.dart';
import 'package:momeet/core/network/timezone_interceptor.dart';
import 'package:momeet/core/providers/auth_provider.dart';

/// JWT 토큰을 요청 헤더에 추가하는 Interceptor
class AuthInterceptor extends Interceptor {
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
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (AppConfig.enableDebugLogging) {
      debugPrint('❌ [HTTP] Error: ${err.message}');
      debugPrint('   Status: ${err.response?.statusCode}');
    }

    // 401 Unauthorized: 토큰 만료 → 자동 로그아웃
    if (err.response?.statusCode == 401) {
      debugPrint('⚠️ [AUTH] Unauthorized - signing out');
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
