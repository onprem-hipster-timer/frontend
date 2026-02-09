// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag_update.freezed.dart';
part 'tag_update.g.dart';

/// 태그 업데이트 DTO
@Freezed()
abstract class TagUpdate with _$TagUpdate {
  const factory TagUpdate({
    String? name,
    String? color,
    String? description,
  }) = _TagUpdate;
  
  factory TagUpdate.fromJson(Map<String, Object?> json) => _$TagUpdateFromJson(json);
}
