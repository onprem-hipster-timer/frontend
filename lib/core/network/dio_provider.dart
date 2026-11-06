// Dio HTTP 클라이언트 프로바이더 with AuthInterceptor, TimezoneInterceptor, ServerClockInterceptor
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/config/app_config.dart';
import 'package:momeet/core/network/explicit_null_interceptor.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/core/network/timezone_interceptor.dart';
import 'package:momeet/core/providers/auth_provider.dart';

/// 요청에 백엔드용 JWT를 붙이고, 401이면 JWT를 한 번 새로 받아 재시도하는 Interceptor
///
/// - JWT는 요청 직전에 만료가 가까우면 새로 받는다 (AuthNotifier.freshAccessToken).
/// - 401은 서명 키 교체 등으로 JWT가 거부된 경우라 한 번만 새로 받아 재시도한다.
///   세션이 끝났으면 AuthNotifier가 미인증으로 바꾸고 요청은 401로 끝난다.
/// - 동시 갱신은 AuthNotifier가 한 번으로 합치므로 대기열(Queued) 방식을 쓰지 않는다.
///   대기열 방식에서 onError 안의 재시도가 다시 실패하면 onError끼리 기다리며 멈춘다.
class AuthInterceptor extends Interceptor {
  final Ref ref;

  /// 재시도에 쓰는 Dio (이 Interceptor가 붙은 인스턴스)
  final Dio dio;

  AuthInterceptor(this.ref, this.dio);

  static const _retriedKey = 'authRetried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String? token;
    try {
      token = await ref.read(authProvider.notifier).freshAccessToken();
    } catch (e) {
      // JWT를 받지 못하면(네트워크 오류 등) 요청을 보내지 않는다
      return handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          type: e is DioException ? e.type : DioExceptionType.unknown,
        ),
      );
    }

    if (token != null) {
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

    final options = err.requestOptions;
    if (err.response?.statusCode != 401 || options.extra[_retriedKey] == true) {
      return handler.next(err);
    }

    try {
      final token = await ref.read(authProvider.notifier).refreshAccessToken();
      if (token == null) return handler.next(err); // 세션이 끝나 미인증이 됐다
      options.extra[_retriedKey] = true;
      return handler.resolve(await dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      return handler.next(e);
    } catch (_) {
      return handler.next(err);
    }
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

  dio.interceptors.add(AuthInterceptor(ref, dio));
  dio.interceptors.add(TimezoneInterceptor());
  dio.interceptors.add(ExplicitNullInterceptor());
  dio.interceptors.add(ServerClockInterceptor(ref.watch(serverClockProvider)));

  return dio;
});
