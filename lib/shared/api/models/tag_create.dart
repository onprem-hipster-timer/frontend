// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag_create.freezed.dart';
part 'tag_create.g.dart';

/// 태그 생성 DTO
@Freezed()
abstract class TagCreate with _$TagCreate {
  const factory TagCreate({
    required String name,
    required String color,
    @JsonKey(name: 'group_id')
    required String groupId,
    String? description,
  }) = _TagCreate;
  
  factory TagCreate.fromJson(Map<String, Object?> json) => _$TagCreateFromJson(json);
}
