import 'package:dio/dio.dart';

/// PATCH 요청에서 명시적 null 전송을 지원하는 인터셉터.
///
/// `include_if_null: false` 설정으로 Retrofit이 null 필드를 제외하지만,
/// 백엔드에 명시적으로 null을 전송해야 하는 경우(예: 부모 제거)
/// `RequestOptions.extra['explicit_nulls']`에 키 목록을 전달하면
/// 직렬화된 JSON에 해당 필드를 null로 주입합니다.
///
/// ```dart
/// api.updateTodoV1TodosTodoIdPatch(
///   todoId: id,
///   body: TodoUpdate(),
///   options: RequestOptions(extra: {'explicit_nulls': ['parent_id']}),
/// );
/// ```
class ExplicitNullInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final explicitNulls = options.extra['explicit_nulls'] as List<String>?;
    if (explicitNulls != null && explicitNulls.isNotEmpty) {
      final data = options.data;
      Map<String, dynamic> json;
      if (data is Map<String, dynamic>) {
        json = Map.of(data);
      } else if (data != null) {
        json = (data as dynamic).toJson() as Map<String, dynamic>;
      } else {
        json = {};
      }
      for (final key in explicitNulls) {
        json[key] = null;
      }
      options.data = json;
    }
    handler.next(options);
  }
}
