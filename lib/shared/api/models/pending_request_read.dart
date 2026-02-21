// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_request_read.freezed.dart';
part 'pending_request_read.g.dart';

/// 대기 중인 친구 요청 DTO
@Freezed()
abstract class PendingRequestRead with _$PendingRequestRead {
  const factory PendingRequestRead({
    required String id,
    @JsonKey(name: 'requester_id') required String requesterId,
    @JsonKey(name: 'addressee_id') required String addresseeId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _PendingRequestRead;

  factory PendingRequestRead.fromJson(Map<String, Object?> json) =>
      _$PendingRequestReadFromJson(json);
}
