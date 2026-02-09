// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'friendship_status.dart';

part 'friendship_read.freezed.dart';
part 'friendship_read.g.dart';

/// 친구 관계 조회 DTO
@Freezed()
abstract class FriendshipRead with _$FriendshipRead {
  const factory FriendshipRead({
    required String id,
    @JsonKey(name: 'requester_id')
    required String requesterId,
    @JsonKey(name: 'addressee_id')
    required String addresseeId,
    required FriendshipStatus status,
    @JsonKey(name: 'created_at')
    required DateTime createdAt,
    @JsonKey(name: 'updated_at')
    required DateTime updatedAt,
    @JsonKey(name: 'blocked_by')
    String? blockedBy,
  }) = _FriendshipRead;
  
  factory FriendshipRead.fromJson(Map<String, Object?> json) => _$FriendshipReadFromJson(json);
}
