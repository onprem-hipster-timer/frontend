// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/tag_create.dart';
import '../models/tag_group_create.dart';
import '../models/tag_group_read.dart';
import '../models/tag_group_read_with_tags.dart';
import '../models/tag_group_update.dart';
import '../models/tag_read.dart';
import '../models/tag_update.dart';

part 'tags_client.g.dart';

@RestApi()
abstract class TagsClient {
  factory TagsClient(Dio dio, {String? baseUrl}) = _TagsClient;

  /// Read Tag Groups.
  ///
  /// 모든 태그 그룹 조회 (태그 포함).
  @GET('/v1/tags/groups')
  Future<List<TagGroupReadWithTags>> readTagGroupsV1TagsGroupsGet({
    @DioOptions() RequestOptions? options,
  });

  /// Create Tag Group.
  ///
  /// 태그 그룹 생성.
  @POST('/v1/tags/groups')
  Future<TagGroupRead> createTagGroupV1TagsGroupsPost({
    @Body() required TagGroupCreate body,
    @DioOptions() RequestOptions? options,
  });

  /// Read Tag Group.
  ///
  /// 태그 그룹 조회 (태그 포함).
  @GET('/v1/tags/groups/{group_id}')
  Future<TagGroupReadWithTags> readTagGroupV1TagsGroupsGroupIdGet({
    @Path('group_id') required String groupId,
    @DioOptions() RequestOptions? options,
  });

  /// Update Tag Group.
  ///
  /// 태그 그룹 업데이트.
  @PATCH('/v1/tags/groups/{group_id}')
  Future<TagGroupRead> updateTagGroupV1TagsGroupsGroupIdPatch({
    @Path('group_id') required String groupId,
    @Body() required TagGroupUpdate body,
    @DioOptions() RequestOptions? options,
  });

  /// Delete Tag Group.
  ///
  /// 태그 그룹 삭제 (CASCADE로 태그도 삭제).
  @DELETE('/v1/tags/groups/{group_id}')
  Future<void> deleteTagGroupV1TagsGroupsGroupIdDelete({
    @Path('group_id') required String groupId,
    @DioOptions() RequestOptions? options,
  });

  /// Read Tags.
  ///
  /// 모든 태그 조회.
  @GET('/v1/tags')
  Future<List<TagRead>> readTagsV1TagsGet({
    @DioOptions() RequestOptions? options,
  });

  /// Create Tag.
  ///
  /// 태그 생성.
  @POST('/v1/tags')
  Future<TagRead> createTagV1TagsPost({
    @Body() required TagCreate body,
    @DioOptions() RequestOptions? options,
  });

  /// Read Tag.
  ///
  /// 태그 조회.
  @GET('/v1/tags/{tag_id}')
  Future<TagRead> readTagV1TagsTagIdGet({
    @Path('tag_id') required String tagId,
    @DioOptions() RequestOptions? options,
  });

  /// Update Tag.
  ///
  /// 태그 업데이트.
  @PATCH('/v1/tags/{tag_id}')
  Future<TagRead> updateTagV1TagsTagIdPatch({
    @Path('tag_id') required String tagId,
    @Body() required TagUpdate body,
    @DioOptions() RequestOptions? options,
  });

  /// Delete Tag.
  ///
  /// 태그 삭제.
  @DELETE('/v1/tags/{tag_id}')
  Future<void> deleteTagV1TagsTagIdDelete({
    @Path('tag_id') required String tagId,
    @DioOptions() RequestOptions? options,
  });
}
