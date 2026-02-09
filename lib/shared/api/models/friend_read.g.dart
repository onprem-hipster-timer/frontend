// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_read.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FriendRead _$FriendReadFromJson(Map<String, dynamic> json) => _FriendRead(
      userId: json['user_id'] as String,
      friendshipId: json['friendship_id'] as String,
      since: DateTime.parse(json['since'] as String),
    );

Map<String, dynamic> _$FriendReadToJson(_FriendRead instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'friendship_id': instance.friendshipId,
      'since': instance.since.toIso8601String(),
    };
