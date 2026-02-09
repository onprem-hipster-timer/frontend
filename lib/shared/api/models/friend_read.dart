// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend_read.freezed.dart';
part 'friend_read.g.dart';

/// 친구 정보 조회 DTO (간략화)
@Freezed()
abstract class FriendRead with _$FriendRead {
  const factory FriendRead({
    @JsonKey(name: 'user_id')
    required String userId,
    @JsonKey(name: 'friendship_id')
    required String friendshipId,
    required DateTime since,
  }) = _FriendRead;
  
  factory FriendRead.fromJson(Map<String, Object?> json) => _$FriendReadFromJson(json);
}
