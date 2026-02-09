// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_request_read.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PendingRequestRead _$PendingRequestReadFromJson(Map<String, dynamic> json) =>
    _PendingRequestRead(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      addresseeId: json['addressee_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$PendingRequestReadToJson(_PendingRequestRead instance) =>
    <String, dynamic>{
      'id': instance.id,
      'requester_id': instance.requesterId,
      'addressee_id': instance.addresseeId,
      'created_at': instance.createdAt.toIso8601String(),
    };
