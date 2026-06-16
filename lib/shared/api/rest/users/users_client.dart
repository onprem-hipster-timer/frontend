// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/my_profile_read.dart';

part 'users_client.g.dart';

@RestApi()
abstract class UsersClient {
  factory UsersClient(Dio dio, {String? baseUrl}) = _UsersClient;

  /// Get My Profile.
  ///
  /// 본인 표시 프로필 조회 (없으면 토큰 클레임으로 생성).
  ///
  /// `friend_code`를 공유하면 상대가 그 코드로 친구 요청을 보낼 수 있다.
  @GET('/v1/users/me')
  Future<MyProfileRead> getMyProfileV1UsersMeGet({
    @DioOptions() RequestOptions? options,
  });
}
