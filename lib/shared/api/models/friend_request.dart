// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend_request.freezed.dart';
part 'friend_request.g.dart';

/// 친구 요청 DTO
@Freezed()
abstract class FriendRequest with _$FriendRequest {
  const factory FriendRequest({
    @JsonKey(name: 'addressee_id') required String addresseeId,
  }) = _FriendRequest;

  factory FriendRequest.fromJson(Map<String, Object?> json) =>
      _$FriendRequestFromJson(json);
}
