// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'guest_lookup_read.freezed.dart';
part 'guest_lookup_read.g.dart';

/// 게스트 이름 찾기 응답. 그 이름의 게스트가 없으면 handle은 null
@Freezed()
abstract class GuestLookupRead with _$GuestLookupRead {
  const factory GuestLookupRead({
    required String? handle,
    @JsonKey(name: 'consent_version') required String consentVersion,
  }) = _GuestLookupRead;

  factory GuestLookupRead.fromJson(Map<String, Object?> json) =>
      _$GuestLookupReadFromJson(json);
}
