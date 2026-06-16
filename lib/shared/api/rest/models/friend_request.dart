// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend_request.freezed.dart';
part 'friend_request.g.dart';

/// 친구 요청 DTO.
///
/// 친추 대상을 `email` 또는 `friend_code` 중 **정확히 하나**로 지정한다:.
/// - `email`: 검증된 이메일 사용자와 매칭(항상 균일 202, 존재 비노출).
/// - `friend_code`: `GET /v1/users/me`로 공유된 코드와 직접 매칭(미존재 404).
///
/// 둘 다 비었거나 둘 다 주어지면 422. `null`이라도 필드가 둘 다 있으면 422로 본다.
/// `email`은 형식 검증된다. OIDC sub는 외부에서 얻을 수 없으므로 식별자로 받지 않는다.
@Freezed()
abstract class FriendRequest with _$FriendRequest {
  const factory FriendRequest({
    String? email,
    @JsonKey(name: 'friend_code') String? friendCode,
  }) = _FriendRequest;

  factory FriendRequest.fromJson(Map<String, Object?> json) =>
      _$FriendRequestFromJson(json);
}
