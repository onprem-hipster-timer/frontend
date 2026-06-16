// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend_request_accepted.freezed.dart';
part 'friend_request_accepted.g.dart';

/// 이메일 기반 친구 요청의 균일 수락 응답.
@Freezed()
abstract class FriendRequestAccepted with _$FriendRequestAccepted {
  const factory FriendRequestAccepted({required bool ok}) =
      _FriendRequestAccepted;

  factory FriendRequestAccepted.fromJson(Map<String, Object?> json) =>
      _$FriendRequestAcceptedFromJson(json);
}
