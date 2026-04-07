// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/resource_type.dart';
import '../models/visibility_read.dart';
import '../models/visibility_update.dart';

part 'visibility_client.g.dart';

@RestApi()
abstract class VisibilityClient {
  factory VisibilityClient(Dio dio, {String? baseUrl}) = _VisibilityClient;

  /// Set Visibility.
  ///
  /// 리소스 접근권한 설정/업데이트.
  ///
  /// 소유자만 접근권한을 설정할 수 있습니다.
  @PUT('/v1/visibility/{resource_type}/{resource_id}')
  Future<VisibilityRead> setVisibilityV1VisibilityResourceTypeResourceIdPut({
    @Path('resource_type') required ResourceType resourceType,
    @Path('resource_id') required String resourceId,
    @Body() required VisibilityUpdate body,
    @DioOptions() RequestOptions? options,
  });

  /// Get Visibility.
  ///
  /// 리소스 접근권한 설정 조회.
  ///
  /// 소유자만 접근권한 설정을 조회할 수 있습니다.
  @GET('/v1/visibility/{resource_type}/{resource_id}')
  Future<VisibilityRead> getVisibilityV1VisibilityResourceTypeResourceIdGet({
    @Path('resource_type') required ResourceType resourceType,
    @Path('resource_id') required String resourceId,
    @DioOptions() RequestOptions? options,
  });

  /// Delete Visibility.
  ///
  /// 리소스 접근권한 설정 삭제 (PRIVATE으로 복귀).
  ///
  /// 소유자만 접근권한을 삭제할 수 있습니다.
  @DELETE('/v1/visibility/{resource_type}/{resource_id}')
  Future<void> deleteVisibilityV1VisibilityResourceTypeResourceIdDelete({
    @Path('resource_type') required ResourceType resourceType,
    @Path('resource_id') required String resourceId,
    @DioOptions() RequestOptions? options,
  });
}
