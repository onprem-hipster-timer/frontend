// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'resource_type.dart';

part 'guest_lookup.freezed.dart';
part 'guest_lookup.g.dart';

/// 게스트 이름 찾기 요청
@Freezed()
abstract class GuestLookup with _$GuestLookup {
  const factory GuestLookup({
    @JsonKey(name: 'resource_type') required ResourceType resourceType,
    @JsonKey(name: 'resource_id') required String resourceId,
    required String name,
  }) = _GuestLookup;

  factory GuestLookup.fromJson(Map<String, Object?> json) =>
      _$GuestLookupFromJson(json);
}
