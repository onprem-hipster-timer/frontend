import 'package:dio/dio.dart';

const _kExplicitNulls = 'explicit_nulls';

/// 명시적 null 전송이 필요한 필드가 있을 때 [RequestOptions]를 생성합니다.
///
/// ```dart
/// options: explicitNulls(['parent_id', 'description']),
/// ```
RequestOptions? explicitNulls(List<String> fields) {
  if (fields.isEmpty) return null;
  return RequestOptions(extra: {_kExplicitNulls: fields});
}

/// PATCH 요청에서 명시적 null 전송을 지원하는 인터셉터.
///
/// `include_if_null: false` 설정으로 Retrofit이 null 필드를 제외하지만,
/// 백엔드에 명시적으로 null을 전송해야 하는 경우(예: 부모 제거)
/// [explicitNulls] 헬퍼로 생성한 [RequestOptions]를 전달하면
/// 직렬화된 JSON에 해당 필드를 null로 주입합니다.
class ExplicitNullInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final nullFields = options.extra[_kExplicitNulls] as List<String>?;
    if (nullFields != null && nullFields.isNotEmpty) {
      final data = options.data;
      final Map<String, dynamic> json;
      if (data is Map<String, dynamic>) {
        json = data;
      } else if (data is String || data is FormData) {
        // null 필드 주입 불가능한 타입 — 원본 데이터 유지
        handler.next(options);
        return;
      } else if (data != null) {
        try {
          json = (data as dynamic).toJson() as Map<String, dynamic>;
        } catch (_) {
          handler.next(options);
          return;
        }
      } else {
        json = {};
      }
      for (final key in nullFields) {
        json[key] = null;
      }
      options.data = json;
    }
    handler.next(options);
  }
}
