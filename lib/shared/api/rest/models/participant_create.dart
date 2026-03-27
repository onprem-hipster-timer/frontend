// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'participant_create.freezed.dart';
part 'participant_create.g.dart';

/// 참여자 생성 DTO
@Freezed()
abstract class ParticipantCreate with _$ParticipantCreate {
  const factory ParticipantCreate({
    @JsonKey(name: 'display_name') required String displayName,
  }) = _ParticipantCreate;

  factory ParticipantCreate.fromJson(Map<String, Object?> json) =>
      _$ParticipantCreateFromJson(json);
}
