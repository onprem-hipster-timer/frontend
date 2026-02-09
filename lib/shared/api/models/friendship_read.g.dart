// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friendship_read.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FriendshipRead _$FriendshipReadFromJson(Map<String, dynamic> json) =>
    _FriendshipRead(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      addresseeId: json['addressee_id'] as String,
      status: FriendshipStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      blockedBy: json['blocked_by'] as String?,
    );

Map<String, dynamic> _$FriendshipReadToJson(_FriendshipRead instance) =>
    <String, dynamic>{
      'id': instance.id,
      'requester_id': instance.requesterId,
      'addressee_id': instance.addresseeId,
      'status': _$FriendshipStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'blocked_by': instance.blockedBy,
    };

const _$FriendshipStatusEnumMap = {
  FriendshipStatus.pending: 'pending',
  FriendshipStatus.accepted: 'accepted',
  FriendshipStatus.blocked: 'blocked',
  FriendshipStatus.$unknown: r'$unknown',
};
