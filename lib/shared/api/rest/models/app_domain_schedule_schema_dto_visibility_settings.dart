// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'visibility_level.dart';

part 'app_domain_schedule_schema_dto_visibility_settings.freezed.dart';
part 'app_domain_schedule_schema_dto_visibility_settings.g.dart';

/// 가시성 설정 DTO
@Freezed()
abstract class AppDomainScheduleSchemaDtoVisibilitySettings
    with _$AppDomainScheduleSchemaDtoVisibilitySettings {
  const factory AppDomainScheduleSchemaDtoVisibilitySettings({
    @JsonKey(name: 'allowed_user_ids') List<String>? allowedUserIds,
    @Default(VisibilityLevel.private) VisibilityLevel level,
  }) = _AppDomainScheduleSchemaDtoVisibilitySettings;

  factory AppDomainScheduleSchemaDtoVisibilitySettings.fromJson(
    Map<String, Object?> json,
  ) => _$AppDomainScheduleSchemaDtoVisibilitySettingsFromJson(json);
}
