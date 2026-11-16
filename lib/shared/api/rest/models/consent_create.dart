// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'consent_create.freezed.dart';
part 'consent_create.g.dart';

/// 약관 동의 — 세 항목 모두 true여야 한다.
///
/// PUT /v1/users/me/consent·PUT /v1/guests/me/consent의 본문이고 POST /v1/guests의 consent다.
@Freezed()
abstract class ConsentCreate with _$ConsentCreate {
  const factory ConsentCreate({
    required String version,
    @JsonKey(name: 'age_over_14') required bool ageOver14,
    required bool terms,
    required bool privacy,
  }) = _ConsentCreate;

  factory ConsentCreate.fromJson(Map<String, Object?> json) =>
      _$ConsentCreateFromJson(json);
}
