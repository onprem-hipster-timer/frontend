// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'visibility_level.dart';

part 'visibility_settings.freezed.dart';
part 'visibility_settings.g.dart';

/// 가시성 설정 DTO
@Freezed()
abstract class VisibilitySettings with _$VisibilitySettings {
  const factory VisibilitySettings({
    @JsonKey(name: 'allowed_user_ids')
    List<String>? allowedUserIds,
    @Default(VisibilityLevel.private)
    VisibilityLevel level,
  }) = _VisibilitySettings;
  
  factory VisibilitySettings.fromJson(Map<String, Object?> json) => _$VisibilitySettingsFromJson(json);
}
