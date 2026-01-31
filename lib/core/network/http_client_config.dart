/// Dio HTTP 클라이언트 설정
import 'package:dio/dio.dart';
import 'package:momeet/core/config/app_config.dart';

class HttpClientConfig {
  static Dio createDioClient({String? baseUrl, Map<String, dynamic>? headers}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        contentType: 'application/json',
        headers: headers ?? {},
      ),
    );

    // 인터셉터 추가 (필요시)
    _addInterceptors(dio);

    return dio;
  }

  static void _addInterceptors(Dio dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (AppConfig.enableDebugLogging) {
            print('🚀 [HTTP] ${options.method} ${options.path}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (AppConfig.enableDebugLogging) {
            print('✅ [HTTP] ${response.statusCode} ${response.requestOptions.path}');
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (AppConfig.enableDebugLogging) {
            print('❌ [HTTP] Error: ${error.message}');
          }
          return handler.next(error);
        },
      ),
    );
  }
}
