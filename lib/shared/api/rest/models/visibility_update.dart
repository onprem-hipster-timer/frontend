// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'visibility_level.dart';

part 'visibility_update.freezed.dart';
part 'visibility_update.g.dart';

/// 접근권한 설정 업데이트 DTO
@Freezed()
abstract class VisibilityUpdate with _$VisibilityUpdate {
  const factory VisibilityUpdate({
    required VisibilityLevel level,
    @JsonKey(name: 'allowed_user_ids') List<String>? allowedUserIds,
    @JsonKey(name: 'allowed_emails') List<String>? allowedEmails,
    @JsonKey(name: 'allowed_domains') List<String>? allowedDomains,
  }) = _VisibilityUpdate;

  factory VisibilityUpdate.fromJson(Map<String, Object?> json) =>
      _$VisibilityUpdateFromJson(json);
}
