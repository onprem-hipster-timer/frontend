import 'package:dio/dio.dart';

import '../utils/patch_value.dart';

/// DTO 무관 제네릭 PATCH 헬퍼.
///
/// [PatchValue] 맵에서 present 필드만 추출하여 PATCH 요청을 전송합니다.
/// Retrofit의 `toJson()`은 `include_if_null: false`로 null 필드를 제외하므로,
/// 명시적 null 전송이 필요한 경우에 사용합니다.
///
/// ```dart
/// final result = await patchRequest<TodoRead>(
///   dio: dio,
///   path: '/v1/todos/$todoId',
///   fields: {'parent_id': PatchValue.present(null)},
///   fromJson: TodoRead.fromJson,
/// );
/// ```
Future<T> patchRequest<T>({
  required Dio dio,
  required String path,
  required Map<String, PatchValue<dynamic>> fields,
  required T Function(Map<String, dynamic>) fromJson,
}) async {
  final response = await dio.patch<Map<String, dynamic>>(
    path,
    data: patchBody(fields),
  );
  return fromJson(response.data!);
}
