// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'guest_import.freezed.dart';
part 'guest_import.g.dart';

/// 게스트 가져오기 요청 (POST /v1/meetings/{meeting_id}/guest-import)
@Freezed()
abstract class GuestImport with _$GuestImport {
  const factory GuestImport({
    @JsonKey(name: 'guest_token') required String guestToken,
  }) = _GuestImport;

  factory GuestImport.fromJson(Map<String, Object?> json) =>
      _$GuestImportFromJson(json);
}
