// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_profile_read.freezed.dart';
part 'my_profile_read.g.dart';

/// 본인 프로필 (GET /v1/users/me) — 친구코드 공유용
@Freezed()
abstract class MyProfileRead with _$MyProfileRead {
  const factory MyProfileRead({
    required String id,
    @JsonKey(name: 'friend_code') required String friendCode,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _MyProfileRead;

  factory MyProfileRead.fromJson(Map<String, Object?> json) =>
      _$MyProfileReadFromJson(json);
}
