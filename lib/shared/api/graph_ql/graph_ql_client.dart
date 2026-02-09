// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'graph_ql_client.g.dart';

@RestApi()
abstract class GraphQlClient {
  factory GraphQlClient(Dio dio, {String? baseUrl}) = _GraphQlClient;

  /// Handle Http Get
  @GET('/v1/graphql')
  Future<void> handleHttpGetV1GraphqlGet({
    @DioOptions() RequestOptions? options,
  });

  /// Handle Http Post
  @POST('/v1/graphql')
  Future<void> handleHttpPostV1GraphqlPost({
    @DioOptions() RequestOptions? options,
  });
}
