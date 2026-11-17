// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'consent_create.dart';
import 'resource_type.dart';

part 'guest_create.freezed.dart';
part 'guest_create.g.dart';

/// 게스트 생성 요청. consent는 회원 동의(PUT /v1/users/me/consent)와 같은 모양이다
@Freezed()
abstract class GuestCreate with _$GuestCreate {
  const factory GuestCreate({
    @JsonKey(name: 'resource_type') required ResourceType resourceType,
    @JsonKey(name: 'resource_id') required String resourceId,
    required String name,
    required String password,
    required ConsentCreate consent,
  }) = _GuestCreate;

  factory GuestCreate.fromJson(Map<String, Object?> json) =>
      _$GuestCreateFromJson(json);
}
