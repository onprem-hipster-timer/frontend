// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/consent_create.dart';
import '../models/guest_create.dart';
import '../models/guest_lookup.dart';
import '../models/guest_lookup_read.dart';
import '../models/guest_read.dart';

part 'guests_client.g.dart';

@RestApi()
abstract class GuestsClient {
  factory GuestsClient(Dio dio, {String? baseUrl}) = _GuestsClient;

  /// Lookup Guest.
  ///
  /// 리소스에서 이름이 같은 게스트의 로그인 식별자(handle)를 찾는다. 없으면 handle은 null.
  /// `consent_version`은 현재 약관 시행일이다. 게스트를 만들 때 `consent.version`으로 보낸다.
  ///
  /// 리소스가 없거나 지금 게스트를 받지 않으면 403.
  /// X-Turnstile-Token 헤더의 토큰이 확인을 통과하지 못하면 403, 확인할 수 없으면 503 (다른 확인보다 먼저다).
  @POST('/v1/guests/lookup')
  Future<GuestLookupRead> lookupGuestV1GuestsLookupPost({
    @Body() required GuestLookup body,
    @DioOptions() RequestOptions? options,
  });

  /// Create Guest.
  ///
  /// 리소스에 새 게스트를 만든다. 로그인은 응답의 handle과 비밀번호로 Kratos에 한다.
  ///
  /// `consent`는 만 14세 이상·이용약관·개인정보처리방침 동의로 세 항목 모두 true여야 한다(아니면 422).
  /// `consent.version`이 현재 약관 시행일이 아니면 409이고, 리소스·이름 확인보다 먼저다.
  /// 이름은 리소스 안에서 겹치지 않는다(이미 있으면 409). 리소스의 게스트가 100명이면 409.
  /// 리소스가 없거나 지금 게스트를 받지 않으면 403.
  /// X-Turnstile-Token 헤더의 토큰이 확인을 통과하지 못하면 403, 확인할 수 없으면 503 (다른 확인보다 먼저다).
  @POST('/v1/guests')
  Future<GuestRead> createGuestV1GuestsPost({
    @Body() required GuestCreate body,
    @DioOptions() RequestOptions? options,
  });

  /// Delete Me.
  ///
  /// 게스트가 자기를 폐기한다. Kratos 세션은 바로 끊기고, 이미 받은 JWT도 게스트 경로에서 거부된다.
  ///
  /// X-Turnstile-Token 헤더의 토큰이 확인을 통과하지 못하면 403, 확인할 수 없으면 503.
  @DELETE('/v1/guests/me')
  Future<void> deleteMeV1GuestsMeDelete({
    @DioOptions() RequestOptions? options,
  });

  /// Put My Consent.
  ///
  /// 게스트의 만 14세 이상 확인, 이용약관, 개인정보처리방침 동의 기록. 본문은 회원 동의와 같다.
  ///
  /// `version`은 POST /v1/guests/lookup이 돌려준 현재 약관 시행일이어야 한다(다르면 409).
  /// 게스트가 폐기되었으면 403. Turnstile 토큰은 받지 않는다.
  @PUT('/v1/guests/me/consent')
  Future<void> putMyConsentV1GuestsMeConsentPut({
    @Body() required ConsentCreate body,
    @DioOptions() RequestOptions? options,
  });
}
