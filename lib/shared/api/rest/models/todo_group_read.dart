// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo_group_read.freezed.dart';
part 'todo_group_read.g.dart';

/// 할 일 그룹 조회 DTO
@Freezed()
abstract class TodoGroupRead with _$TodoGroupRead {
  const factory TodoGroupRead({
    required String id,
    required String name,
    required String color,
    @JsonKey(name: 'is_default') required bool isDefault,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    String? description,
  }) = _TodoGroupRead;

  factory TodoGroupRead.fromJson(Map<String, Object?> json) =>
      _$TodoGroupReadFromJson(json);
}
