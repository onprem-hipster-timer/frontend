// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'participant_read.freezed.dart';
part 'participant_read.g.dart';

/// 참여자 조회 DTO
@Freezed()
abstract class ParticipantRead with _$ParticipantRead {
  const factory ParticipantRead({
    required String id,
    @JsonKey(name: 'meeting_id') required String meetingId,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'user_id') String? userId,
  }) = _ParticipantRead;

  factory ParticipantRead.fromJson(Map<String, Object?> json) =>
      _$ParticipantReadFromJson(json);
}
