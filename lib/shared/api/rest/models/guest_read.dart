// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'resource_type.dart';

part 'guest_read.freezed.dart';
part 'guest_read.g.dart';

/// 게스트 생성 응답. 클라이언트는 handle과 비밀번호로 Kratos에 로그인한다
@Freezed()
abstract class GuestRead with _$GuestRead {
  const factory GuestRead({
    @JsonKey(name: 'guest_id') required String guestId,
    required String handle,
    @JsonKey(name: 'resource_type') required ResourceType resourceType,
    @JsonKey(name: 'resource_id') required String resourceId,
  }) = _GuestRead;

  factory GuestRead.fromJson(Map<String, Object?> json) =>
      _$GuestReadFromJson(json);
}
