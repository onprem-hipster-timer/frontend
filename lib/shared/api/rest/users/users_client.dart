// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/consent_create.dart';
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

  /// Put My Consent.
  ///
  /// 만 14세 이상 확인, 이용약관, 개인정보처리방침 동의 기록.
  ///
  /// `version`은 응답 전에 받은 현재 약관 시행일이어야 한다(다르면 409).
  @PUT('/v1/users/me/consent')
  Future<MyProfileRead> putMyConsentV1UsersMeConsentPut({
    @Body() required ConsentCreate body,
    @DioOptions() RequestOptions? options,
  });
}
