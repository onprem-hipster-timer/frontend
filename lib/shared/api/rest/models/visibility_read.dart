// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'resource_type.dart';
import 'visibility_level.dart';

part 'visibility_read.freezed.dart';
part 'visibility_read.g.dart';

/// 접근권한 설정 조회 DTO
@Freezed()
abstract class VisibilityRead with _$VisibilityRead {
  const factory VisibilityRead({
    required String id,
    @JsonKey(name: 'resource_type') required ResourceType resourceType,
    @JsonKey(name: 'resource_id') required String resourceId,
    @JsonKey(name: 'owner_id') required String ownerId,
    required VisibilityLevel level,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'allowed_user_ids') @Default([]) List<String> allowedUserIds,
    @JsonKey(name: 'allowed_emails') @Default([]) List<String> allowedEmails,
    @JsonKey(name: 'allowed_domains') @Default([]) List<String> allowedDomains,
  }) = _VisibilityRead;

  factory VisibilityRead.fromJson(Map<String, Object?> json) =>
      _$VisibilityReadFromJson(json);
}
