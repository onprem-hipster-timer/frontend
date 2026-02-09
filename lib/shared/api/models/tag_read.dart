// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag_read.freezed.dart';
part 'tag_read.g.dart';

/// 태그 조회 DTO
@Freezed()
abstract class TagRead with _$TagRead {
  const factory TagRead({
    required String id,
    required String name,
    required String color,
    @JsonKey(name: 'group_id')
    required String groupId,
    @JsonKey(name: 'created_at')
    required DateTime createdAt,
    @JsonKey(name: 'updated_at')
    required DateTime updatedAt,
    String? description,
  }) = _TagRead;
  
  factory TagRead.fromJson(Map<String, Object?> json) => _$TagReadFromJson(json);
}
