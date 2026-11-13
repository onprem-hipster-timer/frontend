import 'package:dio/dio.dart';
import 'package:momeet/features/visibility/domain/resource_visibility.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// `/v1/visibility/{type}/{id}`로 리소스 하나의 공유 설정을 읽고 바꾼다
///
/// 테스트: test/features/visibility/data/rest_resource_visibility_test.dart
class RestResourceVisibility implements ResourceVisibility {
  const RestResourceVisibility(this._client, this._type, this._id);

  final VisibilityClient _client;
  final ResourceType _type;
  final String _id;

  @override
  Future<VisibilityRead?> load() async {
    try {
      return await _client.getVisibilityV1VisibilityResourceTypeResourceIdGet(
        resourceType: _type,
        resourceId: _id,
      );
    } on DioException catch (error) {
      // 설정이 없으면 서버가 404로 답한다
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<void> save(VisibilityUpdate update) =>
      _client.setVisibilityV1VisibilityResourceTypeResourceIdPut(
        resourceType: _type,
        resourceId: _id,
        body: update,
      );

  @override
  Future<void> clear() =>
      _client.deleteVisibilityV1VisibilityResourceTypeResourceIdDelete(
        resourceType: _type,
        resourceId: _id,
      );
}
