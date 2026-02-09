// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visibility_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VisibilitySettings _$VisibilitySettingsFromJson(Map<String, dynamic> json) =>
    _VisibilitySettings(
      allowedUserIds: (json['allowed_user_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      level: json['level'] == null
          ? VisibilityLevel.private
          : VisibilityLevel.fromJson(json['level'] as String),
    );

Map<String, dynamic> _$VisibilitySettingsToJson(_VisibilitySettings instance) =>
    <String, dynamic>{
      'allowed_user_ids': instance.allowedUserIds,
      'level': _$VisibilityLevelEnumMap[instance.level]!,
    };

const _$VisibilityLevelEnumMap = {
  VisibilityLevel.private: 'private',
  VisibilityLevel.friends: 'friends',
  VisibilityLevel.selected: 'selected',
  VisibilityLevel.public: 'public',
  VisibilityLevel.$unknown: r'$unknown',
};
